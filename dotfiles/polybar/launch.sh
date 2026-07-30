#!/usr/bin/env bash
set -u

config_file="$HOME/.config/polybar/config.ini"
bars=(logo clock network vpn workspaces metrics target power)
log_dir="$HOME/.cache/polybar"
mkdir -p -- "$log_dir"

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


launch_bars() {
  local monitor="${1:-}"
  local bar
  for bar in "${bars[@]}"; do
    : > "$log_dir/$bar.log"
    if [[ -n "$monitor" ]]; then
      MONITOR="$monitor" polybar --config="$config_file" "$bar" \
        >> "$log_dir/$bar.log" 2>&1 &
    else
      polybar --config="$config_file" "$bar" \
        >> "$log_dir/$bar.log" 2>&1 &
    fi
    # Evita carreras de mapeo/apilado entre varias ventanas override-redirect.
    sleep 0.12
  done
}

if ((${#monitors[@]} == 0)); then
  launch_bars
else
  for monitor in "${monitors[@]}"; do
    launch_bars "$monitor"
  done
fi
