#!/bin/bash

# Verificar si el script se está ejecutando como root
if [ $(id -u) = 0 ]; then
  echo "Este script no debe ser ejecutado como root"
  exit 1
fi

echo "Actualizando e instalando paquetes del sistema..."
sudo pacman -Syu
sudo pacman -S --noconfirm base base-devel net-tools open-vm-tools bspwm sxhkd polybar rofi picom kitty feh zsh git zip unrar p7zip unzip bat lsd wget curl firefox caja vi vim neovim htop btop mlocate

echo "Actualizando la base de datos de archivos..."
sudo updatedb

echo "Creando directorios necesarios..."
mkdir -p ~/.config/{bspwm,sxhkd,polybar} ~/{WallPapers,ConfigFiles}

echo "Copiando archivos de configuración bspwm y sxhkd..."
cp /usr/share/doc/bspwm/examples/bspwmrc ~/.config/bspwm/bspwmrc
cp /usr/share/doc/bspwm/examples/sxhkdrc ~/.config/sxhkd/sxhkdrc

echo "Agregando personalizaciones al archivo de configuración bspwmrc..."
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

echo "Cambiando la terminal predeterminada de urxvt a kitty..."
sed -i 's/urxvt/kitty/g' ~/.config/sxhkd/sxhkdrc

echo "Cambiando la combinación de teclas y el programa asociado en sxhkdrc..."
sed -i 's/super + @space/super + d/g' ~/.config/sxhkd/sxhkdrc
sed -i 's/dmenu_run/rofi -show run/g' ~/.config/sxhkd/sxhkdrc

echo "Descargando imagen de fondo de pantalla y archivo de configuración..."
curl -sfL https://raw.githubusercontent.com/Black-Zeus/Entorn

echo "Descargar imagen de fondo de pantalla y archivo de configuración"
echo "Se descarga una imagen de fondo de pantalla y un archivo de configuración desde GitHub"
echo "usando el comando curl y se guardan en las carpetas correspondientes en el sistema de archivos"
curl -sfL https://raw.githubusercontent.com/Black-Zeus/Entornos/main/Wall_OnePiece.png -o ~/WallPapers/Wall_OnePiece.png
curl -sfL https://raw.githubusercontent.com/Black-Zeus/Entornos/main/config.zip -o ~/ConfigFiles/config.zip

echo "Descomprimir archivo de configuración y eliminar archivo zip"
echo "Se descomprime el archivo de configuración descargado usando el comando unzip"
echo "y se elimina el archivo zip para ahorrar espacio en el disco."
cd ~/ConfigFiles/
unzip config.zip
rm -Rf config.zip

echo "Copiar archivos de configuración de polybar y bin"
echo "Se copian los archivos de configuración de polybar y bin del archivo descomprimido"
echo "a sus respectivas carpetas en el sistema de archivos."
cp -r ~/ConfigFiles/polybar/* ~/.config/polybar
cp -r ~/ConfigFiles/bin ~/.config/bin

echo "Dar permisos de ejecución a los scripts"
echo "Se otorgan permisos de ejecución a todos los archivos .sh que se encuentran en la carpeta ~/.config"
echo "para que puedan ser ejecutados sin problemas."
find ~/.config -type f -name "*.sh" -exec chmod +x {} ;

echo "Cambiar shell predeterminada a zsh"
echo "Se cambia la shell predeterminada del usuario a zsh usando el comando chsh"
echo "para poder usar todas las características de la shell zsh."
chsh -s /bin/zsh
