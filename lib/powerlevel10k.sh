#!/usr/bin/env bash

readonly POWERLEVEL10K_VERSION='1.20.0'
readonly POWERLEVEL10K_URL="https://github.com/romkatv/powerlevel10k/archive/refs/tags/v${POWERLEVEL10K_VERSION}.tar.gz"
readonly POWERLEVEL10K_SHA256='d8187d44b697b3a37a8c4896678b4380e717cbf2850179529358348780a2d3d7'

install_powerlevel10k() {
  local install_dir="$REAL_HOME/.local/share/powerlevel10k/$POWERLEVEL10K_VERSION"
  local theme="$install_dir/powerlevel10k.zsh-theme"
  local temp_dir archive actual_checksum

  if [[ -r "$theme" ]]; then
    log_info "Powerlevel10k $POWERLEVEL10K_VERSION ya está instalado."
    return 0
  fi

  if (( DRY_RUN )); then
    printf '[dry-run] descargar y verificar Powerlevel10k %s -> %s\n' \
      "$POWERLEVEL10K_VERSION" "$install_dir"
    return 0
  fi

  temp_dir="$(mktemp -d)"
  archive="$temp_dir/powerlevel10k.tar.gz"
  if ! curl --proto '=https' --tlsv1.2 --fail --location --retry 3 \
    --output "$archive" "$POWERLEVEL10K_URL"; then
    rm -rf -- "$temp_dir"
    log_error 'No se pudo descargar Powerlevel10k desde el repositorio oficial.'
    return "$EXIT_OPERATION"
  fi

  actual_checksum="$(sha256sum "$archive" | awk '{print $1}')"
  if [[ "$actual_checksum" != "$POWERLEVEL10K_SHA256" ]]; then
    rm -rf -- "$temp_dir"
    log_error 'El checksum de Powerlevel10k no coincide; se rechazó el archivo.'
    return "$EXIT_OPERATION"
  fi

  mkdir -p -- "$install_dir"
  tar -xzf "$archive" --strip-components=1 -C "$install_dir"
  if [[ "$EUID" == 0 ]]; then
    chown -R "$REAL_USER:" "$REAL_HOME/.local/share/powerlevel10k"
  fi
  rm -rf -- "$temp_dir"
  log_info "Powerlevel10k $POWERLEVEL10K_VERSION instalado y verificado."
}
