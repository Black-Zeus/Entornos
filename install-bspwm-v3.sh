#!/usr/bin/env bash

#####################################################################################################
#                                                                                                   #
# Script de Instalación BSPWM para Arch Linux                                                      #
# Autor: Black-Zeus                                                                                #
# Versión: 3.0 - Mejorado y Actualizado para Arch 2026                                            #
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
NC='\033[0m' # Sin color

# Variables globales
CURRENT_USER=$(whoami)
USER_HOME="/home/$CURRENT_USER"

# Verificar que no sea root
if [ "$(id -u)" -eq 0 ]; then
    echo -e "${RED}[✗] Este script NO debe ejecutarse como root${NC}"
    echo -e "${YELLOW}[i] Ejecuta como: ./install-bspwm.sh${NC}"
    exit 1
fi

# Ctrl+C handler
trap ctrl_c INT
function ctrl_c() {
    echo -e "\n${RED}[✗] Instalación cancelada por el usuario${NC}\n"
    exit 1
}

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
║          Instalador Automatizado - Arch Linux + BSPWM               ║
║                        By: Black-Zeus                               ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
}

# Función para imprimir mensajes
print_info() { echo -e "${GREEN}[✓]${NC} $1"; }
print_step() { echo -e "${CYAN}[→]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

# Actualizar sistema
function update_system() {
    print_step "Actualizando el sistema..."
    sudo pacman -Syu --noconfirm
    print_info "Sistema actualizado\n"
    sleep 1
}

# Seleccionar Display Manager
function select_display_manager() {
    echo -e "${YELLOW}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  ¿Qué Display Manager deseas instalar?      ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════╝${NC}\n"
    echo "  1) LightDM (Ligero y rápido)"
    echo "  2) GDM (GNOME Display Manager)"
    echo ""
    
    while true; do
        read -p "Selecciona una opción [1-2]: " dm_choice
        case "$dm_choice" in
            1)
                DM="lightdm"
                DM_PACKAGES="lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings"
                DM_SERVICE="lightdm"
                break
                ;;
            2)
                DM="gdm"
                DM_PACKAGES="gdm"
                DM_SERVICE="gdm"
                break
                ;;
            *)
                print_error "Opción inválida. Por favor, selecciona 1 o 2."
                ;;
        esac
    done
    
    print_info "Display Manager seleccionado: $DM\n"
}

# Instalar Display Manager y Xorg
function install_display_manager() {
    print_step "Instalando Xorg y $DM..."
    sudo pacman -S --needed --noconfirm xorg xorg-server xorg-xinit $DM_PACKAGES
    
    sudo systemctl enable $DM_SERVICE
    print_info "$DM instalado y habilitado\n"
    sleep 1
}

# Preguntar por VMware Tools
function ask_vmware_tools() {
    echo -e "${YELLOW}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  ¿Instalar VMware Tools?                    ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════╝${NC}\n"
    
    while true; do
        read -p "¿Deseas instalar VMware Tools? [S/n]: " vmware_choice
        case "$vmware_choice" in
            s|S|"")
                print_step "Instalando VMware Tools..."
                sudo pacman -S --needed --noconfirm open-vm-tools xf86-video-vmware xf86-input-vmmouse
                sudo systemctl enable vmtoolsd
                sudo systemctl enable vmware-vmblock-fuse
                print_info "VMware Tools instalado\n"
                break
                ;;
            n|N)
                print_warning "Omitiendo VMware Tools\n"
                break
                ;;
            *)
                print_error "Opción inválida. Responde S o N."
                ;;
        esac
    done
    sleep 1
}

# Instalar paquetes base del sistema
function install_base_packages() {
    print_step "Instalando paquetes base del sistema..."
    
    sudo pacman -S --needed --noconfirm \
        base base-devel \
        linux-headers \
        net-tools networkmanager wireless_tools \
        git wget curl \
        unrar zip unzip bzip2 lzip p7zip gzip \
        htop btop neofetch fastfetch \
        mlocate
    
    # Habilitar NetworkManager
    sudo systemctl enable NetworkManager
    sudo systemctl start NetworkManager
    
    print_info "Paquetes base instalados\n"
    sleep 1
}

