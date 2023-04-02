#!/bin/bash

if [ $(id -u) = 0 ]; then
  echo "Este script no debe ser ejecutado como root"
  exit 1
fi

echo "Actualizando e instalando paquetes del sistema..."
sudo pacman -Syu --needed --noconfirm 

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
sudo mkdir -p /usr/share/zsh-autosuggestions/ /usr/share/zsh-sudo/ /usr/share/zsh-syntax-highlighting/

echo "Descargando imagen de fondo de pantalla y archivo de configuración..."
curl -sfL https://raw.githubusercontent.com/Black-Zeus/Entornos/main/Wall_OnePiece.png -o ~/WallPapers/Wall_OnePiece.png
curl -sfL https://raw.githubusercontent.com/Black-Zeus/Entornos/main/config.zip -o ~/ConfigFiles/config.zip

echo "Descomprimiendo archivo de configuración y eliminando archivo zip..."
cd ~/ConfigFiles/
unzip config.zip

echo "Copiando archivos de configuración de polybar y bin..."
cp -r ~/ConfigFiles/bin ~/.config/
cp -r ~/ConfigFiles/zshrc/zshrc ~/.zshrc
cp -r ~/ConfigFiles/polybar ~/.config/
cp -r ~/ConfigFiles/bspwm ~/.config/
cp -r ~/ConfigFiles/kitty ~/.config/
cp -r ~/ConfigFiles/nvim ~/.config/
cp -r ~/ConfigFiles/picom ~/.config/
cp -r ~/ConfigFiles/rofi ~/.config/
cp -r ~/ConfigFiles/sxhkd ~/.config/

echo "Copiando archivos de powerlevel10k y zsh_modul..."
cp -r ~/ConfigFiles/powerlevel10k ~/
sudo cp -r ~/ConfigFiles/zsh_modul/zsh-* /usr/share/

echo "Actualizando configuración..."
sed -i "s/alias cat='batcat'/alias cat='bat'/" ~/.zshrc
sed -i "s+/opt/kitty/bin/kitty+$(which kitty)+" ~/.config/sxhkd/sxhkd
sed -i "s+//usr/share/custonTheme/hell_wallpaper.jpg+~/WallPapers/Wall_OnePiece.png+" ~/.config/bspwm/bspwmrc

echo "Otorgando permisos de ejecución..."
find ~/.config -type f -name "*.sh" -exec chmod +x {} \;

echo "Cambiando shell predeterminada..."
chsh -s $(which zsh)

echo "Instalando fuentes Nerd Fonts Hack..."

# Instalar fuentes Nerd Fonts Hack
sudo mkdir -p /usr/share/fonts/nerd-fonts
cd /usr/share/fonts/nerd-fonts
sudo curl -LO https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/Hack.zip
sudo unzip Hack.zip
fc-cache -f -v

# Instalando AUR
cd ~/GitRepos
git clone https://aur.archlinux.org/paru-bin.git
cd paru-bin
makepkg -si

# Eliminar archivos Innecesarios
sudo rm -rf /usr/share/fonts/nerd-fonts/{*.zip,*.md}
rm -rf ~/ConfigFiles/config.zip

# Terminamos la instalacion
echo "¡Listo! La instalación ha finalizado."
