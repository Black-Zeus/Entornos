#!/bin/bash

if [ $(id -u) = 0 ]; then
  echo "Este script no debe ser ejecutado como root"
  exit 1
fi

echo "Actualizando e instalando paquetes del sistema..."
sudo pacman -Syu --noconfirm 

echo "Paquetes de gráficos y servidor X"
sudo pacman -Sy --needed --noconfirm xorg xorg-server

echo "Entorno de escritorio GNOME"
sudo pacman -Sy --needed --noconfirm gnome

echo "Habilitando servicio de GDM..."
sudo systemctl enable gdm

echo "Paquetes de interfaz gráfica"
sudo pacman -Sy --needed --noconfirm gtkmm

echo "Paquetes para virtualización"
sudo pacman -Sy --needed --noconfirm open-vm-tools xf86-video-vmware xf86-input-vmmouse

echo "Habilitando servicio de vmtoolsd..."
sudo systemctl enable vmtoolsd

echo "Instalando paquetes base..."
sudo pacman -Sy --needed --noconfirm base base-devel

echo "Instalando herramientas de red..."
sudo pacman -Sy --needed --noconfirm net-tools

echo "Instalando gestores de ventanas y escritorios..."
sudo pacman -Sy --needed --noconfirm bspwm sxhkd polybar  #picom

echo "Instalando terminales..."
sudo pacman -Sy --needed --noconfirm kitty zsh

echo "Instalando herramientas de compresión y descompresión..."
sudo pacman -Sy --needed --noconfirm zip unrar p7zip unzip

echo "Instalando herramientas de visualización de archivos..."
sudo pacman -Sy --needed --noconfirm bat lsd feh pluma

echo "Instalando gestor de archivos..."
sudo pacman -Sy --needed --noconfirm caja

echo "Instalando editores de texto..."
sudo pacman -Sy --needed --noconfirm vi vim neovim

echo "Instalando herramientas de descarga..."
sudo pacman -Sy --needed --noconfirm wget curl

echo "Instalando navegador web..."
sudo pacman -Sy --needed --noconfirm firefox

echo "Instalando herramientas de monitoreo del sistema..."
sudo pacman -Sy --needed --noconfirm htop btop mlocate

echo "Actualizando la base de datos de archivos..."
sudo updatedb

echo "Creando directorios necesarios..."

# Directorios en el directorio personal
config_dirs=(polybar rofi nvim sxhkd bspwm kitty)
personal_dirs=(WallPapers ConfigFiles GitRepos powerlevel10k)
system_dirs=(zsh-autosuggestions zsh-sudo zsh-syntax-highlighting fonts/nerd-fonts  fonts/polybar)

echo "Creando Directorios de Configuracion"
for dir in "${config_dirs[@]}"; do
    echo "Creando Directorio: ~/.config/$dir"
    mkdir -p ~/.config/"$dir"
done

echo "Creando Directorios Personales"
for dir in "${personal_dirs[@]}"; do
    echo "Creando Directorio: ~/$dir"
    mkdir -p ~/"$dir"
done

echo "Creando Directorios del sistema"
for dir in "${system_dirs[@]}"; do
    echo "Creando Directorio: /usr/share/$dir"
    sudo mkdir -p "/usr/share/$dir"
done

echo "Descargando imagen de fondo de pantalla y archivo de configuración..."
curl -sfL https://raw.githubusercontent.com/Black-Zeus/Entornos/main/Wall_OnePiece.png -o ~/WallPapers/Wall_OnePiece.png
curl -sfL https://raw.githubusercontent.com/Black-Zeus/Entornos/main/config.zip -o ~/ConfigFiles/config.zip

echo "Descomprimiendo archivo de configuración y eliminando archivo zip..."
cd ~/ConfigFiles/
unzip config.zip

echo "Instalando Fuentes"
cd /usr/share/fonts/nerd-fonts
sudo curl -LO https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/Hack.zip
sudo unzip Hack.zip

sudo cp ~/ConfigFiles/polybar/fonts/* /usr/share/fonts/polybar/
fc-cache -f -v

echo "Cambiando shell predeterminada..."
sudo usermod --shell $(which zsh) $USER
sudo usermod --shell $(which zsh) root

echo "Copiando archivos de configuración de polybar y bin..."
cp -r ~/ConfigFiles/bin ~/.config/
cp -r ~/ConfigFiles/zshrc/zshrc ~/.zshrc
cp -r ~/ConfigFiles/p10k/p10k.zsh  ~/.p10k.zsh
cp -r ~/ConfigFiles/polybar/* ~/.config/polybar
cp -r ~/ConfigFiles/rofi/* ~/.config/rofi
cp -r ~/ConfigFiles/nvim/* ~/.config/nvim
cp -r ~/ConfigFiles/sxhkd/* ~/.config/sxhkd
cp -r ~/ConfigFiles/bspwm/* ~/.config/bspwm
cp -r ~/ConfigFiles/kitty/* ~/.config/kitty

echo "Copiando archivos de powerlevel10k y zsh_modulos"
cp -r ~/ConfigFiles/powerlevel10k ~/
sudo cp -r ~/ConfigFiles/zsh_modul/zsh-* /usr/share/

echo "Actualizando configuración..."
echo "Corrigiendo ~/.config/sxhkd/sxhkdrc"
sed -i 's|urxvt|'"$(which kitty)"'|g' ~/.config/sxhkd/sxhkdrc
sed -i "s+/opt/kitty/bin/kitty+$(which kitty)+" ~/.config/sxhkd/sxhkdrc
sed -i 's/super + @space/super + d/g' ~/.config/sxhkd/sxhkdrc
sed -i 's/dmenu_run/rofi -show run/g' ~/.config/sxhkd/sxhkdrc

echo "Corrigiendo ~/.config/bspwm/bspwmrc"
sed -i "s/picom &/#picom &/" ~/.config/bspwm/bspwmrc
#sed -i 's/pgrep -x sxhkd > \/dev\/null || sxhkd &/pkill sxhkd\nsxhkd \&/' ~/.config/bspwm/bspwmrc
sed -i "s+/usr/share/custonTheme/hell_wallpaper.jpg+~/WallPapers/Wall_OnePiece.png+g" ~/.config/bspwm/bspwmrc

echo "Corrigiendo ~/.zshrc"
sed -i "s/alias cat='batcat'/alias cat='bat'/" ~/.zshrc

echo "Copia archivos a Root"
sudo mkdir -p /root/.config/nvim
sudo mkdir -p /root/powerlevel10k

sudo ln -s ~/.zshrc /root/.zshrc
sudo ln -s ~/.p10k.zsh  /root/.p10k.zsh
sudo cp -r ~/ConfigFiles/nvim/* /root/.config/nvim
sudo cp -r ~/powerlevel10k/* /root/powerlevel10k

echo "Otorgando permisos de ejecución..."
find ~/.config -type f -name "*.sh" -exec bash -c 'echo "Modificando permisos de: $1"; chmod +x "$1"' bash {} \;
for archivo in ~/.config/polybar/scripts/*; do echo "Modificando permisos de: $archivo"; chmod +x "$archivo"; done


# Eliminar archivos Innecesarios
sudo rm -rf /usr/share/fonts/nerd-fonts/{*.zip,*.md}
rm -rf ~/ConfigFiles

localectl set-x11-keymap es

# Terminamos la instalacion
echo "¡Listo! La instalación ha finalizado. reinicie para continuar"