# Instalar BSPWM y componentes
function install_bspwm_components() {
    print_step "Instalando BSPWM y componentes..."
    
    sudo pacman -S --needed --noconfirm \
        bspwm sxhkd \
        polybar \
        rofi \
        picom \
        feh nitrogen \
        dunst \
        kitty \
        firefox \
        thunar thunar-volman thunar-archive-plugin thunar-media-tags-plugin \
        gvfs xfce4-power-manager file-roller \
        pulseaudio pulseaudio-bluetooth pulseaudio-alsa alsa-utils pamixer \
        brightnessctl \
        xclip xdotool \
        acpi \
        neovim vim \
        bat lsd fzf ripgrep fd \
        zsh zsh-completions \
        ttf-dejavu ttf-liberation noto-fonts noto-fonts-emoji \
        ttf-jetbrains-mono-nerd \
        cmatrix
    
    print_info "BSPWM y componentes instalados\n"
    sleep 1
}

# Instalar Paru (AUR Helper)
function install_paru() {
    print_step "Instalando Paru (AUR Helper)..."
    
    if command -v paru &> /dev/null; then
        print_warning "Paru ya está instalado\n"
        return
    fi
    
    cd /tmp
    rm -rf paru
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
    cd "$USER_HOME"
    
    print_info "Paru instalado\n"
    sleep 1
}

# Instalar paquetes de AUR
function install_aur_packages() {
    print_step "Instalando paquetes de AUR..."
    
    paru -S --needed --noconfirm \
        betterlockscreen \
        google-chrome \
        visual-studio-code-bin \
        cava \
        cbonsai \
        tty-clock \
        pipes.sh
    
    print_info "Paquetes de AUR instalados\n"
    sleep 1
}

# Crear estructura de directorios
function create_directories() {
    print_step "Creando estructura de directorios..."
    
    # Directorios de configuración
    local config_dirs=(
        polybar rofi nvim sxhkd bspwm kitty 
        dunst picom bin betterlockscreen nitrogen
    )
    
    for dir in "${config_dirs[@]}"; do
        mkdir -p "$USER_HOME/.config/$dir"
    done
    
    # Directorios personales
    mkdir -p "$USER_HOME"/{WallPapers,ConfigFiles,Screenshots}
    mkdir -p "$USER_HOME/.local/bin"
    
    # Directorios del sistema
    sudo mkdir -p /usr/share/{zsh-autosuggestions,zsh-sudo,zsh-syntax-highlighting}
    sudo mkdir -p /usr/share/fonts/{nerd-fonts,polybar}
    
    print_info "Directorios creados\n"
    sleep 1
}

# Descargar y configurar archivos
function download_configurations() {
    print_step "Descargando configuraciones..."
    
    cd "$USER_HOME"
    
    # Descargar wallpaper
    curl -sfL https://raw.githubusercontent.com/Black-Zeus/Entornos/main/Wall_OnePiece.png \
        -o "$USER_HOME/WallPapers/Wall_OnePiece.png"
    
    # Descargar config.zip
    curl -sfL https://raw.githubusercontent.com/Black-Zeus/Entornos/main/config.zip \
        -o "$USER_HOME/ConfigFiles/config.zip"
    
    # Descomprimir
    cd "$USER_HOME/ConfigFiles"
    unzip -q config.zip
    
    print_info "Configuraciones descargadas\n"
    sleep 1
}

