#!/usr/bin/env bash
set -Eeuo pipefail

command -v rofi >/dev/null 2>&1 || {
  printf 'ERROR: Rofi no está disponible.\n' >&2
  exit 1
}

options=$'Bloquear equipo\nCerrar sesión\nReiniciar\nApagar'
if ! selection="$(printf '%s\n' "$options" | rofi -dmenu -i -p 'Energía')"; then
  exit 0
fi
[[ -n "$selection" ]] || exit 0

if [[ "$selection" == 'Bloquear equipo' ]]; then
  command -v i3lock >/dev/null 2>&1 || {
    printf 'ERROR: i3lock no está disponible.\n' >&2
    exit 1
  }
  exec i3lock --color=252a34
fi

if ! confirmation="$(printf 'No\nSí\n' | rofi -dmenu -i -p "Confirmar: $selection")"; then
  exit 0
fi
[[ "$confirmation" == 'Sí' ]] || exit 0

case "$selection" in
  'Cerrar sesión')
    command -v bspc >/dev/null 2>&1 || {
      printf 'ERROR: bspc no está disponible.\n' >&2
      exit 1
    }
    bspc quit
    ;;
  Reiniciar)
    systemctl reboot
    ;;
  Apagar)
    systemctl poweroff
    ;;
  *)
    printf 'ERROR: opción no reconocida.\n' >&2
    exit 2
    ;;
esac
