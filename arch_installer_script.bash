#!/bin/bash

#### Commands on device before using the script
# passwd
# systemctl start sshd
####


#### How to run the script
# ssh user@device  # First step
#
# ~~Option A~~ # Recomended
# wget https://raw.githubusercontent.com/OriolFilter/LinuxConfigs/master/arch_installer_script
# >> once you have the file downloaded, proceed to modify the variables and read the script (to make sure there isn't nothing dangerous)<<
# bash arch_installer_script
#
# ~~Option B~~ # Not Recomended, Read the script online and use the default variables
# curl https://raw.githubusercontent.com/OriolFilter/LinuxConfigs/master/arch_installer_script | bash
####



#### NOTES ####
# Default passwd 'a', root passwd 'a'
####

##############
#### VARS ####
##############

DRIVE="/dev/nvme0n1"
HOSTNAME="Helltaker"
USER1="justice"
USER2=""
LANG="en_GB.UTF-8"
KEYMAP="en"
TIMEZONE="Europe/Madrid"
EXTERNALDEVICE=false   # true | false
FULLAUTO=true   # true | false
PACKAGELIST="net-tools systemd-resolvconf tree man upower netplan git wget sudo" # packages to install using pacman


if $EXTERNALDEVICE ; then
	REMOVABLE="--removable"
fi

if $FULLAUTO ; then
	NOCONFIRM="--noconfirm"
fi

# umount -all

printf "g
n\n \n \n +512M\n Y\n
n\n \n \n \n Y\n
w\n" | fdisk "$DRIVE"


printf  "Y\n" | mkfs.fat -F32 "${DRIVE}p1"
printf  "Y\n" | mkfs.ext4 "${DRIVE}p2"


pacman -Syy 
pacman -S reflector $NOCONFIRM

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
# reflector -c "ES" -f 12 -l 10 -n 12 --save /etc/pacman.d/mirrorlist # ¿?¿

mount "${DRIVE}p2" /mnt

pacstrap /mnt base linux linux-firmware vim nano zsh $NOCONFIRM

genfstab -U /mnt >> /mnt/etc/fstab


######### CHROOT ########



printf "
timedatectl set-timezone '$TIMEZONE'
locale-gen # uncomment lenguage on /etc/locale.gen
printf LANG='$LANG\n' | tee /etc/locale.conf
export LANG='$LANG'
printf 'KEYMAP=$KEYMAP\n' | tee /etc/vconsole.conf
printf '$HOSTNAME\n' | tee /etc/hostname
printf '127.0.0.1 localhost\n::1 localhost\n127.0.1.1 $HOSTNAME\n' | tee /etc/hosts

pacman -S grub efibootmgr $NOCONFIRM
mkdir /boot/efi
mount '${DRIVE}p1' /boot/efi

grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi $REMOVABLE
grub-mkconfig -o /boot/grub/grub.cfg

printf 'a\na\n' | passwd

# Paquets estandar
pacman -S $PACKAGELIST $NOCONFIRM
# Solucio d'errors
pacman -S sudo base-devel $NOCONFIRM


printf 'Creating user: $USER1\n'
useradd -m '$USER1'

printf '$USER1 ALL=(ALL) ALL' | tee -a /etc/sudoers # Dint tested this

printf 'a\na\n' | passwd '$USER1'

####################
#####INSTALLING#####
#######GNOME########
####################

pacman -S gnome  $NOCONFIRM
# systemctl start gdm.service
systemctl enable gdm.service
systemctl enable NetworkManager.service


####################
#####INSTALLING#####
#########i3#########
####################

pacman -S i3-gaps i3status i3lock xorg-server xorg-xinit compton $NOCONFIRM
" | arch-chroot /mnt

printf "\n\n################################
######INSTALATION COMPLETE######
################################\n"
