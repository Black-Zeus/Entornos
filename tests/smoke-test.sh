#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
required=(
  install.sh AGENTS.md README.md
  docs/audit-report.md docs/architecture.md docs/testing.md
  lib/common.sh lib/logging.sh lib/detect-system.sh lib/packages-apt.sh
  lib/deploy-dotfiles.sh lib/backup.sh
  packages/base.txt packages/desktop.txt packages/vmware.txt packages/security-lab.txt
)

for path in "${required[@]}"; do
  [[ -e "$ROOT_DIR/$path" ]] || { printf 'Falta archivo requerido: %s\n' "$path" >&2; exit 1; }
done

for executable in install.sh tests/syntax-check.sh tests/static-analysis.sh tests/smoke-test.sh \
  dotfiles/bspwm/bspwmrc dotfiles/polybar/launch.sh scripts/vpn-status.sh \
  scripts/target-status.sh scripts/screenshot.sh scripts/lab-update.sh; do
  [[ -x "$ROOT_DIR/$executable" ]] || { printf 'No es ejecutable: %s\n' "$executable" >&2; exit 1; }
done

fixture_dir="$(mktemp -d)"
cleanup() { rm -rf -- "$fixture_dir"; }
trap cleanup EXIT

printf 'ID=parrot\nID_LIKE=debian\nPRETTY_NAME="Parrot Security"\n' > "$fixture_dir/os-release"

PARROT_INSTALLER_TESTING=1 \
PARROT_OS_RELEASE_FILE="$fixture_dir/os-release" \
PARROT_EUID_OVERRIDE=1000 \
PARROT_USER_OVERRIDE=tester \
PARROT_HOME_OVERRIDE="$fixture_dir/home/tester" \
PARROT_VIRT_OVERRIDE=vmware \
  "$ROOT_DIR/install.sh" --components base,desktop,vmware --dry-run > "$fixture_dir/dry-run.log"

grep -q 'MODO DRY-RUN' "$fixture_dir/dry-run.log"
grep -q 'Resumen final' "$fixture_dir/dry-run.log"
[[ ! -e "$fixture_dir/home/tester/.config/bspwm/bspwmrc" ]] || {
  printf 'El dry-run modificó el home simulado.\n' >&2
  exit 1
}

# Prueba aislada de backup y despliegue real; solo escribe dentro del temporal.
PARROT_INSTALLER_TESTING=1 bash -c '
  set -Eeuo pipefail
  source "$1/lib/common.sh"
  source "$1/lib/logging.sh"
  source "$1/lib/backup.sh"
  source "$1/lib/deploy-dotfiles.sh"
  DRY_RUN=0
  LOG_FILE="$2/test.log"
  BACKUP_ROOT="$2/backups"
  mkdir -p "$2/source" "$2/home/.config/demo"
  printf old > "$2/home/.config/demo/file"
  printf new > "$2/source/file"
  deploy_file "$2/source/file" "$2/home/.config/demo/file"
  [[ "$(cat "$2/home/.config/demo/file")" == new ]]
  find "$2/backups" -type f -name file | grep -q .
' bash "$ROOT_DIR" "$fixture_dir"

printf 'Smoke test superado sin modificar el sistema.\n'
