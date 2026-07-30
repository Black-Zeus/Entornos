#!/usr/bin/env bash

declare -a REQUIRED_PACKAGES=()
declare -a OPTIONAL_PACKAGES=()
declare -a PACKAGE_RECORDS=()
declare -a PACKAGE_SCOPES=()
declare -A PACKAGE_KIND=()
declare -A PACKAGE_SCOPE=()
APT_METADATA_REFRESHED=0

refresh_apt_metadata() {
  if (( APT_METADATA_REFRESHED )); then
    return 0
  fi

  if (( DRY_RUN )); then
    printf '[dry-run] sudo apt-get update\n'
  else
    run_command sudo apt-get update
  fi
  APT_METADATA_REFRESHED=1
}

package_has_candidate() {
  local package="$1"
  LC_ALL=C apt-cache policy "$package" |
    awk '$1 == "Candidate:" && $2 != "(none)" { found=1 } END { exit !found }'
}

load_package_file() {
  local package_file="$1"
  local scope="$2"
  local kind package extra
  [[ -r "$package_file" ]] || { log_error "Lista de paquetes ausente: $package_file"; return "$EXIT_DEPENDENCY"; }

  while read -r kind package extra; do
    [[ -z "${kind:-}" || "$kind" == \#* ]] && continue
    if [[ -n "${extra:-}" || -z "${package:-}" ]]; then
      log_error "Entrada inválida en $package_file: $kind ${package:-} ${extra:-}"
      return "$EXIT_DEPENDENCY"
    fi
    case "$kind" in
      required|optional) PACKAGE_RECORDS+=("$kind|$scope|$package") ;;
      *) log_error "Clasificación inválida '$kind' en $package_file"; return "$EXIT_DEPENDENCY" ;;
    esac
  done < "$package_file"
}

load_component_packages() {
  local component scope_file scope record kind package
  local -A known_scope=() emitted=()
  REQUIRED_PACKAGES=()
  OPTIONAL_PACKAGES=()
  PACKAGE_RECORDS=()
  PACKAGE_SCOPES=()
  PACKAGE_KIND=()
  PACKAGE_SCOPE=()
  for component in "$@"; do
    scope="$component"
    [[ -n "${known_scope[$scope]:-}" ]] || { PACKAGE_SCOPES+=("$scope"); known_scope[$scope]=1; }
    load_package_file "$PROJECT_ROOT/packages/$component.txt" "$scope"
    if [[ -d "$PROJECT_ROOT/packages/$component" ]]; then
      while IFS= read -r scope_file; do
        scope="${scope_file##*/}"
        scope="${scope%.txt}"
        [[ -n "${known_scope[$scope]:-}" ]] || { PACKAGE_SCOPES+=("$scope"); known_scope[$scope]=1; }
        load_package_file "$scope_file" "$scope"
      done < <(find "$PROJECT_ROOT/packages/$component" -maxdepth 1 -type f -name '*.txt' | sort)
    fi
  done

  # Primera pasada: required prevalece sobre optional en cualquier scope.
  for record in "${PACKAGE_RECORDS[@]}"; do
    IFS='|' read -r kind scope package <<< "$record"
    [[ "$kind" == required || -z "${PACKAGE_KIND[$package]:-}" ]] && PACKAGE_KIND[$package]="$kind"
    [[ -n "${PACKAGE_SCOPE[$package]:-}" ]] || PACKAGE_SCOPE[$package]="$scope"
  done

  # Segunda pasada: conserva el orden y emite cada paquete una sola vez.
  for record in "${PACKAGE_RECORDS[@]}"; do
    IFS='|' read -r kind scope package <<< "$record"
    [[ -n "${emitted[$package]:-}" ]] && continue
    emitted[$package]=1
    if [[ "${PACKAGE_KIND[$package]}" == required ]]; then
      REQUIRED_PACKAGES+=("$package")
    else
      OPTIONAL_PACKAGES+=("$package")
    fi
  done
}

validate_package_names() {
  local package missing_required=0
  command -v apt-cache >/dev/null 2>&1 || {
    if (( DRY_RUN )); then
      record_recoverable 'apt-cache no está disponible; no se validaron nombres de paquetes en esta simulación.'
      return 0
    fi
    log_error 'apt-cache no está disponible.'
    return "$EXIT_DEPENDENCY"
  }

  for package in "${REQUIRED_PACKAGES[@]}"; do
    if ! package_has_candidate "$package"; then
      if (( DRY_RUN )) && [[ "$package" == google-chrome-stable ]]; then
        record_recoverable 'google-chrome-stable se validará después de configurar el repositorio oficial en una ejecución real.'
        continue
      fi
      log_error "Paquete obligatorio no disponible: $package"
      missing_required=1
    fi
  done
  for package in "${OPTIONAL_PACKAGES[@]}"; do
    package_has_candidate "$package" || record_optional "Paquete no disponible: $package"
  done
  if (( missing_required != 0 )); then
    return "$EXIT_DEPENDENCY"
  fi
}

install_packages() {
  local -a scope_required=() scope_optional=() available_optional=()
  local package scope
  local scope_index=0
  local processed=0
  local total=$((${#REQUIRED_PACKAGES[@]} + ${#OPTIONAL_PACKAGES[@]}))
  refresh_apt_metadata
  for scope in "${PACKAGE_SCOPES[@]}"; do
    scope_index=$((scope_index + 1))
    scope_required=()
    scope_optional=()
    available_optional=()
    for package in "${REQUIRED_PACKAGES[@]}"; do
      [[ "${PACKAGE_SCOPE[$package]}" == "$scope" ]] && scope_required+=("$package")
    done
    for package in "${OPTIONAL_PACKAGES[@]}"; do
      [[ "${PACKAGE_SCOPE[$package]}" == "$scope" ]] && scope_optional+=("$package")
    done
    ((${#scope_required[@]} + ${#scope_optional[@]} > 0)) || continue

    printf '\n[scope %d/%d] %s (%d paquetes; progreso %d/%d)\n' \
      "$scope_index" "${#PACKAGE_SCOPES[@]}" "$scope" \
      "$((${#scope_required[@]} + ${#scope_optional[@]}))" "$processed" "$total"

    if (( DRY_RUN )); then
      ((${#scope_required[@]})) && { printf '[dry-run] obligatorios: '; join_by ', ' "${scope_required[@]}"; printf '\n'; }
      ((${#scope_optional[@]})) && { printf '[dry-run] opcionales: '; join_by ', ' "${scope_optional[@]}"; printf '\n'; }
    else
      ((${#scope_required[@]})) && run_command sudo env DEBIAN_FRONTEND=noninteractive \
        apt-get install --yes -- "${scope_required[@]}"
      for package in "${scope_optional[@]}"; do
        if package_has_candidate "$package"; then
          available_optional+=("$package")
        else
          record_optional "Paquete no disponible: $package"
        fi
      done
      if ((${#available_optional[@]})) && ! run_command sudo env DEBIAN_FRONTEND=noninteractive \
        apt-get install --yes -- "${available_optional[@]}"; then
        record_optional "El scope opcional '$scope' no pudo instalarse completamente."
      fi
    fi
    processed=$((processed + ${#scope_required[@]} + ${#scope_optional[@]}))
    printf '[progreso] %d/%d paquetes procesados (%d%%)\n' \
      "$processed" "$total" "$((total > 0 ? processed * 100 / total : 100))"
  done
}
