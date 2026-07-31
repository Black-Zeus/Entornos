#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
required=(
  install.sh README.md
  docs/audit-report.md docs/architecture.md docs/testing.md docs/keyboard-shortcuts.md
  lib/common.sh lib/logging.sh lib/detect-system.sh lib/packages-apt.sh lib/repositories-apt.sh
  lib/firefox-extensions.sh assets/firefox/wappalyzer-policy.json
  lib/deploy-dotfiles.sh lib/backup.sh lib/fonts.sh lib/powerlevel10k.sh
  packages/base.txt packages/desktop.txt packages/vmware.txt packages/security-lab.txt
  VPN/.gitignore VPN/README.md scripts/vpn-manager.sh
)

for path in "${required[@]}"; do
  [[ -e "$ROOT_DIR/$path" ]] || { printf 'Falta archivo requerido: %s\n' "$path" >&2; exit 1; }
done

for executable in install.sh tests/syntax-check.sh tests/static-analysis.sh tests/smoke-test.sh \
  dotfiles/bspwm/bspwmrc dotfiles/polybar/launch.sh scripts/vpn-status.sh scripts/vpn-manager.sh \
  scripts/interface-status.sh scripts/memory-status.sh scripts/target-status.sh scripts/target scripts/screenshot.sh scripts/lab-update.sh scripts/power-menu.sh scripts/wallpaper-cycle.sh; do
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
  "$ROOT_DIR/install.sh" --components base,desktop,vmware,security-lab --dry-run > "$fixture_dir/dry-run.log"

grep -q 'MODO DRY-RUN' "$fixture_dir/dry-run.log"
grep -q 'Resumen final' "$fixture_dir/dry-run.log"
grep -q 'Wappalyzer firmado desde Mozilla Add-ons' "$fixture_dir/dry-run.log"
[[ ! -e "$fixture_dir/home/tester/.config/bspwm/bspwmrc" ]] || {
  printf 'El dry-run modificó el home simulado.\n' >&2
  exit 1
}

PARROT_INSTALLER_TESTING=1 \
PARROT_OS_RELEASE_FILE="$fixture_dir/os-release" \
PARROT_EUID_OVERRIDE=1000 \
PARROT_USER_OVERRIDE=tester \
PARROT_HOME_OVERRIDE="$fixture_dir/home/tester" \
PARROT_VIRT_OVERRIDE=vmware \
  "$ROOT_DIR/install.sh" --components desktop --dry-run > "$fixture_dir/desktop-only.log"
grep -q '.local/bin/vpn-status.sh' "$fixture_dir/desktop-only.log"
grep -q '.local/bin/vpn-manager.sh' "$fixture_dir/desktop-only.log"
grep -q '^required openvpn$' "$ROOT_DIR/packages/base.txt"
grep -q '^required libnotify-bin$' "$ROOT_DIR/packages/base.txt"
grep -q '^required polkit-kde-agent-1$' "$ROOT_DIR/packages/desktop.txt"
grep -q '^required ksshaskpass$' "$ROOT_DIR/packages/desktop.txt"

printf 'ID=debian\nPRETTY_NAME="Debian de prueba"\n' > "$fixture_dir/not-parrot"
set +e
PARROT_INSTALLER_TESTING=1 \
PARROT_OS_RELEASE_FILE="$fixture_dir/not-parrot" \
PARROT_EUID_OVERRIDE=1000 \
PARROT_USER_OVERRIDE=tester \
PARROT_HOME_OVERRIDE="$fixture_dir/home/tester" \
  "$ROOT_DIR/install.sh" --dry-run > "$fixture_dir/rejected.log" 2>&1
rejected_status=$?
set -e
[[ "$rejected_status" == 3 ]] || {
  printf 'La detección no rechazó Debian con código 3 (obtenido: %s).\n' "$rejected_status" >&2
  exit 1
}
grep -q 'Sistema no soportado' "$fixture_dir/rejected.log"

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
