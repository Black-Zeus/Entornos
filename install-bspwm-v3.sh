#!/usr/bin/env bash

#####################################################################################################
#                                                                                                   #
# Script de Instalación BSPWM para Arch Linux                                                      #
# Autor: Black-Zeus                                                                                #
# Versión: 3.1 - Totalmente Automatizado con Auto-Reparación                                      #
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
    echo -e "${YELLOW}[i] Ejecuta como: ./install-bspwm.sh${NC}"
    exit 1
fi

# Ctrl+C handler
trap ctrl_c INT
function ctrl_c() {
    echo -e "\n${RED}[✗] Instalación cancelada${NC}"
    echo -e "${YELLOW}[i] Log guardado en: $LOG_FILE${NC}\n"
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
║       Instalador Automatizado con Auto-Reparación v4.0              ║
║                     By: Black-Zeus                                  ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
}

# Detectar entorno de virtualización
function detect_virtualization() {
    print_step "Detectando entorno..."
    
    if systemd-detect-virt | grep -qi "vmware"; then
        INSTALL_VMWARE_TOOLS=true
        print_info "VMware detectado - Se instalarán las herramientas"
    elif systemd-detect-virt | grep -qi "kvm\|qemu"; then
        INSTALL_VMWARE_TOOLS=false
        print_info "KVM/QEMU detectado - No se instalarán VMware Tools"
    elif systemd-detect-virt | grep -qi "virtualbox"; then
        INSTALL_VMWARE_TOOLS=false
        print_info "VirtualBox detectado - No se instalarán VMware Tools"
    else
        INSTALL_VMWARE_TOOLS=false
        print_info "Sistema físico o virtualización no detectada"
    fi
    
    sleep 1
}