# Instalar fuentes
function install_fonts() {
    print_step "Instalando fuentes..."
    
    # Hack Nerd Font
    cd /usr/share/fonts/nerd-fonts
    sudo curl -LO https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Hack.zip
    sudo unzip -q Hack.zip
    sudo rm Hack.zip
    
    # Fuentes de Polybar
    if [ -d "$USER_HOME/ConfigFiles/polybar/fonts" ]; then
        sudo cp "$USER_HOME/ConfigFiles/polybar/fonts"/* /usr/share/fonts/polybar/
    fi
    
    # Actualizar cache de fuentes
    fc-cache -fv > /dev/null 2>&1
    
    print_info "Fuentes instaladas\n"
    sleep 1
}

# Copiar configuraciones
function copy_configurations() {
    print_step "Copiando archivos de configuración..."
    
    # Copiar configs si existen
    [ -d "$USER_HOME/ConfigFiles/bin" ] && cp -r "$USER_HOME/ConfigFiles/bin" "$USER_HOME/.config/"
    [ -f "$USER_HOME/ConfigFiles/zshrc/zshrc" ] && cp "$USER_HOME/ConfigFiles/zshrc/zshrc" "$USER_HOME/.zshrc"
    [ -f "$USER_HOME/ConfigFiles/p10k/p10k.zsh" ] && cp "$USER_HOME/ConfigFiles/p10k/p10k.zsh" "$USER_HOME/.p10k.zsh"
    [ -d "$USER_HOME/ConfigFiles/polybar" ] && cp -r "$USER_HOME/ConfigFiles/polybar"/* "$USER_HOME/.config/polybar/"
    [ -d "$USER_HOME/ConfigFiles/nvim" ] && cp -r "$USER_HOME/ConfigFiles/nvim"/* "$USER_HOME/.config/nvim/"
    [ -d "$USER_HOME/ConfigFiles/sxhkd" ] && cp -r "$USER_HOME/ConfigFiles/sxhkd"/* "$USER_HOME/.config/sxhkd/"
    [ -d "$USER_HOME/ConfigFiles/bspwm" ] && cp -r "$USER_HOME/ConfigFiles/bspwm"/* "$USER_HOME/.config/bspwm/"
    [ -d "$USER_HOME/ConfigFiles/kitty" ] && cp -r "$USER_HOME/ConfigFiles/kitty"/* "$USER_HOME/.config/kitty/"
    [ -d "$USER_HOME/ConfigFiles/dunst" ] && cp -r "$USER_HOME/ConfigFiles/dunst"/* "$USER_HOME/.config/dunst/"
    [ -d "$USER_HOME/ConfigFiles/picom" ] && cp -r "$USER_HOME/ConfigFiles/picom"/* "$USER_HOME/.config/picom/"
    [ -d "$USER_HOME/ConfigFiles/rofi" ] && cp -r "$USER_HOME/ConfigFiles/rofi"/* "$USER_HOME/.config/rofi/"
    
    # Copiar módulos de ZSH
    if [ -d "$USER_HOME/ConfigFiles/zsh_modul" ]; then
        sudo cp -r "$USER_HOME/ConfigFiles/zsh_modul"/zsh-* /usr/share/
    fi
    
    # Copiar powerlevel10k
    if [ -d "$USER_HOME/ConfigFiles/powerlevel10k" ]; then
        cp -r "$USER_HOME/ConfigFiles/powerlevel10k" "$USER_HOME/"
    fi
    
    print_info "Configuraciones copiadas\n"
    sleep 1
}

# Configurar archivos
function configure_files() {
    print_step "Configurando archivos..."
    
    # Corregir .zshrc
    if [ -f "$USER_HOME/.zshrc" ]; then
        sed -i "s/alias cat='batcat'/alias cat='bat'/" "$USER_HOME/.zshrc"
        sed -i "s/zeus/$CURRENT_USER/g" "$USER_HOME/.zshrc"
    fi
    
    # Configurar fondo de pantalla en LightDM
    if [ "$DM" = "lightdm" ]; then
        sudo sed -i "s|^#background=.*|background=$USER_HOME/WallPapers/Wall_OnePiece.png|" \
            /etc/lightdm/lightdm-gtk-greeter.conf 2>/dev/null || true
    fi
    
    # Crear .xinitrc
    cat > "$USER_HOME/.xinitrc" << 'EOF'
#!/bin/sh

# Configuración de teclado español
setxkbmap es &

# Compositor
picom &

# Fondo de pantalla
nitrogen --restore &

# Polybar
~/.config/polybar/launch.sh &

# Notificaciones
dunst &

# BSPWM
exec bspwm
EOF
    chmod +x "$USER_HOME/.xinitrc"
    
    # Crear sesión BSPWM para el display manager
    sudo tee /usr/share/xsessions/bspwm.desktop > /dev/null << EOF
[Desktop Entry]
Name=BSPWM
Comment=Binary Space Partitioning Window Manager
Exec=$USER_HOME/.xinitrc
Type=Application
EOF
    
    print_info "Archivos configurados\n"
    sleep 1
}

# Configurar permisos
function set_permissions() {
    print_step "Configurando permisos de ejecución..."
    
    find "$USER_HOME/.config/bspwm" -type f -exec chmod +x {} \; 2>/dev/null
    find "$USER_HOME/.config/polybar" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null
    find "$USER_HOME/.config/bin" -type f -exec chmod +x {} \; 2>/dev/null
    [ -d "$USER_HOME/.local/bin" ] && chmod +x "$USER_HOME/.local/bin"/* 2>/dev/null
    
    # Link simbólico para powermenu
    if [ -f "$USER_HOME/.config/bspwm/scripts/power.sh" ]; then
        ln -sf "$USER_HOME/.config/bspwm/scripts/power.sh" "$USER_HOME/.config/polybar/scripts/powermenu"
        ln -sf "$USER_HOME/.config/bspwm/scripts/power.sh" "$USER_HOME/.config/polybar/scripts/powermenu_alt"
    fi
    
    print_info "Permisos configurados\n"
    sleep 1
}

# Configurar ZSH
function configure_zsh() {
    print_step "Configurando ZSH como shell predeterminada..."
    
    # Cambiar shell
    sudo chsh -s "$(which zsh)" "$CURRENT_USER"
    sudo chsh -s "$(which zsh)" root
    
    # Configurar para root
    sudo mkdir -p /root/.config/nvim
    sudo mkdir -p /root/powerlevel10k
    
    # Links simbólicos para root
    [ -f "$USER_HOME/.zshrc" ] && sudo ln -sf "$USER_HOME/.zshrc" /root/.zshrc
    [ -f "$USER_HOME/.p10k.zsh" ] && sudo ln -sf "$USER_HOME/.p10k.zsh" /root/.p10k.zsh
    
    # Copiar configs de nvim para root
    [ -d "$USER_HOME/.config/nvim" ] && sudo cp -r "$USER_HOME/.config/nvim"/* /root/.config/nvim/
    [ -d "$USER_HOME/powerlevel10k" ] && sudo cp -r "$USER_HOME/powerlevel10k"/* /root/powerlevel10k/
    
    print_info "ZSH configurado\n"
    sleep 1
}

# Configurar teclado español
function configure_keyboard() {
    print_step "Configurando teclado español..."
    
    sudo localectl set-x11-keymap es
    
    print_info "Teclado configurado a español\n"
    sleep 1
}

# Limpiar archivos temporales
function cleanup() {
    print_step "Limpiando archivos temporales..."
    
    # Limpiar fuentes
    sudo rm -rf /usr/share/fonts/nerd-fonts/*.md 2>/dev/null
    
    # Limpiar ConfigFiles
    rm -rf "$USER_HOME/ConfigFiles"
    
    # Limpiar cache de pacman
    sudo pacman -Scc --noconfirm
    paru -Scc --noconfirm
    
    # Actualizar base de datos de archivos
    sudo updatedb
    
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
    
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  Próximos pasos:                                                     ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════════════╝${NC}\n"
    
    echo -e "  ${CYAN}1.${NC} Reinicia el sistema:"
    echo -e "     ${PURPLE}sudo reboot${NC}\n"
    
    echo -e "  ${CYAN}2.${NC} En el login de $DM, selecciona ${GREEN}BSPWM${NC}\n"
    
    echo -e "  ${CYAN}3.${NC} Configura Powerlevel10k (primera vez):"
    echo -e "     ${PURPLE}p10k configure${NC}\n"
    
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  Atajos de teclado principales:                                      ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════════════╝${NC}\n"
    
    echo -e "  ${CYAN}•${NC} Super + Enter         → Abrir terminal (Kitty)"
    echo -e "  ${CYAN}•${NC} Super + D             → Rofi (lanzador de aplicaciones)"
    echo -e "  ${CYAN}•${NC} Super + Shift + Q     → Cerrar ventana activa"
    echo -e "  ${CYAN}•${NC} Super + Shift + R     → Recargar configuración BSPWM"
    echo -e "  ${CYAN}•${NC} Super + Shift + E     → Salir de BSPWM"
    echo -e "  ${CYAN}•${NC} Super + [1-9]         → Cambiar de escritorio"
    echo -e "  ${CYAN}•${NC} Super + Shift + [1-9] → Mover ventana a escritorio"
    echo -e "  ${CYAN}•${NC} Super + F             → Pantalla completa\n"
    
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  Información del sistema:                                            ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════════════╝${NC}\n"
    
    fastfetch 2>/dev/null || neofetch 2>/dev/null || echo "  Sistema: Arch Linux + BSPWM"
    
    echo ""
    print_warning "Presiona Enter para continuar..."
    read
}

# Función principal
function main() {
    show_banner
    
    echo -e "${YELLOW}[!]${NC} Este script instalará BSPWM con todas sus dependencias"
    echo -e "${YELLOW}[!]${NC} Presiona Enter para continuar o Ctrl+C para cancelar\n"
    read
    
    update_system
    select_display_manager
    install_display_manager
    ask_vmware_tools
    install_base_packages
    install_bspwm_components
    install_paru
    install_aur_packages
    create_directories
    download_configurations
    install_fonts
    copy_configurations
    configure_files
    set_permissions
    configure_zsh
    configure_keyboard
    cleanup
    show_summary
}

# Ejecutar
main
