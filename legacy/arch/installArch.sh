#!/bin/bash
#
# Arch Linux Auto-Install Script para VMware
# Configuración: 100GB HDD, 8GB RAM, 4 vCPUs, NAT
# Usuario: Black @ GoldFields/Tecnocomp
#
# ADVERTENCIA: Este script BORRARÁ TODO en /dev/sda
# Usar SOLO en VM nueva sin datos importantes
#

set -e  # Salir si hay errores

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables de configuración
DISK="/dev/sda"
HOSTNAME="archlinux-vm"
USERNAME="black"
TIMEZONE="America/Santiago"
KEYMAP="la-latin1"
LOCALE="es_CL.UTF-8"

# Función para imprimir mensajes
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Banner
clear
echo "================================================"
echo "  Arch Linux Auto-Installer para VMware"
echo "  Disk: 100GB | RAM: 8GB | CPU: 4 cores"
echo "================================================"
echo ""
print_warning "Este script BORRARÁ TODO en ${DISK}"
echo ""
read -p "¿Continuar? (yes/NO): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    print_error "Instalación cancelada por el usuario"
    exit 1
fi

# ============================================
# FASE 1: Preparación Inicial
# ============================================
print_info "FASE 1: Preparación inicial..."

# Verificar modo UEFI
if [ ! -d /sys/firmware/efi/efivars ]; then
    print_error "Sistema no arrancado en modo UEFI"
    exit 1
fi

# Configurar teclado
print_info "Configurando teclado latinoamericano..."
loadkeys $KEYMAP

# Sincronizar reloj
print_info "Sincronizando reloj del sistema..."
timedatectl set-ntp true
sleep 2

# Verificar conectividad
print_info "Verificando conectividad a internet..."
if ! ping -c 3 archlinux.org &>/dev/null; then
    print_error "No hay conexión a internet. Verifica la configuración de red."
    exit 1
fi

# ============================================
# FASE 2: Particionado
# ============================================
print_info "FASE 2: Particionando disco ${DISK}..."

# Limpiar disco y crear tabla GPT
print_info "Limpiando disco y creando tabla GPT..."
wipefs -af $DISK
sgdisk -Z $DISK

# Crear particiones
# 512M EFI, 8G Swap, resto Root
print_info "Creando particiones..."
sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI" $DISK
sgdisk -n 2:0:+8G -t 2:8200 -c 2:"SWAP" $DISK
sgdisk -n 3:0:0 -t 3:8300 -c 3:"ROOT" $DISK

# Informar al kernel de los cambios
partprobe $DISK
sleep 2

# Mostrar particiones creadas
print_info "Particiones creadas:"
lsblk $DISK

# ============================================
# FASE 3: Formateo
# ============================================
print_info "FASE 3: Formateando particiones..."

# Formatear EFI
print_info "Formateando ${DISK}1 como FAT32..."
mkfs.fat -F32 ${DISK}1

# Crear y activar swap
print_info "Configurando swap en ${DISK}2..."
mkswap ${DISK}2
swapon ${DISK}2

# Formatear root
print_info "Formateando ${DISK}3 como ext4..."
mkfs.ext4 -F ${DISK}3

# ============================================
# FASE 4: Montaje
# ============================================
print_info "FASE 4: Montando particiones..."

mount ${DISK}3 /mnt
mkdir -p /mnt/boot/efi
mount ${DISK}1 /mnt/boot/efi

print_info "Particiones montadas:"
lsblk $DISK

# ============================================
# FASE 5: Instalación Base
# ============================================
print_info "FASE 5: Instalando sistema base..."

# Actualizar mirrors para Chile
print_info "Configurando mirrors para Chile..."
cat > /etc/pacman.d/mirrorlist << 'EOF'
Server = http://mirror.ufro.cl/archlinux/$repo/os/$arch
Server = https://archlinux.c3sl.ufpr.br/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
EOF

# Instalar paquetes base
print_info "Instalando paquetes base (esto puede tomar varios minutos)..."
pacstrap /mnt base base-devel linux linux-firmware \
    nano vim networkmanager grub efibootmgr \
    openssh sudo git wget curl htop neofetch \
    bash-completion man-db man-pages

# ============================================
# FASE 6: Configuración del Sistema
# ============================================
print_info "FASE 6: Configurando sistema..."

# Generar fstab
print_info "Generando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# Configurar dentro del chroot
print_info "Entrando al nuevo sistema para configuración..."

arch-chroot /mnt /bin/bash <<CHROOT

# Zona horaria
ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
hwclock --systohc

