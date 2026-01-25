#!/bin/bash
#
# Arch Linux Auto-Install Script para VMware (BIOS/Legacy Mode)
# Configuración: 100GB HDD, 8GB RAM, 4 vCPUs, NAT
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

DISK="/dev/sda"
HOSTNAME="archlinux-vm"
USERNAME="black"
TIMEZONE="America/Santiago"
KEYMAP="la-latin1"
LOCALE="es_CL.UTF-8"

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

clear
echo "================================================"
echo "  Arch Linux Auto-Installer (BIOS/Legacy)"
echo "  Disk: 100GB | RAM: 8GB | CPU: 4 cores"
echo "================================================"
echo ""
print_warning "Este script BORRARÁ TODO en ${DISK}"
echo ""
read -p "¿Continuar? (yes/NO): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    print_error "Instalación cancelada"
    exit 1
fi

print_info "FASE 1: Preparación inicial..."
loadkeys $KEYMAP
timedatectl set-ntp true
sleep 2

if ! ping -c 3 archlinux.org &>/dev/null; then
    print_error "No hay conexión a internet"
    exit 1
fi

print_info "FASE 2: Particionando disco ${DISK} (MBR/DOS)..."
wipefs -af $DISK
dd if=/dev/zero of=$DISK bs=512 count=1

# Crear tabla MBR
parted -s $DISK mklabel msdos

# Crear particiones
print_info "Creando particiones..."
parted -s $DISK mkpart primary linux-swap 1MiB 8GiB
parted -s $DISK mkpart primary ext4 8GiB 100%
parted -s $DISK set 2 boot on

partprobe $DISK
sleep 3

print_info "Particiones creadas:"
lsblk $DISK

print_info "FASE 3: Formateando particiones..."
mkswap ${DISK}1
swapon ${DISK}1
mkfs.ext4 -F ${DISK}2

print_info "FASE 4: Montando particiones..."
mount ${DISK}2 /mnt

print_info "Verificando montaje:"
df -h | grep /mnt

print_info "FASE 5: Instalando sistema base..."

# Mirrors para Chile
cat > /etc/pacman.d/mirrorlist << 'EOF'
Server = http://mirror.ufro.cl/archlinux/$repo/os/$arch
Server = https://archlinux.c3sl.ufpr.br/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
EOF

print_info "Instalando paquetes base (esto tomará varios minutos)..."
pacstrap -K /mnt base base-devel linux linux-firmware \
    nano vim networkmanager grub \
    openssh sudo git wget curl htop fastfetch \
    bash-completion man-db man-pages \
    inetutils iputils

if [ $? -ne 0 ]; then
    print_error "Error en la instalación de paquetes base"
    exit 1
fi

print_info "FASE 6: Configurando sistema..."
genfstab -U /mnt >> /mnt/etc/fstab

print_info "Verificando fstab:"
cat /mnt/etc/fstab

arch-chroot /mnt /bin/bash <<'CHROOT'
# Zona horaria
ln -sf /usr/share/zoneinfo/America/Santiago /etc/localtime
hwclock --systohc

# Localización
echo "es_CL.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=es_CL.UTF-8" > /etc/locale.conf
echo "KEYMAP=la-latin1" > /etc/vconsole.conf

# Hostname
echo "archlinux-vm" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1    localhost
::1          localhost
127.0.1.1    archlinux-vm.localdomain archlinux-vm
EOF

# VMware Tools
pacman -S --noconfirm open-vm-tools xf86-video-vmware xf86-input-vmmouse
systemctl enable vmtoolsd.service
systemctl enable vmware-vmblock-fuse.service

# Servicios de red
systemctl enable NetworkManager
systemctl enable sshd

# GRUB para BIOS/Legacy
grub-install --target=i386-pc --recheck /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# Verificar instalación GRUB
if [ ! -f /boot/grub/grub.cfg ]; then
    echo "ERROR: GRUB no se instaló correctamente"
    exit 1
fi

CHROOT

if [ $? -ne 0 ]; then
    print_error "Error en la configuración del sistema"
    exit 1
fi

print_info "FASE 7: Configurando usuarios..."
echo ""
print_warning "Configura la contraseña para ROOT:"
arch-chroot /mnt passwd

echo ""
print_info "Creando usuario: black"
arch-chroot /mnt useradd -m -G wheel,storage,power,audio,video -s /bin/bash black

