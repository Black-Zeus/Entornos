#!/bin/bash

# Instalación de Apache y PHP
sudo pacman -S --noconfirm --needed apache php php-apache

# Configuración de Apache
sudo systemctl enable httpd
sudo systemctl start httpd

# Instalación de MySQL y PHP-MySQL
sudo pacman -S --noconfirm --needed mysql php-mysql

# Instalación de Composer
sudo pacman -S --noconfirm --needed composer

# Instalación de Laravel
composer global require "laravel/installer"

# Agregar la ruta global de Composer al PATH
echo 'export PATH="$PATH:$HOME/.config/composer/vendor/bin"' >> ~/.bashrc
source ~/.bashrc

# Instalación de Python
sudo pacman -S --noconfirm --needed python

# Instalación de Git
sudo pacman -S --noconfirm --needed git

# Instalación de Postman
yay -S --noconfirm --needed postman-bin

# Instalación de Node.js y npm
sudo pacman -S --noconfirm --needed nodejs npm

# Instalación de Visual Studio Code
sudo pacman -S --noconfirm --needed code

# Instalación de GitKraken
yay -S --noconfirm --needed gitkraken

# Instalación de Insomnia
yay -S --noconfirm --needed insomnia

# Instalación de PhpStorm
yay -S --noconfirm --needed phpstorm

# Instalación de Docker
sudo pacman -S --noconfirm --needed docker docker-compose
sudo systemctl enable docker
sudo systemctl start docker

# Limpieza de caché de paquetes
sudo pacman -Scc --noconfirm
