#!/bin/bash

# Verificar que se está ejecutando como root
if [[ $EUID -ne 0 ]]; then
   echo "Este script debe ser ejecutado como root" 
   exit 1
fi

# Variables de configuración
grub_size=512
swap_size=4.4

# Obtener información del disco
echo "Obteniendo información del disco..."
disk=$(lsblk -dplnx size -o name,size | grep -Ev "boot|rpmb|loop" | tac | tr '\n' ' ' | sed 's/  /\n/g' | head -n 1 | awk '{print $1}')
disk_size=$(lsblk -plnx size -o size "$disk" | sed 's/ //g')
echo "Disco detectado: $disk"
echo "Tamaño del disco: $disk_size"

# Verificar que el disco tenga al menos 10GB
if [ ${disk_size%G} -lt 10 ]; then
   echo "El disco debe tener al menos 10GB"
   exit 1
fi

# Calcular tamaño de partición ext4
ext4_size=$(( ${disk_size%G} - ${grub_size}/1024 - ${swap_size} ))

# Crear particiones
echo "Creando particiones..."
parted -a optimal -s "/dev/$disk" mklabel msdos -- mkpart primary ext4 1MiB ${ext4_size}G mkpart primary linux-swap ${ext4_size}G $(( ${disk_size%G}*1024 ))MiB set 1 boot on

# Formatear particiones
echo "Formateando particiones..."
mkfs.ext4 "/dev/${disk}1"
mkswap "/dev/${disk}2"

# Montar particiones
echo "Montando particiones..."
swapon "/dev/${disk}2"
mount "/dev/${disk}1" /mnt

# Instalar sistema base
echo "Instalando sistema base..."
pacstrap /mnt base linux linux-firmware

# Generar archivo fstab
echo "Generando archivo fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# Copiar script de post-instalación
echo "Copiando script de post-instalación..."
cp post_install.sh /mnt

# Cambiar root al nuevo sistema
echo "Cambiando a nuevo sistema..."
arch-chroot /mnt /bin/bash -c "./post_install.sh"

# Limpiar y desmontar particiones
echo "Desmontando particiones..."
umount -R /mnt
swapoff "/dev/${disk}2"

# Reiniciar
echo "Reiniciando..."
reboot
