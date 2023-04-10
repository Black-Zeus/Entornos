# Resumen de scripts para instalación de Arch Linux

## Script 1: install_SistemaBaseArchLinux.sh
Este script se encarga de la instalación del sistema base de Arch Linux. Primero, verifica que el sistema esté conectado a internet y, a continuación, actualiza los repositorios e instala los paquetes necesarios para realizar la instalación. Luego, crea las particiones necesarias en el disco duro y formatea las mismas con el sistema de archivos elegido por el usuario. Por último, instala el bootloader GRUB y reinicia el sistema.

## Script 2: Install_EntornoArchLinux.sh
Este script instala los paquetes necesarios para crear un entorno de escritorio básico en Arch Linux. Incluye la instalación de Xorg, el servidor de gráficos, así como también de un entorno de escritorio como XFCE. También instala otros paquetes útiles como un navegador web, un editor de texto y una herramienta de compresión de archivos.

## Script 3: install_WebDev.sh
Este script se encarga de la instalación de paquetes necesarios para el desarrollo web en Arch Linux. Instala un servidor web (Apache), así como también paquetes de desarrollo web como PHP, Node.js y Composer. Además, instala herramientas para el desarrollo de bases de datos como MySQL y DBeaver. Por último, agrega la ruta global de Composer al PATH y habilita los servicios necesarios.


## Modo de instalacion
# Descarga e instala el script install_SistemaBaseArchLinux.sh
curl -sSfL https://raw.githubusercontent.com/Black-Zeus/Entornos/main/install_SistemaBaseArchLinux.sh | bash -

# Descarga e instala el script Install_EntornoArchLinux.sh
curl -sSfL https://raw.githubusercontent.com/Black-Zeus/Entornos/main/Install_EntornoArchLinux.sh | bash -

# Descarga e instala el script install_WebDev.sh
curl -sSfL https://raw.githubusercontent.com/Black-Zeus/Entornos/main/install_WebDev.sh | bash -

