#!/bin/bash

# Verificar si el script se está ejecutando como root
if [ $(id -u) = 0 ]; then
  echo "Este script no debe ser ejecutado como root"
  exit 1
fi

# Actualizar e instalar paquetes del sistema
sudo pacman -Syu
sudo pacman -S --noconfirm base base-devel net-tools open-vm-tools bspwm sxhkd polybar rofi picom kitty feh zsh git zip unrar p7zip unzip bat lsd wget curl firefox caja vi vim neovim htop btop mlocate

# Actualizar base de datos de archivos
sudo updatedb

# Crear directorios necesarios
mkdir -p ~/.config/{bspwm,sxhkd,polybar} ~/{WallPapers,ConfigFiles}

# Copiar archivos de configuración bspwm y sxhkd
cp /usr/share/doc/bspwm/examples/bspwmrc ~/.config/bspwm/bspwmrc
cp /usr/share/doc/bspwm/examples/sxhkdrc ~/.config/sxhkd/sxhkdrc

# Agregar personalizaciones al archivo de configuración bspwmrc
cat <<EOF >> ~/.config/bspwm/bspwmrc
bspc config border_width 1
/home/zeus/.config/polybar/./launch.sh
picom &
feh --bg-fill ~/WallPapers/Wall_OnePiece.png &
EOF

# Descargar imagen de fondo de pantalla y archivo de configuración
curl -sfL https://raw.githubusercontent.com/Black-Zeus/Entornos/main/Wall_OnePiece.png -o ~/WallPapers/Wall_OnePiece.png
curl -sfL https://raw.githubusercontent.com/Black-Zeus/Entornos/main/config.zip | tar -xz -C ~/ConfigFiles/ && rm ~/ConfigFiles/config.zip

# Descomprimir archivo de configuración y eliminar archivo zip
unzip ~/ConfigFiles/config.zip
rm -Rf ~/ConfigFiles/config.zip
