#!/usr/bin/env bash
set -Eeuo pipefail

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/.local/share/backgrounds/parrot-security-lab}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/parrot-security-lab"
STATE_FILE="$STATE_DIR/wallpaper-current"
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/parrot-security-lab-wallpaper.lock"
INTERVAL_SECONDS="${WALLPAPER_INTERVAL_SECONDS:-900}"

declare -a wallpapers=()

load_wallpapers() {
  wallpapers=()
  [[ -d "$WALLPAPER_DIR" ]] || return 0
  mapfile -d '' wallpapers < <(
    find "$WALLPAPER_DIR" -type f \
      \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
      -print0 | sort -z
  )
}

apply_wallpaper() {
  local wallpaper="$1"
  command -v feh >/dev/null 2>&1 || {
    printf 'ERROR: feh no está disponible.\n' >&2
    return 1
  }
  [[ -f "$wallpaper" ]] || return 1
  feh --no-fehbg --bg-fill -- "$wallpaper"
  mkdir -p -- "$STATE_DIR"
  printf '%s\n' "$wallpaper" > "$STATE_FILE"
}

next_wallpaper() {
  local current='' index next_index=0
  load_wallpapers
  ((${#wallpapers[@]})) || exit 0
  [[ -r "$STATE_FILE" ]] && IFS= read -r current < "$STATE_FILE"

  for index in "${!wallpapers[@]}"; do
    if [[ "${wallpapers[$index]}" == "$current" ]]; then
      next_index=$(((index + 1) % ${#wallpapers[@]}))
      break
    fi
  done
  apply_wallpaper "${wallpapers[$next_index]}"
}

select_wallpaper() {
  local selection='' wallpaper
  command -v rofi >/dev/null 2>&1 || {
    printf 'ERROR: Rofi no está disponible.\n' >&2
    return 1
  }
  load_wallpapers
  ((${#wallpapers[@]})) || exit 0

  if ! selection="$(printf '%s\n' "${wallpapers[@]##*/}" | rofi -dmenu -i -p 'Wallpaper')"; then
    exit 0
  fi
  [[ -n "$selection" ]] || exit 0
  for wallpaper in "${wallpapers[@]}"; do
    if [[ "${wallpaper##*/}" == "$selection" ]]; then
      apply_wallpaper "$wallpaper"
      return 0
    fi
  done
  printf 'ERROR: wallpaper no reconocido.\n' >&2
  return 2
}

run_locked() {
  command -v flock >/dev/null 2>&1 || {
    printf 'ERROR: flock no está disponible.\n' >&2
    return 1
  }
  flock -n 9 || exit 0
  "$@"
}

case "${1:---next}" in
  --next)
    run_locked next_wallpaper 9> "$LOCK_FILE"
    ;;
  --select)
    run_locked select_wallpaper 9> "$LOCK_FILE"
    ;;
  --daemon)
    [[ "$INTERVAL_SECONDS" =~ ^[1-9][0-9]*$ ]] || {
      printf 'ERROR: intervalo inválido: %s\n' "$INTERVAL_SECONDS" >&2
      exit 2
    }
    while sleep "$INTERVAL_SECONDS"; do
      run_locked next_wallpaper 9> "$LOCK_FILE"
    done
    ;;
  *)
    printf 'Uso: %s [--next|--select|--daemon]\n' "${0##*/}" >&2
    exit 2
    ;;
esac
