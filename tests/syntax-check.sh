#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
status=0
count=0

while IFS= read -r -d '' file; do
  count=$((count + 1))
  if ! bash -n "$file"; then
    printf 'ERROR de sintaxis: %s\n' "${file#"$ROOT_DIR/"}" >&2
    status=1
  fi
done < <(find "$ROOT_DIR" \
  -path "$ROOT_DIR/.git" -prune -o \
  -path "$ROOT_DIR/legacy" -prune -o \
  -type f -name '*.sh' -print0)

if (( count == 0 )); then
  printf 'ERROR: no se encontraron scripts Bash activos.\n' >&2
  exit 1
fi

if (( status == 0 )); then
  printf 'Sintaxis Bash válida en %d archivos activos.\n' "$count"
fi

exit "$status"
