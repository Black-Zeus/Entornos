#!/usr/bin/env bash

# Estas constantes se consumen desde install.sh al cargar esta biblioteca.
# shellcheck disable=SC2034

readonly EXIT_OK=0
readonly EXIT_USAGE=2
readonly EXIT_UNSUPPORTED=3
readonly EXIT_DEPENDENCY=4
readonly EXIT_OPERATION=5

DRY_RUN="${DRY_RUN:-0}"
declare -a RECOVERABLE_ERRORS=()
declare -a OPTIONAL_ERRORS=()

quote_command() {
  printf '%q ' "$@"
}

run_command() {
  if (( DRY_RUN )); then
    printf '[dry-run] '
    quote_command "$@"
    printf '\n'
    return 0
  fi
  "$@"
}

record_recoverable() {
  RECOVERABLE_ERRORS+=("$1")
  log_warn "$1"
}

record_optional() {
  OPTIONAL_ERRORS+=("$1")
  log_warn "Opcional: $1"
}

require_command() {
  local command_name="$1"
  command -v "$command_name" >/dev/null 2>&1 || {
    log_error "Dependencia obligatoria ausente: $command_name"
    return "$EXIT_DEPENDENCY"
  }
}

join_by() {
  local separator="$1"
  shift
  local first=1 item
  for item in "$@"; do
    (( first )) || printf '%s' "$separator"
    printf '%s' "$item"
    first=0
  done
}
