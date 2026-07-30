#!/usr/bin/env bash

LOG_FILE="${LOG_FILE:-}"

init_logging() {
  local log_dir="$1"
  local timestamp
  timestamp="$(date '+%Y%m%d-%H%M%S')"
  LOG_FILE="$log_dir/install-$timestamp.log"

  if (( DRY_RUN )); then
    printf '[dry-run] Log previsto: %s\n' "$LOG_FILE"
    return 0
  fi

  mkdir -p -- "$log_dir"
  chmod 700 "$log_dir"
  : > "$LOG_FILE"
  chmod 600 "$LOG_FILE"
  if [[ "$EUID" == 0 && -n "${REAL_USER:-}" ]]; then
    chown "$REAL_USER:" "$log_dir" "$LOG_FILE"
  fi
}

log_message() {
  local level="$1"
  shift
  local line
  line="$(date '+%Y-%m-%dT%H:%M:%S%z') [$level] $*"
  printf '%s\n' "$line"
  if [[ -n "$LOG_FILE" ]] && (( ! DRY_RUN )); then
    printf '%s\n' "$line" >> "$LOG_FILE"
  fi
}

log_info() { log_message INFO "$@"; }
log_warn() { log_message WARN "$@" >&2; }
log_error() { log_message ERROR "$@" >&2; }
log_step() { log_message STEP "$@"; }
