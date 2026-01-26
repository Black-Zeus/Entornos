#!/usr/bin/env bash

#####################################################################################################
#                                                                                                   #
# Script de Instalación BSPWM para Arch Linux                                                      #
# Autor: Black-Zeus                                                                                #
# Versión: 4.1 - Optimizado (Keys más rápido)                                                     #
#                                                                                                   #
#####################################################################################################

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Variables globales
CURRENT_USER=$(whoami)
USER_HOME="/home/$CURRENT_USER"
LOG_FILE="/tmp/bspwm-install-$(date +%Y%m%d-%H%M%S).log"

# Redirigir todo a log
exec > >(tee -a "$LOG_FILE")
exec 2>&1

# Verificar que no sea root
if [ "$(id -u)" -eq 0 ]; then
    echo -e "${RED}[✗] Este script NO debe ejecutarse como root${NC}"
    exit 1
fi

# Ctrl+C handler
trap ctrl_c INT
function ctrl_c() {
    echo -e "\n${RED}[✗] Instalación cancelada${NC}"
    echo -e "${YELLOW}[i] Log: $LOG_FILE${NC}\n"
    exit 1
}

# Funciones de logging
print_info() { echo -e "${GREEN}[✓]${NC} $1"; }
print_step() { echo -e "${CYAN}[→]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

# Banner
function show_banner() {
    clear
    echo -e "${BLUE}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║   ██████╗ ███████╗██████╗ ██╗    ██╗███╗   ███╗                    ║
║   ██╔══██╗██╔════╝██╔══██╗██║    ██║████╗ ████║                    ║
║   ██████╔╝███████╗██████╔╝██║ █╗ ██║██╔████╔██║                    ║
║   ██╔══██╗╚════██║██╔═══╝ ██║███╗██║██║╚██╔╝██║                    ║
║   ██████╔╝███████║██║     ╚███╔███╔╝██║ ╚═╝ ██║                    ║
║   ╚═════╝ ╚══════╝╚═╝      ╚══╝╚══╝ ╚═╝     ╚═╝                    ║
║                                                                      ║
║       Instalador Automatizado v4.1 (Optimizado)                     ║
║                     By: Black-Zeus                                  ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
}

# Detectar virtualización
function detect_virtualization() {
    print_step "Detectando entorno..."
    
    if systemd-detect-virt | grep -qi "vmware"; then
        INSTALL_VMWARE_TOOLS=true
        print_info "VMware detectado"
    else
        INSTALL_VMWARE_TOOLS=false
        print_info "No-VMware detectado"
    fi
    sleep 0.5
}

# Limpiar y reparar pacman (OPTIMIZADO - SIN refresh-keys)
function fix_pacman() {
    print_step "Reparando sistema de paquetes (método rápido)..."
    
    # Limpiar cache corrupto
    sudo rm -rf /var/cache/pacman/pkg/* 2>/dev/null || true
    
    # Limpiar locks
    sudo rm -f /var/lib/pacman/db.lck 2>/dev/null || true
    
    # Solo inicializar si no existe
    if [ ! -d /etc/pacman.d/gnupg ]; then
        print_info "Inicializando keyring por primera vez..."
        sudo pacman-key --init
        sudo pacman-key --populate archlinux
    fi
    
    # NO hacer refresh-keys (esto es lo que tarda mucho)
    # En su lugar, solo actualizar bases de datos
    print_info "Sincronizando bases de datos..."
    sudo pacman -Syy
    
    print_info "Sistema reparado (método rápido)\n"
    sleep 0.5
}

# Configurar pacman.conf para OMITIR validación de firmas (TEMPORAL)
function disable_signature_check() {
    print_step "Deshabilitando validación de firmas temporalmente..."
    
    # Backup del original
    sudo cp /etc/pacman.conf /etc/pacman.conf.backup
    
    # Cambiar SigLevel a Never temporalmente
    sudo sed -i 's/^SigLevel.*/SigLevel = Never/' /etc/pacman.conf
    
    print_warning "Firmas deshabilitadas (se restaurarán al final)\n"
    sleep 0.5
}

# Restaurar validación de firmas
function restore_signature_check() {
    print_step "Restaurando validación de firmas..."
    
    if [ -f /etc/pacman.conf.backup ]; then
        sudo mv /etc/pacman.conf.backup /etc/pacman.conf
        print_info "Firmas restauradas\n"
    fi
    sleep 0.5
}

# Actualizar sistema
function update_system() {
    print_step "Actualizando el sistema..."
    
    sudo pacman -Syu --noconfirm || {
        print_warning "Update falló, continuando..."
    }
    
    print_info "Sistema actualizado\n"
    sleep 0.5
}

# Instalar paquete (simplificado)
function safe_install() {
    local packages=("$@")
    sudo pacman -S --needed --noconfirm "${packages[@]}" 2>/dev/null || true
}

# Instalar Display Manager
function install_display_manager() {
    print_step "Instalando Display Manager..."
    
    safe_install xorg xorg-server xorg-xinit \
        lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
    
    sudo systemctl enable lightdm 2>/dev/null || true
    print_info "LightDM instalado\n"
    sleep 0.5
}

# VMware Tools
function install_vmware_tools() {
    if [ "$INSTALL_VMWARE_TOOLS" = true ]; then
        print_step "Instalando VMware Tools..."
        safe_install open-vm-tools xf86-video-vmware xf86-input-vmmouse
        sudo systemctl enable vmtoolsd 2>/dev/null || true
        print_info "VMware Tools instalado\n"
    fi
    sleep 0.5
}

# Paquetes base
function install_base_packages() {
    print_step "Instalando paquetes base..."
    
    safe_install \
        base base-devel linux-headers \
        networkmanager wget curl git \
        unzip zip p7zip \
        htop btop fastfetch
    
    sudo systemctl enable NetworkManager 2>/dev/null || true
    sudo systemctl start NetworkManager 2>/dev/null || true
    
    print_info "Paquetes base instalados\n"
    sleep 0.5
}

# BSPWM y componentes
function install_bspwm_components() {
    print_step "Instalando BSPWM..."
    
    safe_install \
        bspwm sxhkd polybar rofi picom \
        feh nitrogen dunst libnotify \
        kitty firefox \
        thunar file-roller \
        pipewire pipewire-pulse pavucontrol \
        brightnessctl xclip \
        neovim bat lsd \
        zsh ttf-jetbrains-mono-nerd \
        maim
    
    print_info "BSPWM instalado\n"
    sleep 0.5
}

# Paru
function install_paru() {
    print_step "Instalando Paru..."
    
    if command -v paru &> /dev/null; then
        print_info "Paru ya instalado\n"
        return
    fi
    
    cd /tmp
    rm -rf paru
    git clone --depth=1 https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm --needed
    cd "$USER_HOME"
    
    print_info "Paru instalado\n"
    sleep 0.5
}

# AUR packages
function install_aur_packages() {
    print_step "Instalando paquetes AUR..."
    
    if ! command -v paru &> /dev/null; then
        print_warning "Paru no disponible\n"
        return
    fi
    
    paru -S --needed --noconfirm \
        google-chrome \
        visual-studio-code-bin \
        betterlockscreen 2>/dev/null || true
    
    print_info "Paquetes AUR instalados\n"
    sleep 0.5
}

# Directorios
function create_directories() {
    print_step "Creando directorios..."
    
    mkdir -p "$USER_HOME/.config"/{polybar,rofi,nvim,sxhkd,bspwm,kitty,dunst,picom,nitrogen}
    mkdir -p "$USER_HOME"/{WallPapers,Screenshots}
    mkdir -p "$USER_HOME/.local/bin"
    
    print_info "Directorios creados\n"
    sleep 0.5
}

# Descargar configs
function download_configurations() {
    print_step "Descargando configuraciones..."
    
    cd "$USER_HOME"
    
    curl -fsSL https://raw.githubusercontent.com/Black-Zeus/Entornos/main/Wall_OnePiece.png \
        -o "$USER_HOME/WallPapers/wall.png" 2>/dev/null || true
    
    if curl -fsSL https://raw.githubusercontent.com/Black-Zeus/Entornos/main/config.zip \
        -o /tmp/config.zip 2>/dev/null; then
        unzip -q /tmp/config.zip -d "$USER_HOME/ConfigFiles" 2>/dev/null || true
    fi
    
    print_info "Configs descargadas\n"
    sleep 0.5
}

# Copiar configs
function copy_configurations() {
    print_step "Copiando configuraciones..."
    
    if [ -d "$USER_HOME/ConfigFiles" ]; then
        cp -r "$USER_HOME/ConfigFiles"/* "$USER_HOME/.config/" 2>/dev/null || true
    fi
    
    print_info "Configs copiadas\n"
    sleep 0.5
}

# Configs por defecto
function create_default_configs() {
    print_step "Creando configs por defecto..."
    
    # .xinitrc
    cat > "$USER_HOME/.xinitrc" << 'EOF'
#!/bin/sh
setxkbmap es &
picom -b &
nitrogen --restore &
~/.config/polybar/launch.sh &
dunst &
exec bspwm
EOF
    chmod +x "$USER_HOME/.xinitrc"
    
    # bspwmrc
    cat > "$USER_HOME/.config/bspwm/bspwmrc" << 'EOF'
#!/bin/sh
pgrep -x sxhkd > /dev/null || sxhkd &
bspc monitor -d 1 2 3 4 5 6 7 8 9 10
bspc config border_width 2
bspc config window_gap 12
EOF
    chmod +x "$USER_HOME/.config/bspwm/bspwmrc"
    
    # sxhkdrc
    cat > "$USER_HOME/.config/sxhkd/sxhkdrc" << 'EOF'
super + Return
    kitty
super + d
    rofi -show drun
super + shift + {q,r}
    bspc {quit,wm -r}
super + shift + c
    bspc node -c
super + {h,j,k,l}
    bspc node -f {west,south,north,east}
super + {1-9,0}
    bspc desktop -f '^{1-9,10}'
super + f
    bspc node -t ~fullscreen
EOF
    
    # Polybar
    mkdir -p "$USER_HOME/.config/polybar"
    cat > "$USER_HOME/.config/polybar/launch.sh" << 'EOF'
#!/bin/bash
killall -q polybar
polybar main &
EOF
    chmod +x "$USER_HOME/.config/polybar/launch.sh"
    
    # Sesión BSPWM
    sudo tee /usr/share/xsessions/bspwm.desktop > /dev/null << EOF
[Desktop Entry]
Name=BSPWM
Exec=$USER_HOME/.xinitrc
Type=Application
EOF
    
    print_info "Configs creadas\n"
    sleep 0.5
}

# ZSH
function configure_zsh() {
    print_step "Configurando ZSH..."
    
    sudo chsh -s "$(which zsh)" "$CURRENT_USER" 2>/dev/null || true
    
    if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>/dev/null || true
    fi
    
    print_info "ZSH configurado\n"
    sleep 0.5
}

# Servicios
function enable_services() {
    print_step "Habilitando servicios..."
    
    sudo systemctl enable NetworkManager 2>/dev/null || true
    sudo systemctl enable lightdm 2>/dev/null || true
    sudo systemctl set-default graphical.target 2>/dev/null || true
    
    print_info "Servicios habilitados\n"
    sleep 0.5
}

# Limpieza
function cleanup() {
    print_step "Limpiando..."
    
    rm -rf "$USER_HOME/ConfigFiles" 2>/dev/null || true
    sudo pacman -Scc --noconfirm
    
    print_info "Limpieza completada\n"
    sleep 0.5
}

# Resumen
function show_summary() {
    show_banner
    
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║            ¡Instalación completada!                                  ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════╝${NC}\n"
    
    echo -e "${CYAN}[i]${NC} Log: ${PURPLE}$LOG_FILE${NC}\n"
    echo -e "${YELLOW}Próximos pasos:${NC}"
    echo -e "  1. ${PURPLE}sudo reboot${NC}"
    echo -e "  2. Selecciona ${GREEN}BSPWM${NC} en LightDM\n"
    
    echo -e "${YELLOW}Atajos:${NC}"
    echo -e "  • Super + Enter → Terminal"
    echo -e "  • Super + D → Rofi\n"
    
    fastfetch 2>/dev/null || neofetch 2>/dev/null || true
}

# Main
function main() {
    show_banner
    
    echo -e "${YELLOW}[!]${NC} Instalación 100% automática y RÁPIDA"
    echo -e "${YELLOW}[!]${NC} Validación de firmas DESHABILITADA temporalmente\n"
    echo -e "${CYAN}Presiona Enter para comenzar...\n${NC}"
    read
    
    detect_virtualization
    disable_signature_check  # ← CLAVE: Deshabilita firmas
    fix_pacman
    update_system
    install_display_manager
    install_vmware_tools
    install_base_packages
    install_bspwm_components
    install_paru
    install_aur_packages
    create_directories
    download_configurations
    copy_configurations
    create_default_configs
    configure_zsh
    enable_services
    cleanup
    restore_signature_check  # ← Restaura firmas
    show_summary
}

main
