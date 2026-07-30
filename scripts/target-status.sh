#!/usr/bin/env bash
set -u

state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
target_file="${LAB_TARGET_FILE:-$state_home/parrot-security-lab/target}"

if [[ ! -r "$target_file" ]]; then
  printf 'TARGET --\n'
  exit 0
fi

IFS=' ' read -r address name _ < "$target_file" || true
if [[ -z "${address:-}" ]]; then
  printf 'TARGET --\n'
elif [[ -n "${name:-}" ]]; then
  printf 'TARGET %s (%s)\n' "$address" "$name"
else
  printf 'TARGET %s\n' "$address"
fi
