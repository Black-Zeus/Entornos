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

# Este script cambia la terminal por defecto de urxvt a kitty en el archivo sxhkdrc de sxhkd.
# También cambia la combinación de teclas super + @space a super + d y el programa asociado a rofi -show run.

# Primero, reemplazamos 'urxvt' por 'kitty' en el archivo sxhkdrc.
sed -i 's/urxvt/kitty/g' ~/.config/sxhkd/sxhkdrc

# A continuación, reemplazamos 'super + @space' por 'super + d' y 'dmenu_run' por 'rofi -show run'.
sed -i 's/super + @space/super + d/g' ~/.config/sxhkd/sxhkdrc
sed -i 's/dmenu_run/rofi -show run/g' ~/.config/sxhkd/sxhkdrc


# Descargar imagen de fondo de pantalla y archivo de configuración
curl -sfL https://raw.githubusercontent.com/Black-Zeus/Entornos/main/Wall_OnePiece.png -o ~/WallPapers/Wall_OnePiece.png
curl -sfL https://raw.githubusercontent.com/Black-Zeus/Entornos/main/config.zip -o ~/ConfigFiles/config.zip

# Descomprimir archivo de configuración y eliminar archivo zip
cd ~/ConfigFiles/
unzip config.zip
rm -Rf config.zip

cp -r ~/ConfigFiles/polybar/ ~/.config/polybar
cp -r ~/ConfigFiles/bin ~/.config/bin

find ~/.config -type f -name "*.sh" -exec chmod +x {} \;
chsh -s /bin/zsh
