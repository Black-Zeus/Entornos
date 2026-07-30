#!/usr/bin/env bash
set -Eeuo pipefail

dry_run=0
case "${1:-}" in
  '') ;;
  --dry-run) dry_run=1 ;;
  --help|-h)
    printf 'Uso: %s [--dry-run]\nActualiza índices y paquetes APT sin full-upgrade ni reinicio.\n' "$0"
    exit 0
    ;;
  *) printf 'Opción desconocida: %s\n' "$1" >&2; exit 2 ;;
esac

if (( dry_run )); then
  printf '[dry-run] sudo apt-get update\n'
  printf '[dry-run] sudo apt-get upgrade\n'
  exit 0
fi

printf 'Esta acción actualizará paquetes mediante APT. ¿Continuar? [s/N] '
read -r answer
[[ "$answer" =~ ^[sS]$ ]] || { printf 'Cancelado.\n'; exit 0; }
sudo apt-get update
sudo apt-get upgrade
printf 'Actualización terminada. No se reinició el sistema.\n'
