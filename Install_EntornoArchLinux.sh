#!/bin/bash

if [ $(id -u) = 0 ]; then
  echo "Este script no debe ser ejecutado como root"
  exit 1
fi

echo "Actualizando e instalando paquetes del sistema..."
sudo pacman -Syu --noconfirm 


# Preguntar al usuario qué entorno de escritorio desea instalar
echo "¿Qué entorno de escritorio deseas instalar?"
echo "1) lightdm"
echo "2) gdm"
read -r choice

# Validar la opción ingresada
while true; do
  read -p "¿Qué entorno de escritorio deseas instalar? (1 para Xfce, 2 para GNOME)" choice
  if [[ "$choice" == "1" || "$choice" == "2" ]]; then
    break
  else
    echo "Opción inválida. Por favor, ingresa 1 para instalar Xfce o 2 para instalar GNOME."
  fi
done

# Instalar el entorno de escritorio correspondiente según la opción del usuario
sudo pacman -Sy --needed --noconfirm xorg xorg-server 
if [ "$choice" = "1" ]; then
  echo #Instalar Xfce y Thunar con algunos plugins útiles#
  sudo pacman -Sy --needed --noconfirm lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings

  # Habilitar el servicio de LightDM, que es el gestor de sesiones de Xfce
  sudo systemctl enable lightdm.service
elif [ "$choice" = "2" ]; then
  # Instalar GNOME y GDM
  sudo pacman -Sy --needed --noconfirm gdm gtkmm
  
  # Habilitar el servicio de GDM, que es el gestor de sesiones de GNOME
  sudo systemctl enable gdm
fi


# Preguntar al usuario si desea instalar las herramientas de integración
echo "¿Deseas instalar las herramientas de integración de VMware?"
echo "S) Sí"
echo "N) No"
read -r choice

# Validar la opción ingresada
while true; do
  read -p "¿Desea instalar las herramientas de integración? (S/N)" choice
  if [[ "$choice" == "S" || "$choice" == "s" || "$choice" == "N" || "$choice" == "n" ]]; then
    break
  else
    echo "Opción inválida. Por favor, ingresa S para instalar las herramientas de integración o N para omitir esta opción."
  fi
done


# Instalar las herramientas de integración si el usuario lo desea
if [ "$choice" = "S" || "$choice" = "s" ]; then
  echo "Paquetes para virtualización"
	sudo pacman -Sy --needed --noconfirm open-vm-tools xf86-video-vmware xf86-input-vmmouse

	echo "Habilitando servicio de vmtoolsd..."
	sudo systemctl enable vmtoolsd
fi

echo "Instalando paquetes base..."
sudo pacman -Sy --needed --noconfirm base base-devel

echo "Instalando herramientas de red..."
sudo pacman -Sy --needed --noconfirm net-tools networkmanager wireless_tools
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager

echo "Instalando gestores de ventanas y escritorios..."
sudo pacman -Sy --needed --noconfirm bspwm sxhkd polybar rofi

# Preguntar al usuario si desea instalar picom
echo "¿Deseas instalar Picom?"
echo "S) Sí"
echo "N) No"
read -r choice_picom

# Validar la opción ingresada
while [[ "$choice_picom" != "S" && "$choice_picom" != "N" && "$choice_picom" != "s" && "$choice_picom" != "n" ]]; do
  echo "Opción inválida. Por favor, ingresa S para instalar Picom o N para omitir esta opción."
  read -r choice_picom
done

# Instalar picom si el usuario lo desea
if [ "$choice_picom" = "S" || "$choice_picom" = "s" ]; then
  sudo pacman -Sy --needed --noconfirm picom
fi

echo "Instalando terminales..."
sudo pacman -Sy --needed --noconfirm kitty zsh

echo "Instalando herramientas de compresión y descompresión..."
sudo pacman -Sy --needed --noconfirm unrar zip unzip bzip2 lzip p7zip gzip

echo "Instalando herramientas de visualización de archivos..."
sudo pacman -Sy --needed --noconfirm bat lsd feh

echo "Instalando editores de texto..."
sudo pacman -Sy --needed --noconfirm vi vim neovim

echo "Instalando herramientas de descarga..."
sudo pacman -Sy --needed --noconfirm wget curl git

echo "Instalando navegador web..."
sudo pacman -Sy --needed --noconfirm firefox

echo "Instalando herramientas de monitoreo del sistema..."
sudo pacman -Sy --needed --noconfirm htop btop mlocate

echo "Instalando herramientas de Audio"
sudo pacman -S --needed --noconfirm pulseaudio pulseaudio-bluetooth pulseaudio-alsa alsa-utils pamixer 

