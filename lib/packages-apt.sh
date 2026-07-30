#!/usr/bin/env bash

declare -a REQUIRED_PACKAGES=()
declare -a OPTIONAL_PACKAGES=()

load_package_file() {
  local package_file="$1"
  local kind package extra
  [[ -r "$package_file" ]] || { log_error "Lista de paquetes ausente: $package_file"; return "$EXIT_DEPENDENCY"; }

  while read -r kind package extra; do
    [[ -z "${kind:-}" || "$kind" == \#* ]] && continue
    if [[ -n "${extra:-}" || -z "${package:-}" ]]; then
      log_error "Entrada inválida en $package_file: $kind ${package:-} ${extra:-}"
      return "$EXIT_DEPENDENCY"
    fi
    case "$kind" in
      required) REQUIRED_PACKAGES+=("$package") ;;
      optional) OPTIONAL_PACKAGES+=("$package") ;;
      *) log_error "Clasificación inválida '$kind' en $package_file"; return "$EXIT_DEPENDENCY" ;;
    esac
  done < "$package_file"
}

load_component_packages() {
  local component
  REQUIRED_PACKAGES=()
  OPTIONAL_PACKAGES=()
  for component in "$@"; do
    load_package_file "$PROJECT_ROOT/packages/$component.txt"
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
    if ! apt-cache show "$package" >/dev/null 2>&1; then
      log_error "Paquete obligatorio no disponible: $package"
      missing_required=1
    fi
  done
  for package in "${OPTIONAL_PACKAGES[@]}"; do
    apt-cache show "$package" >/dev/null 2>&1 || record_optional "Paquete no disponible: $package"
  done
  if (( missing_required != 0 )); then
    return "$EXIT_DEPENDENCY"
  fi
}

install_packages() {
  local -a available_optional=()
  local package
  if (( DRY_RUN )); then
    printf '[dry-run] sudo apt-get update\n'
    ((${#REQUIRED_PACKAGES[@]})) && { printf '[dry-run] sudo apt-get install --yes -- '; quote_command "${REQUIRED_PACKAGES[@]}"; printf '\n'; }
    ((${#OPTIONAL_PACKAGES[@]})) && { printf '[dry-run] paquetes opcionales: '; join_by ', ' "${OPTIONAL_PACKAGES[@]}"; printf '\n'; }
    return 0
  fi

  run_command sudo apt-get update
  ((${#REQUIRED_PACKAGES[@]})) && run_command sudo apt-get install --yes -- "${REQUIRED_PACKAGES[@]}"
  for package in "${OPTIONAL_PACKAGES[@]}"; do
    if apt-cache show "$package" >/dev/null 2>&1; then
      available_optional+=("$package")
    else
      record_optional "Paquete no disponible: $package"
    fi
  done
  if ((${#available_optional[@]})); then
    if ! run_command sudo apt-get install --yes -- "${available_optional[@]}"; then
      record_optional 'Uno o más paquetes opcionales no pudieron instalarse.'
    fi
  fi
}
