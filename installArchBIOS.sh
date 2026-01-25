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
sgdisk -Z $DISK

# Crear tabla MBR en lugar de GPT
parted -s $DISK mklabel msdos

# Crear particiones con parted
# 8G Swap, resto Root (sin partición EFI)
print_info "Creando particiones..."
parted -s $DISK mkpart primary linux-swap 1MiB 8GiB
parted -s $DISK mkpart primary ext4 8GiB 100%
parted -s $DISK set 2 boot on

partprobe $DISK
sleep 2

print_info "Particiones creadas:"
lsblk $DISK

print_info "FASE 3: Formateando particiones..."
mkswap ${DISK}1
swapon ${DISK}1
mkfs.ext4 -F ${DISK}2

print_info "FASE 4: Montando particiones..."
mount ${DISK}2 /mnt

print_info "FASE 5: Instalando sistema base..."
cat > /etc/pacman.d/mirrorlist << 'EOF'
Server = http://mirror.ufro.cl/archlinux/$repo/os/$arch
Server = https://archlinux.c3sl.ufpr.br/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
EOF

print_info "Instalando paquetes base..."
pacstrap /mnt base base-devel linux linux-firmware \
    nano vim networkmanager grub \
    openssh sudo git wget curl htop neofetch \
    bash-completion man-db man-pages

print_info "FASE 6: Configurando sistema..."
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash <<CHROOT
ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
hwclock --systohc

echo "es_CL.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=${LOCALE}" > /etc/locale.conf
echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf

echo "${HOSTNAME}" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1    localhost
::1          localhost
127.0.1.1    ${HOSTNAME}.localdomain ${HOSTNAME}
EOF

pacman -S --noconfirm open-vm-tools xf86-video-vmware xf86-input-vmmouse
systemctl enable vmtoolsd.service
systemctl enable vmware-vmblock-fuse.service
systemctl enable NetworkManager
systemctl enable sshd

# GRUB para BIOS/Legacy
grub-install --target=i386-pc ${DISK}
grub-mkconfig -o /boot/grub/grub.cfg
CHROOT

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

arch-chroot /mnt bash -c "echo '%wheel ALL=(ALL:ALL) ALL' >> /etc/sudoers.d/wheel"
arch-chroot /mnt chmod 440 /etc/sudoers.d/wheel

cat > /mnt/home/${USERNAME}/post-install.sh <<'POSTSCRIPT'
#!/bin/bash
echo "=== Post-Instalación Arch Linux ==="
sudo pacman -Syu --noconfirm

echo "Instalando herramientas de desarrollo..."
sudo pacman -S --noconfirm docker docker-compose python python-pip nodejs npm

sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

sudo pacman -S --noconfirm tmux rsync nmap tree zip unzip

cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd ~

echo "=== Completado ==="
POSTSCRIPT

chmod +x /mnt/home/${USERNAME}/post-install.sh
arch-chroot /mnt chown ${USERNAME}:${USERNAME} /home/${USERNAME}/post-install.sh

print_info "Desmontando particiones..."
umount -R /mnt

echo ""
echo "================================================"
print_info "¡Instalación completada!"
echo "================================================"
echo ""
print_warning "RETIRAR ISO ANTES DE REINICIAR"
echo ""
read -p "¿Reiniciar ahora? (yes/NO): " REBOOT

if [ "$REBOOT" = "yes" ]; then
    reboot
fi
