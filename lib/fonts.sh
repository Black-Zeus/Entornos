#!/usr/bin/env bash

readonly HACK_NERD_FONT_VERSION='3.4.0'
readonly HACK_NERD_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v${HACK_NERD_FONT_VERSION}/Hack.zip"
readonly HACK_NERD_FONT_SHA256='8ca33a60c791392d872b80d26c42f2bfa914a480f9eb2d7516d9f84373c36897'

install_hack_nerd_font() {
  local font_dir="$REAL_HOME/.local/share/fonts/HackNerdFont"
  local marker="$font_dir/.version"
  local temp_dir archive actual_checksum font

  if [[ -r "$marker" ]] && [[ "$(<"$marker")" == "$HACK_NERD_FONT_VERSION" ]]; then
    log_info "Hack Nerd Font $HACK_NERD_FONT_VERSION ya está instalada."
    return 0
  fi

  if (( DRY_RUN )); then
    printf '[dry-run] descargar y verificar Hack Nerd Font %s -> %s\n' \
      "$HACK_NERD_FONT_VERSION" "$font_dir"
    return 0
  fi

  temp_dir="$(mktemp -d)"
  archive="$temp_dir/Hack.zip"
  if ! curl --proto '=https' --tlsv1.2 --fail --location --retry 3 \
    --output "$archive" "$HACK_NERD_FONT_URL"; then
    rm -rf -- "$temp_dir"
    log_error 'No se pudo descargar Hack Nerd Font desde el release oficial.'
    return "$EXIT_OPERATION"
  fi

  actual_checksum="$(sha256sum "$archive" | awk '{print $1}')"
  if [[ "$actual_checksum" != "$HACK_NERD_FONT_SHA256" ]]; then
    rm -rf -- "$temp_dir"
    log_error 'El checksum de Hack Nerd Font no coincide; se rechazó el archivo.'
    return "$EXIT_OPERATION"
  fi

  mkdir -p -- "$temp_dir/extracted" "$font_dir"
  unzip -q "$archive" '*.ttf' -d "$temp_dir/extracted"
  while IFS= read -r -d '' font; do
    install -m 0644 -- "$font" "$font_dir/$(basename -- "$font")"
  done < <(find "$temp_dir/extracted" -type f -name '*.ttf' -print0)
  printf '%s\n' "$HACK_NERD_FONT_VERSION" > "$marker"

  if [[ "$EUID" == 0 ]]; then
    chown -R "$REAL_USER:" "$font_dir"
  fi
  fc-cache -f "$font_dir"
  rm -rf -- "$temp_dir"
  log_info "Hack Nerd Font $HACK_NERD_FONT_VERSION instalada y verificada."
}
