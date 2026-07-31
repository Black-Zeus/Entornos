#!/usr/bin/env bash

deploy_file() {
  local source_file="$1"
  local target_file="$2"
  local mode="${3:-0644}"

  [[ -f "$source_file" ]] || { log_error "Fuente inexistente: $source_file"; return "$EXIT_OPERATION"; }
  if [[ -f "$target_file" ]] && cmp -s -- "$source_file" "$target_file"; then
    if [[ "$EUID" == 0 && -n "${REAL_USER:-}" ]]; then
      chown "$REAL_USER:" "$(dirname -- "$target_file")" "$target_file"
    fi
    log_info "Sin cambios: $target_file"
    return 0
  fi

  if [[ -e "$target_file" || -L "$target_file" ]]; then
    backup_path "$target_file"
  fi

  if (( DRY_RUN )); then
    printf '[dry-run] instalar %q -> %q (modo %s)\n' "$source_file" "$target_file" "$mode"
    return 0
  fi

  mkdir -p -- "$(dirname -- "$target_file")"
  install -m "$mode" -- "$source_file" "$target_file"
  if [[ "$EUID" == 0 && -n "${REAL_USER:-}" ]]; then
    chown "$REAL_USER:" "$(dirname -- "$target_file")" "$target_file"
  fi
  log_info "Instalado: $target_file"
}

deploy_component_dotfiles() {
  local component="$1"
  local source_dir="$PROJECT_ROOT/dotfiles/$component"
  local target_dir="$REAL_HOME/.config/$component"
  local file relative mode

  [[ -d "$source_dir" ]] || { record_optional "No hay dotfiles para $component."; return 0; }
  while IFS= read -r -d '' file; do
    relative="${file#"$source_dir/"}"
    mode=0644
    case "$component/$relative" in
      bspwm/bspwmrc|polybar/launch.sh) mode=0755 ;;
    esac
    deploy_file "$file" "$target_dir/$relative" "$mode"
  done < <(find "$source_dir" -type f -print0)
}

deploy_desktop_dotfiles() {
  local component wallpaper relative
  for component in bspwm sxhkd polybar rofi picom kitty dunst; do
    deploy_component_dotfiles "$component"
  done
  deploy_file "$PROJECT_ROOT/assets/wallpapers/lab-wallpaper.png" \
    "$REAL_HOME/.local/share/backgrounds/parrot-security-lab/one-piece.png" 0644
  while IFS= read -r -d '' wallpaper; do
    relative="${wallpaper#"$PROJECT_ROOT/assets/wallpapers/hackerone/"}"
    deploy_file "$wallpaper" \
      "$REAL_HOME/.local/share/backgrounds/parrot-security-lab/hackerone/$relative" 0644
  done < <(find "$PROJECT_ROOT/assets/wallpapers/hackerone" -type f -print0)
}

deploy_base_dotfiles() {
  deploy_file "$PROJECT_ROOT/dotfiles/zsh/zshrc" "$REAL_HOME/.zshrc" 0644
  deploy_file "$PROJECT_ROOT/dotfiles/zsh/p10k.zsh" "$REAL_HOME/.p10k.zsh" 0644
  deploy_file "$PROJECT_ROOT/dotfiles/tmux/tmux.conf" "$REAL_HOME/.tmux.conf" 0644
}

deploy_lab_scripts() {
  local script
  for script in vpn-status.sh vpn-manager.sh interface-status.sh memory-status.sh target-status.sh target screenshot.sh lab-update.sh power-menu.sh wallpaper-cycle.sh; do
    deploy_file "$PROJECT_ROOT/scripts/$script" "$REAL_HOME/.local/bin/$script" 0755
  done
}
