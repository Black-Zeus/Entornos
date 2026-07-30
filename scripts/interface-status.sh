#!/usr/bin/env bash
set -Eeuo pipefail

if ! command -v ip >/dev/null 2>&1; then
  exit 0
fi

declare -a interfaces=()
declare -A seen=()
default_interface="$(ip -4 route show default 2>/dev/null | awk '{print $5; exit}')"

add_interface() {
  local interface="$1"
  [[ -n "$interface" && -z "${seen[$interface]:-}" ]] || return 0
  if ip -o -4 address show dev "$interface" scope global 2>/dev/null | grep -q .; then
    interfaces+=("$interface")
    seen[$interface]=1
  fi
}

# La IP local aparece primero. Los clics avanzan luego por VPN y otras redes.
add_interface "$default_interface"
while read -r interface; do
  add_interface "$interface"
done < <(ip -o -4 address show up scope global 2>/dev/null | awk '{print $2}' | sort -u)

if ((${#interfaces[@]} == 0)); then
  exit 0
fi

# Cambia de interfaz en ventanas de cinco segundos. Con una sola interfaz el
# índice siempre es cero; no se requiere estado ni interacción del usuario.
index=$(( ($(date +%s) / 5) % ${#interfaces[@]} ))

interface="${interfaces[$index]}"
address="$(ip -o -4 address show dev "$interface" scope global | awk '{split($4,a,"/"); print a[1]; exit}')"
[[ -n "$address" ]] && printf '󰈀 %s %s\n' "$interface" "$address"
