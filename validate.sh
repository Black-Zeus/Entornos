#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

checks=(
  "tests/syntax-check.sh"
  "tests/static-analysis.sh"
  "tests/smoke-test.sh"
  "tests/package-candidates.sh"
  "tests/package-installability.sh"
)

passed=0
failed=0
not_run=0

printf 'Validación integral de parrot-security-lab\n'
printf 'Repositorio: %s\n\n' "$ROOT_DIR"

for check in "${checks[@]}"; do
  printf '%s\n' "==> $check"

  if bash "$ROOT_DIR/$check"; then
    passed=$((passed + 1))
    printf 'RESULTADO: CORRECTO\n\n'
  else
    result=$?
    if (( result == 2 )); then
      not_run=$((not_run + 1))
      printf 'RESULTADO: NO EJECUTADO (código %d)\n\n' "$result" >&2
    else
      failed=$((failed + 1))
      printf 'RESULTADO: FALLÓ (código %d)\n\n' "$result" >&2
    fi
  fi
done

printf 'Resumen de validación\n'
printf '  Correctas: %d\n' "$passed"
printf '  Fallidas: %d\n' "$failed"
printf '  No ejecutadas: %d\n' "$not_run"

if (( failed > 0 )); then
  exit 1
fi

if (( not_run > 0 )); then
  exit 2
fi

printf 'Todas las validaciones finalizaron correctamente.\n'
