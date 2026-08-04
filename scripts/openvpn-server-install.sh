#!/usr/bin/env bash
set -Eeuo pipefail

dry_run=0
case "${1:-}" in
  '') ;;
  --dry-run) dry_run=1 ;;
  --help|-h)
    cat <<'EOF'
Uso: openvpn-server-install.sh [--dry-run]

Corrige en Parrot OS el conflicto de versiones entre openssh-client
(instalado desde *-backports) y openssh-server/openssh-sftp-server
(instalados desde el repositorio estable) que bloquea
`apt install openvpn-server` con un error de dependencias no satisfechas.

Este script NO instala openvpn-server. Actualiza el sistema con APT
(equivalente a lab-update.sh) y, si detecta el conflicto, reinstala el
trío SSH desde el mismo backports que ya usa openssh-client. Después de
ejecutarlo, instale manualmente:

  sudo apt install openvpn-server
EOF
    exit 0
    ;;
  *) printf 'Opción desconocida: %s\n' "$1" >&2; exit 2 ;;
esac

if [[ ! -r /etc/os-release ]] || ! grep -Fxq 'ID=parrot' /etc/os-release; then
  printf 'ERROR: este script solo está pensado para Parrot OS.\n' >&2
  exit 3
fi

codename="$(. /etc/os-release && printf '%s' "${VERSION_CODENAME:-}")"
if [[ -z "$codename" ]]; then
  printf 'ERROR: no se pudo determinar VERSION_CODENAME en /etc/os-release.\n' >&2
  exit 3
fi
backports_suite="${codename}-backports"

if (( dry_run )); then
  client_version="$(dpkg-query -W -f='${Version}' openssh-client 2>/dev/null || true)"
  printf '[dry-run] sudo apt-get update\n'
  printf '[dry-run] sudo apt-get upgrade\n'
  if [[ "$client_version" == *"~bpo"* ]]; then
    printf '[dry-run] openssh-client ya está en %s (%s)\n' "$backports_suite" "$client_version"
    printf '[dry-run] sudo apt-get install -t %s -- openssh-client openssh-server openssh-sftp-server\n' \
      "$backports_suite"
  else
    printf '[dry-run] sudo apt-get install -- openssh-client openssh-server openssh-sftp-server\n'
  fi
  exit 0
fi

printf 'Este script actualizará el sistema y ajustará los paquetes SSH mediante APT. ¿Continuar? [s/N] '
read -r answer
[[ "$answer" =~ ^[sS]$ ]] || { printf 'Cancelado.\n'; exit 0; }

sudo apt-get update
sudo apt-get upgrade

client_version="$(dpkg-query -W -f='${Version}' openssh-client 2>/dev/null || true)"
if [[ "$client_version" == *"~bpo"* ]]; then
  printf 'openssh-client instalado desde %s (%s); alineando openssh-server y openssh-sftp-server.\n' \
    "$backports_suite" "$client_version"
  sudo apt-get install -t "$backports_suite" -- openssh-client openssh-server openssh-sftp-server
else
  sudo apt-get install -- openssh-client openssh-server openssh-sftp-server
fi

printf '\nListo. No se habilitó ni inició ningún servicio SSH ni VPN.\n'
printf 'Para completar la instalación de OpenVPN, ejecute manualmente:\n'
printf '  sudo apt install openvpn-server\n'