# Limpiar y reparar pacman
function fix_pacman() {
    print_step "Reparando y limpiando sistema de paquetes..."
    
    # Limpiar cache corrupto
    print_info "Limpiando cache de pacman..."
    sudo rm -rf /var/cache/pacman/pkg/*
    
    # Actualizar llaves
    print_info "Actualizando llaves PGP..."
    sudo pacman-key --init
    sudo pacman-key --populate archlinux
    sudo pacman-key --refresh-keys
    
    # Limpiar locks
    sudo rm -f /var/lib/pacman/db.lck
    
    # Actualizar bases de datos
    print_info "Sincronizando bases de datos..."
    sudo pacman -Syy
    
    print_info "Sistema de paquetes reparado\n"
    sleep 1
}

# Actualizar sistema con reintentos
function update_system() {
    print_step "Actualizando el sistema..."
    
    local max_retries=3
    local retry=0
    
    while [ $retry -lt $max_retries ]; do
        if sudo pacman -Syu --noconfirm; then
            print_info "Sistema actualizado correctamente\n"
            return 0
        else
            retry=$((retry + 1))
            print_warning "Intento $retry/$max_retries falló, reintentando..."
            fix_pacman
        fi
    done
    
    print_error "No se pudo actualizar el sistema después de $max_retries intentos"
    return 1
}

# Instalar paquete con manejo de errores
function safe_install() {
    local packages=("$@")
    local failed_packages=()
    
    for package in "${packages[@]}"; do
        if pacman -Qi "$package" &>/dev/null; then
            continue
        fi
        
        if ! sudo pacman -S --needed --noconfirm "$package" 2>/dev/null; then
            failed_packages+=("$package")
            print_warning "Falló: $package (se intentará desde AUR después)"
        fi
    done
    
    if [ ${#failed_packages[@]} -gt 0 ]; then
        echo "${failed_packages[@]}" >> /tmp/failed_packages.txt
    fi
}

# Instalar Display Manager automáticamente (LightDM por defecto)
function install_display_manager() {
    print_step "Instalando Display Manager (LightDM)..."
    
    safe_install xorg xorg-server xorg-xinit \
        lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
    
    sudo systemctl enable lightdm 2>/dev/null
    print_info "LightDM instalado y habilitado\n"
    sleep 1
}

# Instalar VMware Tools si está en VMware
function install_vmware_tools() {
    if [ "$INSTALL_VMWARE_TOOLS" = true ]; then
        print_step "Instalando VMware Tools..."
        safe_install open-vm-tools xf86-video-vmware xf86-input-vmmouse
        sudo systemctl enable vmtoolsd 2>/dev/null
        sudo systemctl enable vmware-vmblock-fuse 2>/dev/null
        print_info "VMware Tools instalado\n"
    fi
    sleep 1
}

# Instalar paquetes base
function install_base_packages() {
    print_step "Instalando paquetes base del sistema..."
    
    safe_install \
        base base-devel linux-headers \
        net-tools networkmanager wireless_tools \
        git wget curl rsync \
        unrar zip unzip bzip2 lzip p7zip gzip \
        htop btop fastfetch \
        mlocate
    
    sudo systemctl enable NetworkManager 2>/dev/null
    sudo systemctl start NetworkManager 2>/dev/null
    
    print_info "Paquetes base instalados\n"
    sleep 1
}

# Instalar BSPWM y componentes
function install_bspwm_components() {
    print_step "Instalando BSPWM y componentes gráficos..."
    
    safe_install \
        bspwm sxhkd \
        polybar \
        rofi \
        picom \
        feh nitrogen \
        dunst libnotify \
        kitty alacritty \
        firefox \
        thunar thunar-volman thunar-archive-plugin thunar-media-tags-plugin \
        file-roller \
        pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber \
        pavucontrol \
        brightnessctl \
        xclip xdotool wmctrl \
        acpi \
        neovim \
        bat lsd fzf ripgrep fd eza \
        zsh zsh-completions \
        ttf-dejavu ttf-liberation noto-fonts noto-fonts-emoji \
        ttf-jetbrains-mono-nerd \
        cmatrix \
        maim scrot flameshot \
        redshift \
        playerctl
    
    print_info "BSPWM y componentes instalados\n"
    sleep 1
}

# Instalar Paru
function install_paru() {
    print_step "Instalando Paru (AUR Helper)..."
    
    if command -v paru &> /dev/null; then
        print_info "Paru ya está instalado\n"
        return
    fi
    
    cd /tmp
    rm -rf paru
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm --needed
    cd "$USER_HOME"
    
    print_info "Paru instalado\n"
    sleep 1
}

# Instalar paquetes de AUR
function install_aur_packages() {
    print_step "Instalando paquetes de AUR..."
    
    if ! command -v paru &> /dev/null; then
        print_warning "Paru no disponible, saltando paquetes AUR"
        return
    fi
    
    local aur_packages=(
        betterlockscreen
        google-chrome
        visual-studio-code-bin
        cava
    )
    
    for package in "${aur_packages[@]}"; do
        paru -S --needed --noconfirm "$package" 2>/dev/null || \
            print_warning "No se pudo instalar: $package (no crítico)"
    done
    
    # Reinstalar paquetes que fallaron en pacman
    if [ -f /tmp/failed_packages.txt ]; then
        while read -r package; do
            paru -S --needed --noconfirm "$package" 2>/dev/null || true
        done < /tmp/failed_packages.txt
        rm /tmp/failed_packages.txt
    fi
    
    print_info "Paquetes AUR instalados\n"
    sleep 1
}

# Crear estructura de directorios
function create_directories() {
    print_step "Creando estructura de directorios..."
    
    local config_dirs=(
        polybar rofi nvim sxhkd bspwm kitty 
        dunst picom nitrogen alacritty
    )
    
    for dir in "${config_dirs[@]}"; do
        mkdir -p "$USER_HOME/.config/$dir"
    done
    
    mkdir -p "$USER_HOME"/{WallPapers,ConfigFiles,Screenshots}
    mkdir -p "$USER_HOME/.local/bin"
    
    sudo mkdir -p /usr/share/{zsh-autosuggestions,zsh-sudo,zsh-syntax-highlighting}
    sudo mkdir -p /usr/share/fonts/{nerd-fonts,polybar}
    
    print_info "Directorios creados\n"
    sleep 1
}

# Descargar configuraciones con reintentos
function download_configurations() {
    print_step "Descargando configuraciones..."
    
    cd "$USER_HOME"
    
    # Wallpaper
    curl -fsSL https://raw.githubusercontent.com/Black-Zeus/Entornos/main/Wall_OnePiece.png \
        -o "$USER_HOME/WallPapers/Wall_OnePiece.png" || \
        print_warning "No se pudo descargar wallpaper"
    
    # Config.zip
    if curl -fsSL https://raw.githubusercontent.com/Black-Zeus/Entornos/main/config.zip \
        -o "$USER_HOME/ConfigFiles/config.zip"; then
        cd "$USER_HOME/ConfigFiles"
        unzip -q config.zip 2>/dev/null || print_warning "Error al descomprimir config.zip"
    else
        print_warning "No se pudo descargar config.zip - Se usarán configs por defecto"
    fi
    
    print_info "Configuraciones descargadas\n"
    sleep 1
}

# Instalar fuentes
function install_fonts() {
    print_step "Instalando fuentes..."
    
    cd /tmp
    
    # Hack Nerd Font
    if ! ls /usr/share/fonts/nerd-fonts/*Hack* &>/dev/null; then
        curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Hack.zip -o Hack.zip
        sudo unzip -q Hack.zip -d /usr/share/fonts/nerd-fonts/
        rm Hack.zip
    fi
    
    # Fuentes de Polybar
    if [ -d "$USER_HOME/ConfigFiles/polybar/fonts" ]; then
        sudo cp "$USER_HOME/ConfigFiles/polybar/fonts"/* /usr/share/fonts/polybar/ 2>/dev/null || true
    fi
    
    fc-cache -fv > /dev/null 2>&1
    
    print_info "Fuentes instaladas\n"
    sleep 1
}

# Copiar configuraciones con validación
function copy_configurations() {
    print_step "Copiando configuraciones..."
    
    local configs=(
        "bin:.config/"
        "zshrc/zshrc:.zshrc"
        "p10k/p10k.zsh:.p10k.zsh"
        "polybar:.config/polybar"
        "nvim:.config/nvim"
        "sxhkd:.config/sxhkd"
        "bspwm:.config/bspwm"
        "kitty:.config/kitty"
        "dunst:.config/dunst"
        "picom:.config/picom"
        "rofi:.config/rofi"
    )
    
    for config in "${configs[@]}"; do
        IFS=':' read -r src dst <<< "$config"
        if [ -e "$USER_HOME/ConfigFiles/$src" ]; then
            if [ -d "$USER_HOME/ConfigFiles/$src" ]; then
                cp -r "$USER_HOME/ConfigFiles/$src"/* "$USER_HOME/$dst/" 2>/dev/null || true
            else
                cp "$USER_HOME/ConfigFiles/$src" "$USER_HOME/$dst" 2>/dev/null || true
            fi
        fi
    done
    
    # Módulos ZSH
    if [ -d "$USER_HOME/ConfigFiles/zsh_modul" ]; then
        sudo cp -r "$USER_HOME/ConfigFiles/zsh_modul"/zsh-* /usr/share/ 2>/dev/null || true
    fi
    
    # Powerlevel10k
    if [ -d "$USER_HOME/ConfigFiles/powerlevel10k" ]; then
        cp -r "$USER_HOME/ConfigFiles/powerlevel10k" "$USER_HOME/" 2>/dev/null || true
    fi
    
    print_info "Configuraciones copiadas\n"
    sleep 1
}

# Crear configuraciones por defecto si no existen
function create_default_configs() {
    print_step "Creando configuraciones por defecto..."
    
    # .xinitrc
    cat > "$USER_HOME/.xinitrc" << 'EOF'
#!/bin/sh
setxkbmap es &
picom -b &
nitrogen --restore &
[ -f ~/.config/polybar/launch.sh ] && ~/.config/polybar/launch.sh &
dunst &
exec bspwm
EOF
    chmod +x "$USER_HOME/.xinitrc"
    
    # bspwmrc básico
    if [ ! -f "$USER_HOME/.config/bspwm/bspwmrc" ]; then
        cat > "$USER_HOME/.config/bspwm/bspwmrc" << 'EOF'
#!/bin/sh
pgrep -x sxhkd > /dev/null || sxhkd &
bspc monitor -d I II III IV V VI VII VIII IX X
bspc config border_width         2
bspc config window_gap          12
bspc config split_ratio          0.52
bspc config borderless_monocle   true
bspc config gapless_monocle      true
EOF
        chmod +x "$USER_HOME/.config/bspwm/bspwmrc"
    fi
    
    # sxhkdrc básico
    if [ ! -f "$USER_HOME/.config/sxhkd/sxhkdrc" ]; then
        cat > "$USER_HOME/.config/sxhkd/sxhkdrc" << 'EOF'
# Terminal
super + Return
    kitty

# Launcher
super + d
    rofi -show drun

# Reload
super + Escape
    pkill -USR1 -x sxhkd

# Quit/restart bspwm
super + shift + {q,r}
    bspc {quit,wm -r}

# Close window
super + shift + c
    bspc node -c

# Focus direction
super + {h,j,k,l}
    bspc node -f {west,south,north,east}

# Switch desktop
super + {1-9,0}
    bspc desktop -f '^{1-9,10}'

# Move to desktop
super + shift + {1-9,0}
    bspc node -d '^{1-9,10}'

# Fullscreen
super + f
    bspc node -t ~fullscreen

# Floating
super + shift + space
    bspc node -t ~floating
EOF
        chmod +x "$USER_HOME/.config/sxhkd/sxhkdrc"
    fi
    
    # Polybar launch.sh
    if [ ! -f "$USER_HOME/.config/polybar/launch.sh" ]; then
        mkdir -p "$USER_HOME/.config/polybar"
        cat > "$USER_HOME/.config/polybar/launch.sh" << 'EOF'
#!/bin/bash
killall -q polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done
polybar main &
EOF
        chmod +x "$USER_HOME/.config/polybar/launch.sh"
    fi
    
    # Sesión BSPWM
    sudo tee /usr/share/xsessions/bspwm.desktop > /dev/null << EOF
[Desktop Entry]
Name=BSPWM
Comment=Binary Space Partitioning Window Manager
Exec=$USER_HOME/.xinitrc
Type=Application
EOF
    
    print_info "Configuraciones por defecto creadas\n"
    sleep 1
}

# Configurar archivos
function configure_files() {
    print_step "Configurando archivos del sistema..."
    
    # Corregir .zshrc
    if [ -f "$USER_HOME/.zshrc" ]; then
        sed -i "s/alias cat='batcat'/alias cat='bat'/g" "$USER_HOME/.zshrc"
        sed -i "s/zeus/$CURRENT_USER/g" "$USER_HOME/.zshrc"
    fi
    
    # LightDM wallpaper
    if [ -f "$USER_HOME/WallPapers/Wall_OnePiece.png" ]; then
        sudo sed -i "s|^#background=.*|background=$USER_HOME/WallPapers/Wall_OnePiece.png|" \
            /etc/lightdm/lightdm-gtk-greeter.conf 2>/dev/null || true
    fi
    
    print_info "Archivos configurados\n"
    sleep 1
}

# Configurar permisos
function set_permissions() {
    print_step "Configurando permisos..."
    
    find "$USER_HOME/.config/bspwm" -type f -exec chmod +x {} \; 2>/dev/null || true
    find "$USER_HOME/.config/polybar" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    find "$USER_HOME/.local/bin" -type f -exec chmod +x {} \; 2>/dev/null || true
    
    # Links simbólicos
    if [ -f "$USER_HOME/.config/bspwm/scripts/power.sh" ]; then
        ln -sf "$USER_HOME/.config/bspwm/scripts/power.sh" \
            "$USER_HOME/.config/polybar/scripts/powermenu" 2>/dev/null || true
    fi
    
    print_info "Permisos configurados\n"
    sleep 1
}

# Configurar ZSH
function configure_zsh() {
    print_step "Configurando ZSH..."
    
    sudo chsh -s "$(which zsh)" "$CURRENT_USER" 2>/dev/null || true
    
    # Instalar Oh My Zsh si no existe
    if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    
    # Powerlevel10k
    if [ ! -d "${ZSH_CUSTOM:-$USER_HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
            "${ZSH_CUSTOM:-$USER_HOME/.oh-my-zsh/custom}/themes/powerlevel10k" 2>/dev/null || true
    fi
    
    # Configurar para root
    sudo mkdir -p /root/.config/nvim 2>/dev/null
    [ -f "$USER_HOME/.zshrc" ] && sudo ln -sf "$USER_HOME/.zshrc" /root/.zshrc 2>/dev/null || true
    [ -f "$USER_HOME/.p10k.zsh" ] && sudo ln -sf "$USER_HOME/.p10k.zsh" /root/.p10k.zsh 2>/dev/null || true
    
    print_info "ZSH configurado\n"
    sleep 1
}

# Configurar teclado
function configure_keyboard() {
    print_step "Configurando teclado español..."
    sudo localectl set-x11-keymap es 2>/dev/null || true
    print_info "Teclado configurado\n"
    sleep 1
}

# Habilitar servicios
function enable_services() {
    print_step "Habilitando servicios del sistema..."
    
    local services=(
        "NetworkManager"
        "lightdm"
    )
    
    [ "$INSTALL_VMWARE_TOOLS" = true ] && services+=("vmtoolsd" "vmware-vmblock-fuse")
    
    for service in "${services[@]}"; do
        sudo systemctl enable "$service" 2>/dev/null || true
    done
    
    # Cambiar a graphical target
    sudo systemctl set-default graphical.target 2>/dev/null || true
    
    print_info "Servicios habilitados\n"
    sleep 1
}

# Limpiar sistema
function cleanup() {
    print_step "Limpiando archivos temporales..."
    
    sudo rm -rf /usr/share/fonts/nerd-fonts/*.md 2>/dev/null
    rm -rf "$USER_HOME/ConfigFiles"
    sudo pacman -Scc --noconfirm
    command -v paru &>/dev/null && paru -Scc --noconfirm
    sudo updatedb 2>/dev/null || true
    
    print_info "Limpieza completada\n"
    sleep 1
}

# Resumen final
function show_summary() {
    show_banner
    
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                                      ║${NC}"
    echo -e "${GREEN}║            ¡Instalación completada exitosamente!                    ║${NC}"
    echo -e "${GREEN}║                                                                      ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════╝${NC}\n"
    
    echo -e "${CYAN}[i]${NC} Log completo guardado en: ${PURPLE}$LOG_FILE${NC}\n"
    
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  Próximos pasos:                                                     ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════════════╝${NC}\n"
    
    echo -e "  ${CYAN}1.${NC} Reinicia: ${PURPLE}sudo reboot${NC}"
    echo -e "  ${CYAN}2.${NC} Selecciona ${GREEN}BSPWM${NC} en LightDM"
    echo -e "  ${CYAN}3.${NC} Configura Powerlevel10k: ${PURPLE}p10k configure${NC}\n"
    
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  Atajos principales:                                                 ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════════════╝${NC}\n"
    
    echo -e "  ${CYAN}•${NC} Super + Enter   → Terminal"
    echo -e "  ${CYAN}•${NC} Super + D       → Rofi"
    echo -e "  ${CYAN}•${NC} Super + Shift + C → Cerrar ventana"
    echo -e "  ${CYAN}•${NC} Super + Shift + R → Recargar BSPWM\n"
    
    fastfetch 2>/dev/null || neofetch 2>/dev/null || true
    
    echo ""
}

# Función principal
function main() {
    show_banner
    
    echo -e "${YELLOW}[!]${NC} Instalación completamente automatizada de BSPWM"
    echo -e "${YELLOW}[!]${NC} No se requiere interacción del usuario\n"
    echo -e "${CYAN}[i]${NC} Presiona Enter para comenzar o Ctrl+C para cancelar\n"
    read
    
    detect_virtualization
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
    install_fonts
    copy_configurations
    create_default_configs
    configure_files
    set_permissions
    configure_zsh
    configure_keyboard
    enable_services
    cleanup
    show_summary
}

# Ejecutar
main
