#!/usr/bin/env bash

readonly GOOGLE_LINUX_KEY_URL='https://dl.google.com/linux/linux_signing_key.pub'
readonly GOOGLE_LINUX_KEY_FINGERPRINT='EB4C1BFD4F042F6DDDCCEC917721F63BD38B4796'
readonly GOOGLE_CHROME_KEYRING='/usr/share/keyrings/google-chrome.gpg'
readonly GOOGLE_CHROME_SOURCE='/etc/apt/sources.list.d/google-chrome.list'
readonly GOOGLE_CHROME_REPOSITORY='deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main'

google_key_has_expected_fingerprint() {
  local key_file="$1"
  gpg --batch --show-keys --with-colons -- "$key_file" 2>/dev/null |
    awk -F: -v expected="$GOOGLE_LINUX_KEY_FINGERPRINT" \
      '$1 == "fpr" && $10 == expected { found=1 } END { exit !found }'
}

google_repository_is_current() {
  [[ -r "$GOOGLE_CHROME_KEYRING" && -r "$GOOGLE_CHROME_SOURCE" ]] || return 1
  google_key_has_expected_fingerprint "$GOOGLE_CHROME_KEYRING" || return 1
  grep -Fxq -- "$GOOGLE_CHROME_REPOSITORY" "$GOOGLE_CHROME_SOURCE"
}

configure_google_chrome_repository() {
  local temp_dir key_ascii key_binary source_file

  if (( DRY_RUN )); then
    printf '[dry-run] verificar clave Google (%s) y configurar %s\n' \
      "$GOOGLE_LINUX_KEY_FINGERPRINT" "$GOOGLE_CHROME_SOURCE"
    return 0
  fi

  if google_repository_is_current; then
    log_info 'Repositorio APT oficial de Google Chrome ya configurado.'
    return 0
  fi

  temp_dir="$(mktemp -d)"
  key_ascii="$temp_dir/google-linux-signing-key.asc"
  key_binary="$temp_dir/google-chrome.gpg"
  source_file="$temp_dir/google-chrome.list"

  if ! curl --fail --silent --show-error --location \
      --proto '=https' --tlsv1.2 --output "$key_ascii" -- "$GOOGLE_LINUX_KEY_URL"; then
    rm -rf -- "$temp_dir"
    log_error 'No se pudo descargar la clave oficial de Google mediante TLS.'
    return "$EXIT_DEPENDENCY"
  fi

  if ! google_key_has_expected_fingerprint "$key_ascii"; then
    rm -rf -- "$temp_dir"
    log_error 'La clave descargada de Google no contiene la huella esperada.'
    return "$EXIT_DEPENDENCY"
  fi

  if ! gpg --batch --yes --dearmor --output "$key_binary" -- "$key_ascii"; then
    rm -rf -- "$temp_dir"
    log_error 'No se pudo convertir la clave de Google al formato de APT.'
    return "$EXIT_OPERATION"
  fi

  printf '%s\n' "$GOOGLE_CHROME_REPOSITORY" > "$source_file"
  run_command sudo install -o root -g root -m 0644 -- "$key_binary" "$GOOGLE_CHROME_KEYRING"
  run_command sudo install -o root -g root -m 0644 -- "$source_file" "$GOOGLE_CHROME_SOURCE"
  rm -rf -- "$temp_dir"
  log_info 'Repositorio APT oficial de Google Chrome configurado y verificado.'
}