echo "Instalando herramientas de Brillo"
sudo pacman -S --needed --noconfirm brightnessctl 

echo "Instalando herramientas de Notificaciones"
sudo pacman -S --needed --noconfirm dunst 

echo "Instalando herramientas de Como gestor de aerchivo, cambiar caja por thunair"
sudo pacman -S --needed --noconfirm  thunar thunar-volman thunar-archive-plugin thunar-shares-plugin thunar-media-tags-plugin thunar-vcs-plugin gvfs xfce4-power-manager-settings file-roller 

#echo "Instalando herramientas de Bloqueo de pantalla"
#sudo pacman -S --needed --noconfirm betterlockscreen xautolock

echo "Instalando herramientas de Clipboard avanzado"
sudo pacman -S --needed --noconfirm xclip

echo "Instalando herramientas de Varias"
sudo pacman -S --needed --noconfirm cmatrix pinta acpi  neofetch

echo "Instalacion de paru Package AUR (Arch User Repository) "
cd /tmp
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si

echo "Actualizando la base de datos de archivos..."
sudo updatedb

echo "Creando directorios necesarios..."

# Directorios en el directorio personal
config_dirs=(polybar rofi nvim sxhkd bspwm kitty dunst picom bin betterlockscreen)
personal_dirs=(WallPapers ConfigFiles powerlevel10k)
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

cd /tmp
git clone https://gist.github.com/85942af486eb79118467.git Wallpapers
cp Wallpapers/* ~/WallPapers/


echo "Cambiando shell predeterminada..."
sudo usermod --shell $(which zsh) $USER
sudo usermod --shell $(which zsh) root

echo "Copiando archivos de configuración de polybar y bin..."
cp -r ~/ConfigFiles/bin ~/.config/
cp -r ~/ConfigFiles/zshrc/zshrc ~/.zshrc
cp -r ~/ConfigFiles/p10k/p10k.zsh  ~/.p10k.zsh
cp -r ~/ConfigFiles/polybar/* ~/.config/polybar
cp -r ~/ConfigFiles/nvim/* ~/.config/nvim
cp -r ~/ConfigFiles/sxhkd/* ~/.config/sxhkd
cp -r ~/ConfigFiles/bspwm/* ~/.config/bspwm
cp -r ~/ConfigFiles/kitty/* ~/.config/kitty
cp -r ~/ConfigFiles/dunst/* ~/.config/dunst
cp -r ~/ConfigFiles/picom/* ~/.config/picom

# Instalar Rofi si el usuario lo desea
if [ "$choice_rofi" = "S" ]; then
  cp -r ~/ConfigFiles/rofi/* ~/.config/rofi
fi


echo "Copiando archivos de powerlevel10k y zsh_modulos"
cp -r ~/ConfigFiles/powerlevel10k ~/
sudo cp -r ~/ConfigFiles/zsh_modul/zsh-* /usr/share/

echo "Corrigiendo ~/.zshrc"
sed -i "s/alias cat='batcat'/alias cat='bat'/" ~/.zshrc

#echo -e "\n###\n#Aconfiguracion para WallPapers en Pantalla de Bloqueo\nbetterlockscreen -u ~/Wallpapers" >> ~/.config/sxhkd/sxhkdrc


echo "Copia archivos a Root"
sudo mkdir -p /root/.config/nvim
sudo mkdir -p /root/powerlevel10k

#sudo cp -R ~/.config /root/.config

sudo ln -s ~/.zshrc /root/.zshrc
sudo ln -s ~/.p10k.zsh  /root/.p10k.zsh
sudo cp -r ~/ConfigFiles/nvim/* /root/.config/nvim
sudo cp -r ~/powerlevel10k/* /root/powerlevel10k

echo "Otorgando permisos de ejecución..."
chmod +x ~/.config/bspwm/scripts/*
chmod +x ~/.config/bspwm/*
chmod +x ~/.config/polybar/launch.sh
chmod +x ~/.config/polybar/scripts/*
chmod +x ~/.config/bin/*

# Eliminar archivos Innecesarios
sudo rm -rf /usr/share/fonts/nerd-fonts/{*.zip,*.md}
rm -rf ~/ConfigFiles

rm ~/.config/polybar/scripts/powermenu*
ln ~/.config/bspwm/scripts/power.sh ~/.config/polybar/scripts/powermenu
ln ~/.config/bspwm/scripts/power.sh ~/.config/polybar/scripts/powermenu_alt

localectl set-x11-keymap es

# Terminamos la instalacion
echo "¡Listo! La instalación ha finalizado. reinicie para continuar"
