#!/usr/bin/env bash
set -u

if ! command -v ip >/dev/null 2>&1; then
  printf 'VPN --\n'
  exit 0
fi

interface="$(ip -o link show 2>/dev/null | awk -F': ' '$2 ~ /^(tun|tap|wg)[[:alnum:]_.-]*$/ {print $2; exit}')"
if [[ -z "$interface" ]]; then
  printf 'VPN --\n'
  exit 0
fi

address="$(ip -o -4 address show dev "$interface" 2>/dev/null | awk '{split($4,a,"/"); print a[1]; exit}')"
if [[ -n "$address" ]]; then
  printf 'VPN %s %s\n' "$interface" "$address"
else
  printf 'VPN %s --\n' "$interface"
fi
