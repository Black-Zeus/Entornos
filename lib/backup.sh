#!/usr/bin/env bash

BACKUP_ROOT="${BACKUP_ROOT:-}"

init_backup() {
  local state_dir="$1"
  local timestamp
  timestamp="$(date '+%Y%m%d-%H%M%S')"
  BACKUP_ROOT="$state_dir/backups/$timestamp"
  if (( DRY_RUN )); then
    printf '[dry-run] Backup previsto: %s\n' "$BACKUP_ROOT"
  fi
}

backup_path() {
  local target="$1"
  local relative backup_target
  [[ -e "$target" || -L "$target" ]] || return 0
  [[ -n "$BACKUP_ROOT" ]] || { log_error 'BACKUP_ROOT no está inicializado.'; return "$EXIT_OPERATION"; }

  relative="${target#/}"
  backup_target="$BACKUP_ROOT/$relative"
  if (( DRY_RUN )); then
    printf '[dry-run] backup %q -> %q\n' "$target" "$backup_target"
    return 0
  fi

  mkdir -p -- "$BACKUP_ROOT" "$(dirname -- "$backup_target")"
  chmod 700 "$BACKUP_ROOT"
  if [[ "$EUID" == 0 && -n "${REAL_USER:-}" ]]; then
    chown "$REAL_USER:" "$BACKUP_ROOT"
  fi
  cp -a -- "$target" "$backup_target"
  if [[ "$EUID" == 0 && -n "${REAL_USER:-}" ]]; then
    chown -R "$REAL_USER:" "$backup_target"
  fi
  log_info "Backup creado: $backup_target"
}
