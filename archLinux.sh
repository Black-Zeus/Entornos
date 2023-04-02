#!/bin/bash

if [ $(id -u) = 0 ]; then
  echo "Este script no debe ser ejecutado como root"
  exit 1
fi

echo "Actualizando e instalando paquetes del sistema..."
sudo pacman -Syu --noconfirm 

echo "Instalando la interfaz gráfica..."
sudo pacman -Sy --needed --noconfirm xorg xorg-server gnome
sudo systemctl enable gdm

echo "Instalando paquetes adicionales..."
sudo pacman -Sy --needed --noconfirm gtkmm open-vm-tools xf86-video-vmware xf86-input-vmmouse
sudo systemctl enable vmtoolsd
sudo pacman -Sy --needed --noconfirm base base-devel net-tools bspwm sxhkd polybar rofi picom kitty feh zsh git zip unrar p7zip unzip bat lsd wget curl firefox caja vi vim neovim htop btop mlocate

echo "Actualizando la base de datos de archivos..."
sudo updatedb

echo "Creando directorios necesarios..."
mkdir -p ~/.config/{bspwm,sxhkd,polybar} ~/{WallPapers,ConfigFiles,GitRepos,Desktop,powerlevel10k}
sudo mkdir -p /usr/share/zsh-autosuggestions/ /usr/share/zsh-sudo/ /usr/share/zsh-syntax-highlighting/ /usr/share/fonts/nerd-fonts

echo "Descargando imagen de fondo de pantalla y archivo de configuración..."
curl -sfL https://raw.githubusercontent.com/Black-Zeus/Entornos/main/Wall_OnePiece.png -o ~/WallPapers/Wall_OnePiece.png
curl -sfL https://raw.githubusercontent.com/Black-Zeus/Entornos/main/config.zip -o ~/ConfigFiles/config.zip

echo "Descomprimiendo archivo de configuración y eliminando archivo zip..."
cd ~/ConfigFiles/
unzip config.zip

### Hasta aca solo son instalacion de paquets


### Aqui comienza la personalizacion 

# Instalar fuentes Nerd Fonts Hack
cd /usr/share/fonts/nerd-fonts
sudo curl -LO https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/Hack.zip
sudo unzip Hack.zip
fc-cache -f -v


echo "Cambiando shell predeterminada..."bspwm
sudo usermod --shell $(which zsh) $USER
#chsh -s $(which zsh)

cp /usr/share/doc/bspwm/examples/bspwmrc ~/.config/bspwm/bspwmrc
cp /usr/share/doc/bspwm/examples/sxhkdrc ~/.config/sxhkd/sxhkdrc

cat <<EOF >> ~/.config/bspwm/bspwmrc
# Configuración de bspwm
# Se establece el ancho del borde de las ventanas en 1 píxel
bspc config border_width 1

# Ejecución de polybar
# Se ejecuta el script de inicio de polybar, que se encuentra en la ruta especificada
/home/zeus/.config/polybar/./launch.sh

# Compositor de ventanas
# Se ejecuta picom, que es un compositor de ventanas que proporciona transparencia
picom &

# Establecimiento del fondo de pantalla
# Se establece el fondo de pantalla con una imagen específica, que se encuentra en la ruta especificada
feh --bg-fill ~/WallPapers/Wall_OnePiece.png &
EOF

sed -i 's|urxvt|'"$(which kitty)"'|g' ~/.config/sxhkd/sxhkdrc
sed -i 's/super + @space/super + d/g' ~/.config/sxhkd/sxhkdrc
sed -i 's/dmenu_run/rofi -show run/g' ~/.config/sxhkd/sxhkdrc
sed -i 's/pgrep -x sxhkd > \/dev\/null || sxhkd &/pkill sxhkd\nsxhkd \&/' ~/.config/bspwm/bspwmrc

echo "Se cargara zsh, ingrese exit para continuar"
#pause
#zsh

echo "Copiando archivos de configuración de polybar y bin..."
cp -r ~/ConfigFiles/bin ~/.config/
cp -r ~/ConfigFiles/zshrc/zshrc ~/.zshrc
cp -r ~/ConfigFiles/p10k/p10k.zsh  ~/.p10k.zsh
cp -r ~/ConfigFiles/polybar ~/.config/
#cp -r ~/ConfigFiles/picom ~/.config/
#cp -r ~/ConfigFiles/rofi ~/.config/
#cp -r ~/ConfigFiles/sxhkd ~/.config/
#cp -r ~/ConfigFiles/bspwm ~/.config/
cp -r ~/ConfigFiles/kitty ~/.config/
cp -r ~/ConfigFiles/nvim ~/.config/

echo "Copiando archivos de powerlevel10k y zsh_modul..."
cp -r ~/ConfigFiles/powerlevel10k ~/
sudo cp -r ~/ConfigFiles/zsh_modul/zsh-* /usr/share/

echo "Actualizando configuración..."
sed -i "s/alias cat='batcat'/alias cat='bat'/" ~/.zshrc
#sed -i "s+/opt/kitty/bin/kitty+$(which kitty)+" ~/.config/sxhkd/sxhkdrc
#sed -i "s+/usr/share/custonTheme/hell_wallpaper.jpg+~/WallPapers/Wall_OnePiece.png+g" ~/.config/bspwm/bspwmrc


echo "Otorgando permisos de ejecución..."
find ~/.config -type f -name "*.sh" -exec chmod +x {} \;


# Eliminar archivos Innecesarios
sudo rm -rf /usr/share/fonts/nerd-fonts/{*.zip,*.md}
rm -rf ~/ConfigFiles/config.zip

localectl set-x11-keymap es

# Terminamos la instalacion
echo "¡Listo! La instalación ha finalizado. reinicie para continuar"
