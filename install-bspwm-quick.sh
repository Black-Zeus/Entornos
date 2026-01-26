#!/bin/bash
# install-bspwm-quick.sh - Instalación rápida sin gvfs

set -e

# Instalar paquetes (sin gvfs)
sudo pacman -S --noconfirm --needed \
    xorg-server xorg-xinit xorg-xrandr xorg-xsetroot xorg-xbacklight \
    bspwm sxhkd polybar rofi picom feh \
    alacritty kitty lightdm lightdm-gtk-greeter \
    firefox pulseaudio pavucontrol \
    thunar thunar-volman \
    nitrogen lxappearance dunst libnotify \
    scrot flameshot ranger \
    ttf-dejavu ttf-liberation noto-fonts \
    ttf-font-awesome ttf-jetbrains-mono \
    brightnessctl playerctl xclip xsel redshift imagemagick \
    materia-gtk-theme adapta-gtk-theme papirus-icon-theme

# Clonar repo
cd ~
[ -d "AutoBspwmKali" ] && rm -rf AutoBspwmKali
git clone https://github.com/Justice-Reaper/AutoBspwmKali.git
cd AutoBspwmKali

# Crear estructura
mkdir -p ~/.config/{bspwm,sxhkd,polybar,picom,rofi,alacritty,dunst,nitrogen}
mkdir -p ~/.local/share/{fonts,backgrounds}

# Copiar configs
[ -d "bspwm" ] && cp -r bspwm/* ~/.config/bspwm/ && chmod +x ~/.config/bspwm/bspwmrc
[ -d "sxhkd" ] && cp -r sxhkd/* ~/.config/sxhkd/ && chmod +x ~/.config/sxhkd/sxhkdrc
[ -d "polybar" ] && cp -r polybar/* ~/.config/polybar/ && find ~/.config/polybar -type f -name "*.sh" -exec chmod +x {} \;
[ -d "picom" ] && cp -r picom/* ~/.config/picom/
[ -d "rofi" ] && cp -r rofi/* ~/.config/rofi/
[ -d "alacritty" ] && cp -r alacritty/* ~/.config/alacritty/
[ -d "dunst" ] && cp -r dunst/* ~/.config/dunst/
[ -d "wallpapers" ] && cp -r wallpapers/* ~/.local/share/backgrounds/
[ -d "fonts" ] && cp -r fonts/* ~/.local/share/fonts/ && fc-cache -fv

# Adaptar
sed -i 's/terminator/alacritty/g' ~/.config/sxhkd/sxhkdrc
sed -i 's/gnome-terminal/alacritty/g' ~/.config/sxhkd/sxhkdrc

# .xinitrc
cat > ~/.xinitrc << 'EOF'
#!/bin/sh
setxkbmap latam &
picom &
nitrogen --restore &
~/.config/polybar/launch.sh &
dunst &
exec bspwm
EOF
chmod +x ~/.xinitrc

# Wallpaper
if [ -n "$(ls -A ~/.local/share/backgrounds 2>/dev/null)" ]; then
    mkdir -p ~/.config/nitrogen
    cat > ~/.config/nitrogen/bg-saved.cfg << EOF
[xin_-1]
file=$(ls ~/.local/share/backgrounds/* | head -1)
mode=5
bgcolor=#000000
EOF
fi

# LightDM
sudo systemctl enable lightdm
sudo tee /usr/share/xsessions/bspwm.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=BSPWM
Comment=Binary Space Partitioning Window Manager
Exec=/home/black/.xinitrc
Type=Application
EOF

echo "✓ Completado. Ejecuta: sudo reboot"
