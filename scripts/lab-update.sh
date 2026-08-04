#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Uso: lab-update.sh OPCIÓN

Opciones:
  --check      Lista actualizaciones disponibles usando los índices APT actuales.
  --dry-run    Muestra la actualización completa que se ejecutaría.
  --upgrade    Actualiza completamente Parrot mediante parrot-upgrade.
  --help       Muestra esta ayuda.

La actualización no reinicia ni apaga el sistema automáticamente.
EOF
}

check_parrot() {
  if [[ ! -r /etc/os-release ]] || ! grep -Fxq 'ID=parrot' /etc/os-release; then
    printf 'ERROR: esta operación solo está soportada en Parrot OS.\n' >&2
    exit 3
  fi
}

case "${1:-}" in
  --check)
    (($# == 1)) || { printf 'ERROR: argumentos adicionales no permitidos.\n' >&2; exit 2; }
    command -v apt >/dev/null 2>&1 || {
      printf 'ERROR: apt no está disponible.\n' >&2
      exit 4
    }
    printf 'Actualizaciones disponibles según los índices APT actuales:\n'
    apt list --upgradable
    ;;
  --dry-run)
    (($# == 1)) || { printf 'ERROR: argumentos adicionales no permitidos.\n' >&2; exit 2; }
    printf '[dry-run] sudo parrot-upgrade\n'
    printf '[dry-run] No se reiniciará ni apagará el sistema.\n'
    ;;
  --upgrade)
    (($# == 1)) || { printf 'ERROR: argumentos adicionales no permitidos.\n' >&2; exit 2; }
    check_parrot
    command -v parrot-upgrade >/dev/null 2>&1 || {
      printf 'ERROR: parrot-upgrade no está disponible.\n' >&2
      exit 4
    }
    command -v sudo >/dev/null 2>&1 || {
      printf 'ERROR: sudo no está disponible.\n' >&2
      exit 4
    }
    printf 'Se actualizará completamente Parrot mediante parrot-upgrade. ¿Continuar? [s/N] '
    read -r answer
    [[ "$answer" =~ ^[sS]$ ]] || { printf 'Cancelado.\n'; exit 0; }
    sudo parrot-upgrade
    printf 'Actualización terminada. No se reinició el sistema.\n'
    ;;
  --help|-h)
    usage
    ;;
  '')
    usage >&2
    exit 2
    ;;
  *)
    printf 'ERROR: opción desconocida: %s\n\n' "$1" >&2
    usage >&2
    exit 2
    ;;
esac
