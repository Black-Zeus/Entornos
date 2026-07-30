#!/bin/bash
#
# Instalador de BSPWM para Arch Linux (ya instalado)
# Ejecutar como usuario black (NO como root)
#

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[✓]${NC} $1"; }
print_step() { echo -e "${BLUE}[→]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

# Verificar que NO se ejecute como root
if [ "$EUID" -eq 0 ]; then 
    print_error "NO ejecutes este script como root o con sudo"
    print_info "Ejecuta como: ./install-bspwm.sh"
    exit 1
fi

clear
cat << "EOF"
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║     Instalador BSPWM para Arch Linux                    ║
║     Basado en AutoBspwmKali                             ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
EOF
echo ""

# ============================================
# PASO 1: Instalar paquetes necesarios
# ============================================
print_step "PASO 1: Instalando paquetes de entorno gráfico..."

sudo pacman -Syu --noconfirm

sudo pacman -S --noconfirm \
    xorg-server xorg-xinit xorg-xrandr xorg-xsetroot xorg-xbacklight \
    bspwm sxhkd polybar rofi picom feh \
    alacritty kitty \
    lightdm lightdm-gtk-greeter \
    firefox \
    pulseaudio pavucontrol \
    thunar thunar-volman gvfs \
    nitrogen lxappearance \
    dunst libnotify \
    scrot flameshot \
    ranger \
    ttf-dejavu ttf-liberation noto-fonts \
    ttf-font-awesome ttf-jetbrains-mono ttf-nerd-fonts-symbols \
    brightnessctl \
    playerctl \
    xclip xsel \
    redshift \
    imagemagick \
    materia-gtk-theme adapta-gtk-theme papirus-icon-theme

print_info "Paquetes base instalados"

# Instalar arc-gtk-theme desde AUR con yay
print_step "Instalando temas adicionales desde AUR..."
if command -v yay &> /dev/null; then
    yay -S --noconfirm arc-gtk-theme 2>/dev/null || print_warning "arc-gtk-theme no disponible, usando alternativas"
else
    print_warning "yay no está instalado, saltando arc-gtk-theme"
fi

print_info "Paquetes instalados correctamente"

# ============================================
# PASO 2: Crear estructura de directorios
# ============================================
print_step "PASO 2: Creando estructura de directorios..."

mkdir -p ~/.config/{bspwm,sxhkd,polybar,picom,rofi,alacritty,dunst,nitrogen}
mkdir -p ~/.local/share/{fonts,backgrounds}
mkdir -p ~/Screenshots

print_info "Directorios creados"

# ============================================
# PASO 3: Clonar y configurar AutoBspwmKali
# ============================================
print_step "PASO 3: Clonando configuraciones de AutoBspwmKali..."

cd ~
if [ -d "AutoBspwmKali" ]; then
    rm -rf AutoBspwmKali
fi

git clone https://github.com/Justice-Reaper/AutoBspwmKali.git
cd AutoBspwmKali

print_info "Repositorio clonado"

# ============================================
# PASO 4: Copiar configuraciones
# ============================================
print_step "PASO 4: Copiando configuraciones..."

# BSPWM
if [ -d "bspwm" ]; then
    print_info "Copiando BSPWM config..."
    cp -r bspwm/* ~/.config/bspwm/
    chmod +x ~/.config/bspwm/bspwmrc
    find ~/.config/bspwm/scripts -type f -exec chmod +x {} \; 2>/dev/null || true
fi

# SXHKD
if [ -d "sxhkd" ]; then
    print_info "Copiando SXHKD config..."
    cp -r sxhkd/* ~/.config/sxhkd/
    chmod +x ~/.config/sxhkd/sxhkdrc
fi

# Polybar
if [ -d "polybar" ]; then
    print_info "Copiando Polybar config..."
    cp -r polybar/* ~/.config/polybar/
    find ~/.config/polybar -type f -name "*.sh" -exec chmod +x {} \;
fi

# Picom
if [ -d "picom" ]; then
    print_info "Copiando Picom config..."
    cp -r picom/* ~/.config/picom/ 2>/dev/null || true
fi

# Rofi
if [ -d "rofi" ]; then
    print_info "Copiando Rofi config..."
    cp -r rofi/* ~/.config/rofi/ 2>/dev/null || true
fi

# Alacritty
if [ -d "alacritty" ]; then
    print_info "Copiando Alacritty config..."
    cp -r alacritty/* ~/.config/alacritty/ 2>/dev/null || true
fi

# Dunst
if [ -d "dunst" ]; then
    print_info "Copiando Dunst config..."
    cp -r dunst/* ~/.config/dunst/ 2>/dev/null || true
fi

# Wallpapers
if [ -d "wallpapers" ]; then
    print_info "Copiando fondos de pantalla..."
    cp -r wallpapers/* ~/.local/share/backgrounds/ 2>/dev/null || true
fi

# Fuentes
if [ -d "fonts" ]; then
    print_info "Instalando fuentes..."
    cp -r fonts/* ~/.local/share/fonts/ 2>/dev/null || true
    fc-cache -fv
fi

# ============================================
# PASO 5: Adaptar configuraciones para Arch
# ============================================
print_step "PASO 5: Adaptando configuraciones para Arch Linux..."

# Cambiar terminal por defecto a alacritty
if [ -f ~/.config/sxhkd/sxhkdrc ]; then
    sed -i 's/terminator/alacritty/g' ~/.config/sxhkd/sxhkdrc
    sed -i 's/gnome-terminal/alacritty/g' ~/.config/sxhkd/sxhkdrc
    sed -i 's/xterm/alacritty/g' ~/.config/sxhkd/sxhkdrc
fi

# Ajustar rutas de Kali a Arch
if [ -f ~/.config/bspwm/bspwmrc ]; then
    sed -i 's|/usr/share/kali|/usr/share/arch|g' ~/.config/bspwm/bspwmrc
    sed -i 's|kali|arch|g' ~/.config/bspwm/bspwmrc
fi

# Si no existe Picom config, crear una básica
if [ ! -f ~/.config/picom/picom.conf ]; then
    print_info "Creando configuración básica de Picom..."
    cat > ~/.config/picom/picom.conf << 'PICOM'
# Shadows
shadow = true;
shadow-radius = 12;
shadow-offset-x = -7;
shadow-offset-y = -7;
shadow-opacity = 0.6;

# Fading
fading = true;
fade-delta = 4;
fade-in-step = 0.03;
fade-out-step = 0.03;

# Transparency
inactive-opacity = 0.95;
frame-opacity = 0.9;
active-opacity = 1.0;

# Corners
corner-radius = 8;

# Backend
backend = "glx";
vsync = true;
PICOM
fi

# Crear configuración de Alacritty si no existe
if [ ! -f ~/.config/alacritty/alacritty.yml ]; then
    print_info "Creando configuración de Alacritty..."
    mkdir -p ~/.config/alacritty
    cat > ~/.config/alacritty/alacritty.yml << 'ALACRITTY'
window:
  opacity: 0.95
  padding:
    x: 10
    y: 10

font:
  normal:
    family: JetBrains Mono
    style: Regular
  size: 11

colors:
  primary:
    background: '#1e1e2e'
    foreground: '#cdd6f4'

cursor:
  style:
    shape: Block
    blinking: On
ALACRITTY
fi

# ============================================
# PASO 6: Configurar .xinitrc
# ============================================
print_step "PASO 6: Configurando .xinitrc..."

cat > ~/.xinitrc << 'XINITRC'
#!/bin/sh

# Configuración de teclado
setxkbmap latam &

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
XINITRC

chmod +x ~/.xinitrc

print_info ".xinitrc configurado"

# ============================================
# PASO 7: Configurar Nitrogen (wallpaper)
# ============================================
print_step "PASO 7: Configurando fondo de pantalla..."

if [ -n "$(ls -A ~/.local/share/backgrounds 2>/dev/null)" ]; then
    WALLPAPER=$(ls ~/.local/share/backgrounds/* | head -1)
    mkdir -p ~/.config/nitrogen
    cat > ~/.config/nitrogen/bg-saved.cfg << EOF
[xin_-1]
file=$WALLPAPER
mode=5
bgcolor=#000000
EOF
    print_info "Fondo de pantalla configurado"
else
    print_warning "No se encontraron fondos de pantalla"
fi

# ============================================
# PASO 8: Habilitar LightDM
# ============================================
print_step "PASO 8: Habilitando LightDM..."

sudo systemctl enable lightdm
print_info "LightDM habilitado"

# ============================================
# PASO 9: Crear sesión BSPWM para LightDM
# ============================================
print_step "PASO 9: Creando sesión BSPWM para LightDM..."

sudo tee /usr/share/xsessions/bspwm.desktop > /dev/null << 'SESSION'
[Desktop Entry]
Name=BSPWM
Comment=Binary Space Partitioning Window Manager
Exec=/home/black/.xinitrc
Type=Application
SESSION

print_info "Sesión BSPWM creada"

# ============================================
# PASO 10: Configurar ZSH (opcional)
# ============================================
print_step "PASO 10: Configurando ZSH..."

# Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    print_info "Instalando Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 2>/dev/null || true
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 2>/dev/null || true

# Configurar plugins en .zshrc
if [ -f ~/.zshrc ]; then
    if ! grep -q "zsh-autosuggestions" ~/.zshrc; then
        sed -i 's/plugins=(git)/plugins=(git docker python zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc
    fi
    
    # Agregar aliases
    cat >> ~/.zshrc << 'ZSHRC'

# Custom Aliases
alias ll='exa -lah --icons 2>/dev/null || ls -lah'
alias cat='bat 2>/dev/null || cat'
alias vim='nvim 2>/dev/null || vim'

ZSHRC
fi

# ============================================
# FINALIZACIÓN
# ============================================
echo ""
cat << "EOF"
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║     ✓ BSPWM instalado correctamente                     ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
EOF
echo ""
print_info "Instalación completada exitosamente"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_step "Próximos pasos:"
echo ""
echo "  1. Reinicia el sistema:"
echo "     sudo reboot"
echo ""
echo "  2. En LightDM, selecciona 'BSPWM' antes de iniciar sesión"
echo ""
echo "  3. Atajos de teclado principales:"
echo "     • Super + Enter       → Terminal"
echo "     • Super + D           → Rofi (lanzador)"
echo "     • Super + Shift + Q   → Cerrar ventana"
echo "     • Super + Shift + R   → Recargar BSPWM"
echo "     • Super + [1-9]       → Cambiar escritorio"
echo "     • Super + Shift + E   → Salir de BSPWM"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cd ~
print_info "Limpiando archivos temporales..."

print_warning "Presiona Enter para continuar..."
read
