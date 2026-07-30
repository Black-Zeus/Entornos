#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
status=0
active_paths=(
  "$ROOT_DIR/install.sh"
  "$ROOT_DIR/lib"
  "$ROOT_DIR/scripts"
  "$ROOT_DIR/packages"
  "$ROOT_DIR/dotfiles"
)

fail_if_found() {
  local description="$1"
  local pattern="$2"
  shift 2
  local matches

  if matches="$(grep -RInE --exclude-dir=.git --exclude-dir=legacy "$pattern" "$@" 2>/dev/null)"; then
    printf 'ERROR: %s\n%s\n' "$description" "$matches" >&2
    status=1
  fi
}

fail_if_found 'gestores Arch en código activo' \
  '(^|[^[:alnum:]_])(pacman|pacstrap|arch-chroot|paru|yay)([^[:alnum:]_]|$)' \
  "${active_paths[@]}"
fail_if_found 'desactivación de firmas' 'SigLevel[[:space:]]*=[[:space:]]*Never' "${active_paths[@]}"
fail_if_found 'rutas personales hardcodeadas' '/home/(black|zeus|usuario|jaagr)(/|$)' \
  "${active_paths[@]}"

if command -v shellcheck >/dev/null 2>&1; then
  mapfile -d '' shell_files < <(find "$ROOT_DIR" \
    -path "$ROOT_DIR/.git" -prune -o \
    -path "$ROOT_DIR/legacy" -prune -o \
    -type f -name '*.sh' -print0)
  if ! shellcheck -x "${shell_files[@]}"; then
    status=1
  fi
else
  printf 'NO EJECUTADO: ShellCheck no está disponible.\n' >&2
fi

if (( status == 0 )); then
  printf 'Validaciones estáticas integradas superadas.\n'
fi

exit "$status"
