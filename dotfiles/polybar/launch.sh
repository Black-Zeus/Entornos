#!/usr/bin/env bash
set -u

polybar-msg cmd quit >/dev/null 2>&1 || true
for _ in {1..20}; do
  pgrep -x polybar >/dev/null 2>&1 || break
  sleep 0.1
done

if command -v xrandr >/dev/null 2>&1; then
  mapfile -t monitors < <(xrandr --query | awk '/ connected/{print $1}')
else
  monitors=()
fi

if ((${#monitors[@]} == 0)); then
  polybar main &
else
  for monitor in "${monitors[@]}"; do
    MONITOR="$monitor" polybar main &
  done
fi
