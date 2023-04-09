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
sudo pacman -Sy --needed --noconfirm bspwm sxhkd polybar rofi picom

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
config_dirs=(bspwm sxhkd polybar)
personal_dirs=(WallPapers ConfigFiles GitRepos Desktop powerlevel10k)
for dir in "${config_dirs[@]}"; do
    echo "Creando Directorio: ~/.config/$dir"
    mkdir -p ~/.config/"$dir"
done
for dir in "${personal_dirs[@]}"; do
    echo "Creando Directorio: ~/$dir"
    mkdir -p ~/"$dir"
done

# Directorios del sistema
system_dirs=(zsh-autosuggestions zsh-sudo zsh-syntax-highlighting fonts/nerd-fonts  fonts/polybar)
for dir in "${system_dirs[@]}"; do
    echo "Creando Directorio: /usr/share/$dir"
    sudo mkdir -p "/usr/share/$dir"
done

echo "Descargando imagen de fondo de pantalla y archivo de configuración..."

curl -sfL https://raw.githubusercontent.com/Black-Zeus/Entornos/main/Wall_OnePiece.png -o ~/WallPapers/Wall_OnePiece.png
curl -sfL https://raw.githubusercontent.com/Black-Zeus/Entornos/main/config.zip -o ~/ConfigFiles/config.zip

echo "Descomprimiendo archivo de configuración y eliminando archivo zip..."
cd ~/ConfigFiles/

echo "Descomprimiendo archivo de configuración y eliminando archivo zip..."
cd ~/ConfigFiles/
unzip config.zip

### Hasta aca solo son instalacion de paquets
### Aqui comienza la personalizacion 
# Instalar fuentes Nerd Fonts Hack
cd /usr/share/fonts/nerd-fonts
sudo curl -LO https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/Hack.zip
sudo unzip Hack.zip

# Copiando Fuentes empleadas en PolyBar
sudo cp ~/ConfigFiles/polybar/fonts/* /usr/share/fonts/polybar/
fc-cache -f -v

echo "Cambiando shell predeterminada..."
sudo usermod --shell $(which zsh) $USER
sudo usermod --shell $(which zsh) root
#chsh -s $(which zsh)

cp /usr/share/doc/bspwm/examples/bspwmrc ~/.config/bspwm/bspwmrc
cp /usr/share/doc/bspwm/examples/sxhkdrc ~/.config/sxhkd/sxhkdrc

#cat <<EOF >> ~/.config/bspwm/bspwmrc
#
### Configuracion Personalizada ###
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
cp -r ~/ConfigFiles/rofi ~/.config/
cp -r ~/ConfigFiles/nvim ~/.config/
#cp -r ~/ConfigFiles/picom ~/.config/
#cp -r ~/ConfigFiles/sxhkd ~/.config/
#cp -r ~/ConfigFiles/bspwm ~/.config/
#cp -r ~/ConfigFiles/kitty ~/.config/

echo "Copiando archivos de powerlevel10k y zsh_modulos"
cp -r ~/ConfigFiles/powerlevel10k ~/
sudo cp -r ~/ConfigFiles/zsh_modul/zsh-* /usr/share/

echo "Actualizando configuración..."
sed -i "s/alias cat='batcat'/alias cat='bat'/" ~/.zshrc
sed -i "s+/opt/kitty/bin/kitty+$(which kitty)+" ~/.config/sxhkd/sxhkdrc
sed -i "s/picom &/#picom &/" ~/.config/sxhkd/sxhkdrc
sed -i "s+/usr/share/custonTheme/hell_wallpaper.jpg+~/WallPapers/Wall_OnePiece.png+g" ~/.config/bspwm/bspwmrc

echo "Copia archivos a Root"
sudo mkdir -p /root/.config/nvim
sudo mkdir -p /root/powerlevel10k

sudo cp -r ~/ConfigFiles/zshrc/zshrc /root/.zshrc
sudo cp -r ~/ConfigFiles/p10k/p10k.zsh  /root/.p10k.zsh
sudo cp -r ~/ConfigFiles/nvim/* /root/.config/nvim
sudo cp -r ~/powerlevel10k/* /root/powerlevel10k

echo "Otorgando permisos de ejecución..."
find ~/.config -type f -name "*.sh" -exec chmod +x {} \;
chmod +x ~/.config/polybar/scripts/*

# Eliminar archivos Innecesarios
sudo rm -rf /usr/share/fonts/nerd-fonts/{*.zip,*.md}
rm -rf ~/ConfigFiles/config.zip

localectl set-x11-keymap es

# Terminamos la instalacion
echo "¡Listo! La instalación ha finalizado. reinicie para continuar"
