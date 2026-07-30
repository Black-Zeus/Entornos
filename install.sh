#!/usr/bin/env bash
set -Eeuo pipefail

if [[ -z "${BASH_VERSION:-}" ]]; then
  printf 'ERROR: este instalador requiere Bash.\n' >&2
  exit 3
fi

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PROJECT_ROOT

# shellcheck source=lib/common.sh
source "$PROJECT_ROOT/lib/common.sh"
# shellcheck source=lib/logging.sh
source "$PROJECT_ROOT/lib/logging.sh"
# shellcheck source=lib/detect-system.sh
source "$PROJECT_ROOT/lib/detect-system.sh"
# shellcheck source=lib/backup.sh
source "$PROJECT_ROOT/lib/backup.sh"
# shellcheck source=lib/packages-apt.sh
source "$PROJECT_ROOT/lib/packages-apt.sh"
# shellcheck source=lib/repositories-apt.sh
source "$PROJECT_ROOT/lib/repositories-apt.sh"
# shellcheck source=lib/firefox-extensions.sh
source "$PROJECT_ROOT/lib/firefox-extensions.sh"
# shellcheck source=lib/deploy-dotfiles.sh
source "$PROJECT_ROOT/lib/deploy-dotfiles.sh"
# shellcheck source=lib/fonts.sh
source "$PROJECT_ROOT/lib/fonts.sh"
# shellcheck source=lib/powerlevel10k.sh
source "$PROJECT_ROOT/lib/powerlevel10k.sh"

DRY_RUN=0
declare -a COMPONENTS=(base desktop vmware security-lab)

usage() {
  cat <<'EOF'
Uso:
  ./install.sh [--dry-run] [--components LISTA]
  ./install.sh --help

Prepara una VM Parrot OS para el perfil único parrot-security-lab.

Opciones:
  --dry-run             Muestra las acciones sin instalar ni modificar archivos.
  --components LISTA    Componentes: base,desktop,vmware,security-lab.
  --help                Muestra esta ayuda.

Ejemplos:
  ./install.sh --dry-run
  ./install.sh --components base,desktop,vmware,security-lab --dry-run

Una ejecución real instala paquetes mediante APT y despliega dotfiles con
backup. No reinicia, no cambia la shell y no habilita servicios.
EOF
}

die_usage() {
  printf 'ERROR: %s\n\n' "$1" >&2
  usage >&2
  exit "$EXIT_USAGE"
}

parse_components() {
  local value="$1"
  local item
  local -A seen=()
  COMPONENTS=()
  IFS=',' read -r -a requested <<< "$value"
  ((${#requested[@]})) || die_usage 'La lista de componentes está vacía.'

  for item in "${requested[@]}"; do
    case "$item" in
      base|desktop|vmware|security-lab) ;;
      '') die_usage 'La lista de componentes contiene un elemento vacío.' ;;
      *) die_usage "Componente desconocido: $item" ;;
    esac
    if [[ -z "${seen[$item]:-}" ]]; then
      COMPONENTS+=("$item")
      seen[$item]=1
    fi
  done
}

parse_args() {
  while (($#)); do
    case "$1" in
      --dry-run) DRY_RUN=1; shift ;;
      --help|-h) usage; exit "$EXIT_OK" ;;
      --components)
        (($# >= 2)) || die_usage 'Falta el valor de --components.'
        parse_components "$2"
        shift 2
        ;;
      --components=*) parse_components "${1#*=}"; shift ;;
      *) die_usage "Opción desconocida: $1" ;;
    esac
  done
}

component_selected() {
  local wanted="$1" component
  for component in "${COMPONENTS[@]}"; do
    [[ "$component" == "$wanted" ]] && return 0
  done
  return 1
}

verify_dependencies() {
  local dependency
  for dependency in awk date find grep install cp cmp curl dirname gpg mktemp uname sha256sum tar; do
    require_command "$dependency"
  done
  if (( ! DRY_RUN )); then
    require_command sudo
    require_command apt-get
    require_command apt-cache
  fi
}

deploy_selected_dotfiles() {
  component_selected base && deploy_base_dotfiles
  component_selected desktop && deploy_desktop_dotfiles
  if component_selected base || component_selected desktop; then
    deploy_lab_scripts
  fi
}

print_summary() {
  printf '\nResumen final\n'
  printf '  Perfil: parrot-security-lab\n'
  printf '  Modo: %s\n' "$([[ "$DRY_RUN" == 1 ]] && printf 'MODO DRY-RUN' || printf 'ejecución real')"
  printf '  Usuario: %s\n' "$REAL_USER"
  printf '  Arquitectura: %s\n' "$DETECTED_ARCH"
  printf '  Virtualización: %s\n' "$DETECTED_VIRT"
  printf '  Componentes: '
  join_by ', ' "${COMPONENTS[@]}"
  printf '\n  Errores recuperables: %d\n' "${#RECOVERABLE_ERRORS[@]}"
  printf '  Incidencias opcionales: %d\n' "${#OPTIONAL_ERRORS[@]}"
  if (( DRY_RUN )); then
    printf '  No se realizaron cambios.\n'
  else
    printf '  Log: %s\n' "$LOG_FILE"
    printf '  Backups: %s\n' "$BACKUP_ROOT"
  fi
  printf '\nNo se cambió la shell ni se habilitaron servicios. No se requiere reinicio automático.\n'
  if component_selected vmware; then
    printf 'Revise docs/architecture.md antes de habilitar manualmente servicios VMware.\n'
  fi
}

on_error() {
  local status="$1"
  local line="$2"
  case "$status" in
    "$EXIT_USAGE"|"$EXIT_UNSUPPORTED"|"$EXIT_DEPENDENCY"|"$EXIT_OPERATION") ;;
    *) status="$EXIT_OPERATION" ;;
  esac
  log_error "Fallo crítico en la línea $line (código $status)."
  exit "$status"
}

main() {
  parse_args "$@"
  trap 'on_error "$?" "$LINENO"' ERR

  if [[ "${PARROT_INSTALLER_TESTING:-0}" == 1 && "$DRY_RUN" != 1 ]]; then
    log_error 'El modo de prueba interno solo permite --dry-run.'
    exit "$EXIT_UNSUPPORTED"
  fi

  detect_real_user
  init_logging "$REAL_HOME/.local/state/parrot-security-lab/logs"
  (( DRY_RUN )) && log_info 'MODO DRY-RUN: no se realizarán cambios.'
  detect_parrot
  detect_architecture
  detect_virtualization
  verify_dependencies

  if component_selected vmware && [[ "$DETECTED_VIRT" != vmware ]]; then
    record_recoverable 'Se seleccionó VMware, pero el hipervisor no fue detectado.'
  fi

  component_selected base && configure_google_chrome_repository
  load_component_packages "${COMPONENTS[@]}"
  refresh_apt_metadata
  validate_package_names
  init_backup "$REAL_HOME/.local/state/parrot-security-lab"
  install_packages
  component_selected base && install_firefox_wappalyzer
  component_selected base && install_powerlevel10k
  component_selected desktop && install_hack_nerd_font
  deploy_selected_dotfiles
  print_summary
}

main "$@"
