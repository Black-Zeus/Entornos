#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
status=0
declare -a packages=()

command -v apt-get >/dev/null 2>&1 || {
  printf 'NO EJECUTADO: apt-get no está disponible.\n' >&2
  exit 2
}

mapfile -t packages < <(
  awk '$1 == "required" || $1 == "optional" { print $2 }' \
    "$ROOT_DIR"/packages/*.txt "$ROOT_DIR"/packages/security-lab/*.txt |
    sort -u
)

for package in "${packages[@]}"; do
  if ! apt-get --simulate install -- "$package" >/dev/null 2>&1; then
    printf 'NO RESOLUBLE INDIVIDUALMENTE: %s\n' "$package" >&2
    status=1
  fi
done

if ! apt-get --simulate install -- "${packages[@]}" >/dev/null 2>&1; then
  printf 'EL CONJUNTO COMPLETO TIENE CONFLICTOS DE DEPENDENCIAS.\n' >&2
  status=1
fi

if (( status == 0 )); then
  printf 'Todos los paquetes y el conjunto completo son resolubles por APT.\n'
fi

exit "$status"