# Localización
echo "es_CL.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=${LOCALE}" > /etc/locale.conf
echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf

# Hostname
echo "${HOSTNAME}" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1    localhost
::1          localhost
127.0.1.1    ${HOSTNAME}.localdomain ${HOSTNAME}
EOF

# Instalar VMware Tools
pacman -S --noconfirm open-vm-tools xf86-video-vmware xf86-input-vmmouse
systemctl enable vmtoolsd.service
systemctl enable vmware-vmblock-fuse.service

# Habilitar servicios
systemctl enable NetworkManager
systemctl enable sshd

# Configurar GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux --recheck
grub-mkconfig -o /boot/grub/grub.cfg

CHROOT

# ============================================
# FASE 7: Usuarios y Contraseñas
# ============================================
print_info "FASE 7: Configurando usuarios..."

echo ""
print_warning "Configura la contraseña para ROOT:"
arch-chroot /mnt passwd

echo ""
print_info "Creando usuario: ${USERNAME}"
arch-chroot /mnt useradd -m -G wheel,storage,power,audio,video -s /bin/bash ${USERNAME}

echo ""
print_warning "Configura la contraseña para ${USERNAME}:"
arch-chroot /mnt passwd ${USERNAME}

# Configurar sudo
print_info "Configurando sudo para grupo wheel..."
arch-chroot /mnt bash -c "echo '%wheel ALL=(ALL:ALL) ALL' >> /etc/sudoers.d/wheel"
arch-chroot /mnt chmod 440 /etc/sudoers.d/wheel

# ============================================
# FASE 8: Post-instalación
# ============================================
print_info "FASE 8: Configuración final..."

# Crear script de post-instalación para el usuario
cat > /mnt/home/${USERNAME}/post-install.sh <<'POSTSCRIPT'
#!/bin/bash
# Script de post-instalación para Black
# Ejecutar después del primer boot

echo "=== Post-Instalación Arch Linux ==="
echo ""

# Actualizar sistema
echo "[1/5] Actualizando sistema..."
sudo pacman -Syu --noconfirm

# Instalar herramientas de desarrollo
echo "[2/5] Instalando herramientas de desarrollo..."
sudo pacman -S --noconfirm \
    docker docker-compose \
    python python-pip \
    nodejs npm \
    go \
    code \
    make cmake gcc gdb

# Habilitar Docker
echo "[3/5] Configurando Docker..."
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# Instalar utilidades adicionales
echo "[4/5] Instalando utilidades..."
sudo pacman -S --noconfirm \
    tmux screen \
    rsync \
    nmap tcpdump wireshark-cli \
    iftop nethogs \
    tree \
    zip unzip p7zip

# AUR Helper (yay)
echo "[5/5] Instalando yay (AUR helper)..."
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd ~

echo ""
echo "=== Post-instalación completada ==="
echo "Ejecuta 'newgrp docker' o cierra sesión para usar Docker sin sudo"
echo ""
echo "Para instalar entorno gráfico:"
echo "  XFCE:  sudo pacman -S xfce4 xfce4-goodies lightdm lightdm-gtk-greeter"
echo "  GNOME: sudo pacman -S gnome gnome-extra gdm"
echo "  KDE:   sudo pacman -S plasma kde-applications sddm"
echo ""
echo "Luego habilita el display manager:"
echo "  sudo systemctl enable lightdm  # para XFCE"
echo "  sudo systemctl enable gdm      # para GNOME"
echo "  sudo systemctl enable sddm     # para KDE"

POSTSCRIPT

chmod +x /mnt/home/${USERNAME}/post-install.sh
arch-chroot /mnt chown ${USERNAME}:${USERNAME} /home/${USERNAME}/post-install.sh

# ============================================
# FINALIZACIÓN
# ============================================
print_info "Desmontando particiones..."
umount -R /mnt

echo ""
echo "================================================"
print_info "¡Instalación completada exitosamente!"
echo "================================================"
echo ""
echo "Próximos pasos:"
echo "  1. Retirar la ISO de la VM"
echo "  2. Reiniciar: reboot"
echo "  3. Login como: ${USERNAME}"
echo "  4. Ejecutar: ./post-install.sh"
echo ""
print_warning "RETIRAR ISO ANTES DE REINICIAR"
echo ""
read -p "¿Reiniciar ahora? (yes/NO): " REBOOT

if [ "$REBOOT" = "yes" ]; then
    print_info "Reiniciando en 5 segundos..."
    sleep 5
    reboot
else
    print_info "Reinicia manualmente cuando estés listo"
    print_warning "No olvides retirar la ISO primero"
fi
