#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

vpn_dir="${VPN_DIR:-$HOME/Entornos/VPN}"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/parrot-security-lab/vpn"
pid_file="$state_dir/openvpn.pid"
log_file="$state_dir/openvpn.log"
launcher_log="$state_dir/authorization.log"
status_file="$state_dir/status"
export SUDO_ASKPASS="${SUDO_ASKPASS:-/usr/bin/ksshaskpass}"

notify() {
  local urgency="$1" message="$2"
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -u "$urgency" 'VPN' "$message"
  else
    printf '%s\n' "$message" >&2
  fi
}

set_status() { printf '%s\n' "$1" > "$status_file"; }

managed_pid() {
  local pid command
  [[ -r "$pid_file" ]] || return 1
  IFS= read -r pid < "$pid_file"
  [[ "$pid" =~ ^[1-9][0-9]*$ ]] || return 1
  command="$(ps -p "$pid" -o comm= 2>/dev/null | awk '{$1=$1; print}')"
  [[ "$command" == openvpn ]] || return 1
  printf '%s\n' "$pid"
}

show_log() {
  if [[ ! -s "$log_file" ]]; then
    notify normal 'Todavía no existe un log de OpenVPN.'
    return 0
  fi
  if command -v kitty >/dev/null 2>&1; then
    kitty --title 'OpenVPN log' tail -n 200 -f -- "$log_file" &
  else
    tail -n 50 -- "$log_file"
  fi
}

stop_vpn() {
  local pid
  if ! pid="$(managed_pid)"; then
    notify critical 'No existe una sesión OpenVPN administrada que pueda cerrarse.'
    set_status error
    return 1
  fi
  if ! sudo -A /bin/kill -TERM "$pid"; then
    notify critical 'No fue posible detener OpenVPN. Revisa la autorización gráfica.'
    set_status error
    return 1
  fi
  rm -f -- "$pid_file"
  set_status disconnected
  notify normal 'VPN desconectada.'
}

select_config() {
  local selection
  local -a configs=()
  mapfile -d '' configs < <(find "$vpn_dir" -maxdepth 1 -type f -iname '*.ovpn' -print0 | sort -z)
  if ((${#configs[@]} == 0)); then
    notify critical "No hay archivos .ovpn en $vpn_dir"
    return 1
  fi
  selection="$(printf '%s\n' "${configs[@]##*/}" | rofi -dmenu -i -p 'Conectar VPN')" || return 1
  [[ -n "$selection" ]] || return 1
  printf '%s\n' "$vpn_dir/$selection"
}

start_vpn() {
  local config attempt error_detail
  config="$(select_config)" || return 0
  [[ -f "$config" && ! -L "$config" ]] || {
    notify critical 'La configuración seleccionada no es un archivo regular permitido.'
    return 1
  }

  : > "$log_file"
  : > "$launcher_log"
  : > "$pid_file"
  chmod 0600 "$log_file" "$launcher_log" "$pid_file"
  set_status connecting

  if ! sudo -A /usr/sbin/openvpn --config "$config" --daemon \
      --writepid "$pid_file" --log-append "$log_file" 2> "$launcher_log"; then
    [[ ! -s "$launcher_log" ]] || cat -- "$launcher_log" >> "$log_file"
    set_status error
    error_detail="$(tail -n 1 -- "$log_file")"
    notify critical "OpenVPN no pudo iniciarse. ${error_detail:-Revisa el log desde la tarjeta VPN.}"
    return 1
  fi
  [[ ! -s "$launcher_log" ]] || cat -- "$launcher_log" >> "$log_file"

  for ((attempt = 0; attempt < 15; attempt += 1)); do
    if ip -o link show 2>/dev/null | awk -F': ' '$2 ~ /^(tun|tap)[[:alnum:]_.-]*$/ {found=1} END {exit !found}'; then
      set_status connected
      notify normal "VPN conectada con ${config##*/}."
      return 0
    fi
    managed_pid >/dev/null || break
    sleep 1
  done

  set_status error
  notify critical 'OpenVPN no creó una interfaz VPN. Pulsa la tarjeta para consultar el log.'
  return 1
}

mkdir -p -- "$state_dir" "$vpn_dir"
chmod 0700 "$state_dir"
[[ ! -e "$status_file" ]] || chmod 0600 "$status_file"

for dependency in ip rofi sudo; do
  command -v "$dependency" >/dev/null 2>&1 || {
    notify critical "Dependencia ausente: $dependency"
    exit 1
  }
done
[[ -x "$SUDO_ASKPASS" ]] || {
  notify critical "Askpass gráfico ausente: $SUDO_ASKPASS"
  exit 1
}
[[ -x /usr/sbin/openvpn ]] || {
  notify critical 'Dependencia ausente: /usr/sbin/openvpn'
  exit 1
}

if [[ "${1:-}" == '--log' ]]; then
  show_log
  exit 0
fi

if managed_pid >/dev/null; then
  option="$(printf 'Desconectar\nVer log\nCancelar\n' | rofi -dmenu -i -p 'VPN activa')" || exit 0
  case "$option" in
    Desconectar) stop_vpn ;;
    'Ver log') show_log ;;
    *) exit 0 ;;
  esac
else
  if [[ -r "$status_file" ]] && grep -qx 'error' "$status_file"; then
    option="$(printf 'Ver log\nReintentar\nCancelar\n' | rofi -dmenu -i -p 'VPN con error')" || exit 0
    case "$option" in
      'Ver log') show_log ;;
      Reintentar) start_vpn ;;
      *) exit 0 ;;
    esac
  else
    start_vpn
  fi
fi
