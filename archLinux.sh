#!/bin/bash

if [ $(id -u) = 0 ]; then
  echo "Este script no debe ser ejecutado como root"
  exit 1
fi


echo "Instalando paquetes del sistema..."
sudo pacman -Syu
sudo pacman -S --noconfirm base base-devel net-tools open-vm-tools htop btop neofetch

echo "Instalando paquetes de ventanas..."
sudo pacman -S --noconfirmbspwm sxhkd polybar rofi picom kitty feh

echo "Instalando paquetes de aplicaciones..."
sudo pacman -S --noconfirmzsh caja firefox google-chrome remmina remmina-plugin git

echo "Instalando paquetes de compresión..."
sudo pacman -S --noconfirmzip unrar p7zip

echo "Instalando NeoVim y Powerlevel10k..."

# Instalar NeoVim y el plugin Powerlevel10k
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
git clone https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc

echo "Instalando fuentes TrueType de Windows..."

# Instalar fuentes TrueType de Windows
mkdir -p ~/.local/share/fonts/windows
cd ~/.local/share/fonts/windows
curl -LO https://github.com/microsoft/cascadia-code/releases/download/v2103.17/CascadiaCode-2103.17.zip
unzip CascadiaCode-2103.17.zip
fc-cache -f -v

echo "Instalando fuentes Nerd Fonts Hack..."

# Instalar fuentes Nerd Fonts Hack
mkdir -p ~/.local/share/fonts/nerd-fonts
cd ~/.local/share/fonts/nerd-fonts
curl -LO https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Hack.zip
unzip Hack.zip
fc-cache -f -v

echo "Descargando y descomprimiendo el archivo ConfigFile.zip..."

# Descargar y descomprimir ConfigFile.zip
# Verificar si el directorio ~/.config/ existe, y si no, crearlo
if [ ! -d "$HOME/.config/" ]; then
  mkdir -p "$HOME/.config/"
fi

cd ~/.config
curl -LO https://raw.githubusercontent.com/Black-Zeus/Entornos/main/config.zip
unzip ConfigFile.zip

# Aplicar permisos de ejecución a todos los archivos .sh dentro de todos los subdirectorios de ~/.config/
echo "Permisos de ejecución aplicados a todos los archivos .sh dentro de los subdirectorios de ~/.config/"
find "$HOME/.config/" -type f -name "*.sh" -exec chmod +x {} \;

echo "¡Listo! La instalación ha finalizado."