echo ""
print_warning "Configura la contraseña para black:"
arch-chroot /mnt passwd black

# Configurar sudo
arch-chroot /mnt bash -c "echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/wheel"
arch-chroot /mnt chmod 440 /etc/sudoers.d/wheel

print_info "FASE 8: Creando script de post-instalación..."

cat > /mnt/home/black/post-install.sh <<'POSTSCRIPT'
#!/bin/bash
# Script de post-instalación para Black

echo "================================================"
echo "  Post-Instalación Arch Linux"
echo "================================================"
echo ""

# Actualizar sistema
echo "[1/7] Actualizando sistema..."
sudo pacman -Syu --noconfirm

# Herramientas de desarrollo
echo "[2/7] Instalando herramientas de desarrollo..."
sudo pacman -S --noconfirm \
    docker docker-compose \
    python python-pip \
    nodejs npm \
    go \
    make cmake gcc gdb

# Docker
echo "[3/7] Configurando Docker..."
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# Utilidades de red y monitoreo
echo "[4/7] Instalando utilidades de red..."
sudo pacman -S --noconfirm \
    nmap tcpdump \
    iftop nethogs \
    bind-tools \
    traceroute

# Utilidades generales
echo "[5/7] Instalando utilidades generales..."
sudo pacman -S --noconfirm \
    tmux screen \
    rsync \
    tree \
    zip unzip p7zip \
    lsof \
    strace

# AUR Helper (yay)
echo "[6/7] Instalando yay (AUR helper)..."
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd ~

# Instalar neofetch desde AUR
echo "[7/7] Instalando neofetch desde AUR..."
yay -S --noconfirm neofetch

echo ""
echo "================================================"
echo "  Post-instalación completada"
echo "================================================"
echo ""
echo "NOTAS:"
echo "  • Ejecuta 'newgrp docker' o cierra sesión para usar Docker sin sudo"
echo "  • fastfetch está instalado (alternativa a neofetch)"
echo "  • neofetch está disponible vía AUR"
echo ""
echo "Para instalar entorno gráfico:"
echo "  XFCE:  sudo pacman -S xfce4 xfce4-goodies lightdm lightdm-gtk-greeter"
echo "         sudo systemctl enable lightdm"
echo ""
echo "  GNOME: sudo pacman -S gnome gnome-extra gdm"
echo "         sudo systemctl enable gdm"
echo ""
echo "  KDE:   sudo pacman -S plasma kde-applications sddm"
echo "         sudo systemctl enable sddm"
echo ""
echo "  i3wm:  sudo pacman -S xorg xorg-xinit i3-wm i3status dmenu"
echo "         echo 'exec i3' > ~/.xinitrc"
echo ""

POSTSCRIPT

chmod +x /mnt/home/black/post-install.sh
arch-chroot /mnt chown black:black /home/black/post-install.sh

# Crear script de verificación
cat > /mnt/home/black/verify-system.sh <<'VERIFY'
#!/bin/bash
echo "=== Verificación del Sistema ==="
echo ""
echo "Sistema Operativo:"
cat /etc/os-release | grep PRETTY_NAME
echo ""
echo "Kernel:"
uname -r
echo ""
echo "Uso de Disco:"
df -h /
echo ""
echo "Memoria:"
free -h
echo ""
echo "CPU:"
lscpu | grep "Model name"
echo ""
echo "Red:"
ip -br addr
echo ""
echo "Servicios activos:"
systemctl list-units --type=service --state=running | grep -E 'NetworkManager|sshd|vmtoolsd'
VERIFY

chmod +x /mnt/home/black/verify-system.sh
arch-chroot /mnt chown black:black /home/black/verify-system.sh

print_info "Desmontando particiones..."
swapoff ${DISK}1
umount -R /mnt

echo ""
echo "================================================"
print_info "¡Instalación completada exitosamente!"
echo "================================================"
echo ""
echo "Próximos pasos:"
echo "  1. Retirar la ISO de la VM en VMware"
echo "  2. Reiniciar: reboot"
echo "  3. Login como: black"
echo "  4. Verificar sistema: ./verify-system.sh"
echo "  5. Post-instalación: ./post-install.sh"
echo ""
print_warning "¡IMPORTANTE! RETIRAR ISO ANTES DE REINICIAR"
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
