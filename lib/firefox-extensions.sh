#!/usr/bin/env bash

readonly FIREFOX_POLICY_DIR='/etc/firefox/policies'
readonly FIREFOX_POLICY_FILE="$FIREFOX_POLICY_DIR/policies.json"

install_firefox_wappalyzer() {
  local source_policy="$PROJECT_ROOT/assets/firefox/wappalyzer-policy.json"
  local temp_dir merged_policy backup_target

  [[ -r "$source_policy" ]] || {
    log_error "Política de Wappalyzer ausente: $source_policy"
    return "$EXIT_OPERATION"
  }
  jq empty "$source_policy" || {
    log_error 'La política versionada de Wappalyzer no contiene JSON válido.'
    return "$EXIT_OPERATION"
  }

  if (( DRY_RUN )); then
    printf '[dry-run] combinar Wappalyzer firmado desde Mozilla Add-ons en %s\n' "$FIREFOX_POLICY_FILE"
    return 0
  fi

  temp_dir="$(mktemp -d)"
  merged_policy="$temp_dir/policies.json"

  if sudo test -f "$FIREFOX_POLICY_FILE"; then
    if ! sudo jq --slurpfile addition "$source_policy" \
        '.policies.ExtensionSettings = ((.policies.ExtensionSettings // {}) + $addition[0].policies.ExtensionSettings)' \
        "$FIREFOX_POLICY_FILE" | tee "$merged_policy" >/dev/null; then
      rm -rf -- "$temp_dir"
      log_error 'No se pudo combinar Wappalyzer con las políticas existentes de Firefox.'
      return "$EXIT_OPERATION"
    fi

    if sudo cmp -s -- "$merged_policy" "$FIREFOX_POLICY_FILE"; then
      rm -rf -- "$temp_dir"
      log_info 'Política de Wappalyzer para Firefox ya configurada.'
      return 0
    fi

    backup_target="$BACKUP_ROOT/${FIREFOX_POLICY_FILE#/}"
    mkdir -p -- "$(dirname -- "$backup_target")"
    chmod 700 "$BACKUP_ROOT"
    sudo cp -a -- "$FIREFOX_POLICY_FILE" "$backup_target"
    sudo chown "$REAL_USER:" "$backup_target"
    log_info "Backup creado: $backup_target"
  else
    cp -- "$source_policy" "$merged_policy"
  fi

  run_command sudo install -d -o root -g root -m 0755 -- "$FIREFOX_POLICY_DIR"
  run_command sudo install -o root -g root -m 0644 -- "$merged_policy" "$FIREFOX_POLICY_FILE"
  rm -rf -- "$temp_dir"
  log_info 'Wappalyzer configurado para instalarse desde Mozilla Add-ons al iniciar Firefox.'
}
