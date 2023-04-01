#!/bin/bash

# Validar si el teclado está en español
if ! localectl status | grep -q "Layout: es"; then
  echo "Configurando el teclado en español"
  localectl set-x11-keymap es
fi

# Activamos la conexión de red
sudo systemctl enable NetworkManager
sudo systemctl enable wpa_supplicant

sudo systemctl start NetworkManager
sudo systemctl start wpa_supplicant

# Instalación AUR (paquetes adicionales para Arch User Repository)
sudo pacman -Sy --noconfirm curl wget kitty
mkdir ~/GitRepos
mkdir ~/Desktop

cd ~/GitRepos
git clone https://aur.archlinux.org/paru-bin.git
cd paru-bin
makepkg -si

# Instalamos la interfaz Gráfica
sudo pacman -Sy --noconfirm xorg xorg-server gnome
sudo systemctl enable gdm

sudo pacman -Sy --noconfirm gtkmm open-vm-tools xf86-video-vmware xf86-input-vmmouse
sudo systemctl enable vmtoolsd

# Reiniciamos para aplicar los cambios
sudo reboot now
