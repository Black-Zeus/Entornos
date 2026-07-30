#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
status=0

command -v apt-cache >/dev/null 2>&1 || {
  printf 'NO EJECUTADO: apt-cache no está disponible.\n' >&2
  exit 2
}

while IFS= read -r package; do
  if ! LC_ALL=C apt-cache policy "$package" |
      awk '$1 == "Candidate:" && $2 != "(none)" { found=1 } END { exit !found }'; then
    printf 'SIN CANDIDATO: %s\n' "$package" >&2
    status=1
  fi
done < <(
  awk '$1 == "required" || $1 == "optional" { print $2 }' \
    "$ROOT_DIR"/packages/*.txt "$ROOT_DIR"/packages/security-lab/*.txt |
    sort -u
)

if (( status == 0 )); then
  printf 'Todos los paquetes declarados tienen candidato APT.\n'
fi

exit "$status"
