#!/bin/bash

if [ $(id -u) = 0 ]; then
  echo "Este script no debe ser ejecutado como root"
  exit 1
fi

echo "Instalando paquetes del sistema..."
sudo pacman -Syu
sudo pacman -S --noconfirm base base-devel net-tools open-vm-tools 
sudo pacman -S --noconfirm bspwm sxhkd polybar rofi picom kitty feh 

sudo pacman -S --noconfirm zsh git zip unrar p7zip unzip bat lsd wget curl
sudo pacman -S --noconfirm firefox caja vi vim neovim htop btop


mkdir -p ~/.config/bspwm
mkdir -p ~/.config/sxhkd
mkdir -p ~/.config/polybar

cp /usr/share/doc/bspwm/example/bspwmrc ~/.config/bspwm/bspwmrc
cp /usr/share/doc/bspwm/example/sxhkdrc ~/.config/sxhkd/sxhkdrc


echo "###\n\
# Scrip para lanzar la Polybar al iniciar sesion\n\
/home/zeus/.config/polybar/./launch.sh\n\
picom &\n\
bspc config border_width 1\n\n\
#Parametros personalizados\n\
#Adicion Fondo de Pantalla\n\
feh --bg-fill /usr/share/custonTheme/hell_wallpaper.jpg &" >> ~/.config/bspwm/bspwmrc


sudo mkdir -p /usr/share/custonTheme/ && mkdir -p ~/.config/ && mkdir -p ~/ConfigFiles/

sudo curl https://raw.githubusercontent.com/Black-Zeus/Entornos/main/Wall_OnePiece.png > /usr/share/custonTheme/Wall_OnePiece.png
wget https://raw.githubusercontent.com/Black-Zeus/Entornos/main/config.zip -o ~/ConfigFiles/

unzip ~/ConfigFiles/config.zip
rm -Rf ~/ConfigFiles/config.zip
