#!/bin/bash

# Actualización del sistema operativo
sudo pacman -Syu --noconfirm

# Instalación de paquetes de Pacman
## Desarrollo
sudo pacman -S --noconfirm --needed base-devel git

## Servidor web
sudo pacman -S --noconfirm --needed apache php php-apache mysql php-mysql

## Desarrollo web
sudo pacman -S --noconfirm --needed composer nodejs npm

## Python
sudo pacman -S --noconfirm --needed python

## Navegadores web
sudo pacman -S --noconfirm --needed firefox google-chrome

## Otras herramientas
sudo pacman -S --noconfirm --needed code dbeaver cherrytree spyder

# Instalación de Paru
cd /tmp
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si --noconfirm
cd ..
rm -rf paru

# Instalación de paquetes con Paru
paru -S --noconfirm --needed postman-bin gitkraken insomnia

# Eliminación de paquetes no requeridos
sudo pacman -Rs --noconfirm gtk2-perl

# Limpieza de caché de paquetes
sudo pacman -Scc --noconfirm

# Habilitación de servicios
sudo systemctl enable httpd
sudo systemctl enable docker

# Inicio de servicios
sudo systemctl start httpd
sudo systemctl start docker

# Agregar la ruta global de Composer al PATH
# Listar todos los archivos terminados en rc en el directorio home del usuario
echo "Seleccione el archivo rc en el que desea agregar la línea:"
select rc_file in ~/.*rc
do
  # Verificar si se seleccionó un archivo válido
  if [[ ! -f $rc_file ]]; then
    echo "Archivo no válido. Intente de nuevo."
    continue
  fi
  
  # Verificar si la línea ya existe en el archivo
  if grep -q 'export PATH="$PATH:$HOME/.config/composer/vendor/bin"' "$rc_file"; then
    echo "La línea ya existe en el archivo seleccionado."
  else
    # Agregar la línea al final del archivo
    echo 'export PATH="$PATH:$HOME/.config/composer/vendor/bin"' >> "$rc_file"
    echo "La línea se agregó con éxito al archivo seleccionado."
    source $rc_file
  fi

  break
done

echo "Configuracion Ambiente de Desarrollo web terminado."

