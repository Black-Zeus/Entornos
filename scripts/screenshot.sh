#!/usr/bin/env bash
set -Eeuo pipefail

command -v flameshot >/dev/null 2>&1 || {
  printf 'ERROR: flameshot no está instalado.\n' >&2
  exit 4
}

exec flameshot gui
