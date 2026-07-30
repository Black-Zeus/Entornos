#!/usr/bin/env bash

OS_RELEASE_FILE="${PARROT_OS_RELEASE_FILE:-/etc/os-release}"
DETECTED_ARCH=""
DETECTED_VIRT="none"
REAL_USER=""
REAL_HOME=""

effective_uid() {
  if [[ "${PARROT_INSTALLER_TESTING:-0}" == 1 && -n "${PARROT_EUID_OVERRIDE:-}" ]]; then
    printf '%s\n' "$PARROT_EUID_OVERRIDE"
  else
    printf '%s\n' "$EUID"
  fi
}

detect_real_user() {
  local uid
  uid="$(effective_uid)"

  if [[ "${PARROT_INSTALLER_TESTING:-0}" == 1 && -n "${PARROT_USER_OVERRIDE:-}" ]]; then
    REAL_USER="$PARROT_USER_OVERRIDE"
    REAL_HOME="${PARROT_HOME_OVERRIDE:?Falta PARROT_HOME_OVERRIDE en modo de prueba}"
    return 0
  fi

  if [[ "$uid" == 0 ]]; then
    if [[ -z "${SUDO_USER:-}" || "$SUDO_USER" == root ]]; then
      log_error 'No ejecute el instalador directamente como root. Use un usuario normal con sudo.'
      return "$EXIT_UNSUPPORTED"
    fi
    REAL_USER="$SUDO_USER"
  else
    REAL_USER="${USER:-$(id -un)}"
  fi

  REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
  if [[ -z "$REAL_HOME" || ! -d "$REAL_HOME" ]]; then
    log_error "No se pudo resolver un home válido para $REAL_USER."
    return "$EXIT_UNSUPPORTED"
  fi
}

detect_parrot() {
  local ID='' PRETTY_NAME=''
  if [[ ! -r "$OS_RELEASE_FILE" ]]; then
    log_error "No se puede leer $OS_RELEASE_FILE."
    return "$EXIT_UNSUPPORTED"
  fi

  # shellcheck disable=SC1090
  source "$OS_RELEASE_FILE"
  if [[ "${ID,,}" != parrot ]]; then
    log_error "Sistema no soportado: ${PRETTY_NAME:-${ID:-desconocido}}. Solo se admite Parrot OS."
    return "$EXIT_UNSUPPORTED"
  fi
  log_info "Sistema detectado: ${PRETTY_NAME:-Parrot OS}."
}

detect_architecture() {
  DETECTED_ARCH="$(uname -m)"
  case "$DETECTED_ARCH" in
    x86_64|amd64) ;;
    *)
      log_error "Arquitectura no validada para este proyecto: $DETECTED_ARCH"
      return "$EXIT_UNSUPPORTED"
      ;;
  esac
  log_info "Arquitectura: $DETECTED_ARCH."
}

detect_virtualization() {
  if [[ "${PARROT_INSTALLER_TESTING:-0}" == 1 && -n "${PARROT_VIRT_OVERRIDE:-}" ]]; then
    DETECTED_VIRT="$PARROT_VIRT_OVERRIDE"
  elif command -v systemd-detect-virt >/dev/null 2>&1; then
    DETECTED_VIRT="$(systemd-detect-virt 2>/dev/null || printf none)"
  else
    DETECTED_VIRT=unknown
    record_recoverable 'systemd-detect-virt no está disponible; VMware no pudo detectarse.'
  fi

  if [[ "$DETECTED_VIRT" == vmware ]]; then
    log_info 'VMware detectado.'
  else
    log_warn "VMware no detectado (virtualización: $DETECTED_VIRT)."
  fi
}
