#! /bin/bash

loadkeys de-latin1 # set keyboard layout

ip a #check internet connection (Connection of ethernet is connected directly)

#use iwctl to connect wifi

    #device list #to se devices

    #station wlan0 get-network #to search for wifis

    #station wlan0 connect [WLANNAME] #to connect to wifi

    #exit 

reflector -c Germany -a 6 --sort rate --save /etc/pacman.d/mirrorlist ##get best mirror list

pacman -Syy #sync to sercer

timedatectl set-ntp true #use network time protocoll


lsblk # list all partitons

cfdisk /dev/sda #partiton the drive

    #1. Partion EFI Partion 300M
    #2. Partiton SWAP Partion 8G
    #3. Partiton Linux File System (leftover space)

#USE BTRFS File System

mkfs.fat -F32 /dev/sda1 #use FAT 32 for the EFI Partion

mkswap /dev/sda2 #make swap

swapon /dev/sda3 #enable swap

mkfs.btrfs /dev/sda3 #Use BTRF Filesystem

##Create BTRFS Subvolumes according to snapper wiki
mount /dev/sda3 /mnt

btrfs subvolume create /mnt/@


btrfs subvolume create /mnt/@home

btrfs subvolume create /mnt/@snapshots

btrfs subvolume create /mnt/@var_log

umount /mnt #unmout the mnt directory

## Mount the Subvolumes, all subvolumes need to have the same options (btrfs limitation)

mount -o noatime,compress=lzo,space_cache=v2,subvol=/@ /dev/sda3 /mnt

mkdir -p /mnt/{boot,home,.snapshots,var/log}

mount -o noatime,compress=lzo,space_cache=v2,subvol=/@home /dev/sda3 /mnt/home

mount -o noatime,compress=lzo,space_cache=v2,subvol=/@snapshots /dev/sda3 /mnt/.snapshots

mount -o noatime,compress=lzo,space_cache=v2,subvol=/@var_log /dev/sda3 /mnt/var/log

mount /dev/sda1 /mnt/boot

pacstrap /mnt base linux linux-firmware vim intel-ucode

genfstab -U /mnt/etc/fstab #mount partitions on boot

arch-chroot /mnt 

##Configurations files

ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

hwclock --systohc

vim /etc/locale.gen

locale-gen #generate locales

echo "LANG=en_US-UTF8" > /etc/locale.conf

echo "KEYMAP=de-latin1" > /etc/vconsole.conf

echo "niklasPC" > /etc/hostname

vim /etc/hosts
#Create the follwong conntent there: (without comment)

#    127.0.0.1	localhost
#    ::1		localhost
#    127.0.1.1	niklasPC.localdomain	niklasPC

passwd #set root password


## 
pacamn -S grub efibootmgr networkmanager network-manager-applet dialog wpa_supplicant mtools dosfstools git reflector bluez bluez-utils cups xdg-utils xdg-user-dirs pulseautio pulsaudio-bluethooth ineutils base-devel linux-headers bash-completion

vim /etc/mkinitcpio.conf
#Write btrfs in to Modules like that: 

#MODULES=(btrfs ..)

mkinitcpio -p linux #recreate the kernel with btrfs

##Install Grub

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB #install grub

grub-mkconfig -o /boot/grub/grub.cfg # generate grub config

##Enable systemd services
systemctl enable NetworkManager

systemctl enable bluetooth

systemctl enable cups


##Create a usser

useradd -mG wheel niklas #create user with wheel group (sudo)

passwd niklas #set user password

EDITOR=vim visudo #define privileges of wheel group
#Uncomment the line 
    #%wheel ALL=(ALL) ALL
    #Every Member of the wheel group has root privileges

exit  #arch-chroot

umount -a

reboot

##Enter user credentials

ip a #check internet connection (Connection of ethernet is connected directly)

#use ntmui to connect to wifi

##Install Snapper correctly

#delete snappshots direcory and remount, otherwise snapper config will not work (note we already have the mount poin in our fstab file)

sudo umount /.snapshots

sudo rm -r /.snapshots

sudo snapper -c root create-config /

sudo btrfs subvolume delete /.snapshots

sudo mkdir /.snapshots

sudo mount -a #note we already have the mount poin in our fstab file, so @snapshots is remounted

sudo chmod 750 /.snapshots #snapersnapshots are accasable without root piriviliges

sudo vim /etc/snapper/configs/root

#Add your user to allow users 
    #ALLOW_USERS="niklas"

# limits for timeline cleanup use 5 Hourly and 7 daily otherwise you will have to many snapshots (this is recommende by the arch wiki)
    #TIMELINE_MIN_AGE="1800"
    #TIMELINE_LIMIT_HOURLY="5"
    #TIMELINE_LIMIT_DAILY="7"
    #TIMELINE_LIMIT_WEEKLY="0"
    #TIMELINE_LIMIT_MONTHLY="0"
    #TIMELINE_LIMIT_YEARLY="0"


sudo systemctl enable --now snapper-timeline.timer

sudo systemctl enable --now snapper-cleanup.timer

##Install yay

git clone https://aur.archlinux.org/yay

cd yay

makepkg -si PKGBUILD

yay .S snapper-pac-grub snapper-gui #snapper-pac-grub updates grub entries after snapshots

##Insall gnome

sudo pacman -S mesa nvidia xorg gnome gdm gnome-tweaks

systemctl enable gdm #enable display manager

##Create backup algorithm for efi partiton, becaus it does not use btrfs
sudo mkdir /etc/pacman.d/hooks 

vim /etc/pacman.d/hooks/95-bootbackup.hook #conntent is attached in GitHub

sudo pacman -S rsync

##Pacman cache cleanup 

vim /etc/pacman.d/hooks/clean-pkg-cache.hook #conntent is attached in GitHub

reboot

##Switch gnoem language and keyboard languge after reboot


## Allow other users than root to open snapshots in snapper-gui
sudo chmod a+rx /.snapshots

sudo chown :users 

##Remove file systemcheck in, becuase it could lead to date corruption, it should look like this

    #HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block filesystems)

sudo vim /etc/mkinitcpio.conf

mkinitcpio -p linux #recreate the kernel

##Recover old home partion if available otherwise do the following steps:

    #1. turn the bashrc into .bashrc and move into ~/

    #2. copy the reflector.conf file  into /etc/xdg/reflector/reflector.conf

    #3. copy the starship.toml file into   ~/.config/starship.toml

systemctl enable reflector

##Install some useful packages  
sudo pacman -S --needed <  pkglist.txt  #conntent is attached in GitHub

yay -S --needed < pkglist_aur.txt  #conntent is attached in GitHub

##Install Flatpak

sudo pacman -S flatpak

##Install Flatpack Applications

xargs flatpak install -y < flatpaks.txt



##Install the following  gnome extensions:
    #1.  Appindicator and KStatusNotifierItem Support
    #2.  Arch Linux Updates Indicator
    #3.  Blur my Shell
    #4.  Clipboard Indicator
    #5.  Dash to Dock
    #6.  Frippery Move Clock
    #7.  GPU profile selector (for envycontoll)
    #8.  Quick Settings Tweaker
    #9.  Remove App Menu
    #10. User Themes
    #11. Vitals

## And set a gnome theme Darcular:


#Use Daruclar Theme for gnome terminal
sudo pacman -S dconf

git clone https://github.com/dracula/gnome-terminal.git

cd gnome-terminal

./install.sh

#Use Darcular for gedit

wget https://raw.githubusercontent.com/dracula/gedit/master/dracula.xml

mv dracula.xml $HOME/.local/share/gedit/styles/

#Activate in Gedit's preferences dialog


#Dracula gkt theme
git clone https://github.com/dracula/gtk.git

mv gtk Dracula

cp Dracular  /usr/share/themes/ 

gsettings set org.gnome.desktop.wm.preferences theme "Dracula"
gsettings set org.gnome.desktop.wm.preferences theme "Dracula"


##Dracula icons
git clone https://github.com/m4thewz/dracula-icons.git

mv dracula-icons Dracula

cp Dracula usr/share/icons/

gsettings set org.gnome.desktop.interface icon-theme "Dracula"

##Dracula Mailspring

git clone https://github.com/dracula/mailspring.git

#And set it via Edit > Change Theme...

##Enable GTK Theme for flatpak and use Darcula theme

mkdir ~/.themes
mkdir ~/.icons

cp -r /usr/share/themes/Dracula/ ~/.themes/ ##copy from usr/share to home, so flatpak can acces it (/usr/shrare is blacklisted)
cp -r /usr/share/icons/Dracula/ ~/.icons/

#Inside Flatseal 

    #enable the paths under all application settings
        #1. add path: ~/.themes under other file section
        #2. add path: ~/.icons under other file section
    #add environment variables under all application settings
        #1 add line: ICON_THEME=Dracula
        #2 add line: GTK_THEME=Dracula

#Force GTK theme by setting a envoriment variable

sudo bash -c "echo "GTK_THEME=Dracula" >> /etc/environment"


##Insall plymouth

yay -S plymouth
 
 ##RAdd plymouth to kernel hooks after HOOKS=(base udev...)

    #HOOKS=(base udev plymouth autodetect modconf kms keyboard keymap consolefont block filesystems)

sudo vim /etc/mkinitcpio.conf

mkinitcpio -p linux #recreate the kernel

##Add edit grub config and add

 #GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet splash rd.udev.log_priority=3 vt.global_curser_default=1"


sudo vim /etc/default/grub #hole file is in GitHub

##List plymouth themes

sudo plymouth-set-default-theme -l

##Install arch linux spin thmee

sudo plymouth-set-default-theme -R spinfinity

#Use displaymanager with plymouth option

yay -S gdm-plymouth

systemctl enable gdm

##If necessary edit plymouth config then recreate the kernel, for quick machines use ShowDelay=0 option

 sudo vim /etc/plymouth/plymouthd.conf

mkinitcpio -p linux #recreate the kernel


##Install kvm 
#All neccesary packages should alread be installed (pkglist.txt)
sudo systemctl enable libvirtd.service

sudo systemctl start libvirtd.service

sudo vim /etc/libvirt/libvirtd.conf
#In that file do:

    #Set the UNIX domain socket group ownership to libvirt, (around line 85)
    #unix_sock_group = "libvirt"

    #Set the UNIX socket permissions for the R/W socket (around line 102)
    #unix_sock_rw_perms = "0770"

#Then add your user account to libvirt group.
sudo usermod -a -G libvirt $(whoami)
newgrp libvirt

#Restart libvirt daemon.
sudo systemctl restart libvirtd.service

#Enable defautl netowrk
sudo virsh net-list --all

#Download the conntent of the default.xml from GitHub and do 
sudo virsh net-define --file default.xml

sudo virsh net-start default

#Auto start the network
sudo virsh net-autostart --network default

##Install Winapps
#follow the instruction at to create a vm https://github.com/Fmstrat/winapps/blob/main/docs/KVM.md

git clone https://github.com/Fmstrat/winapps.git

cd winapps

vim  ~/.config/winapps/winapps.conf
#Edit the file like that:
    #RDP_USER="MyWindowsUser"
    #RDP_PASS="MyWindowsPassword"
    #RDP_DOMAIN="MYDOMAIN"
    #RDP_IP="192.168.123.111"
    #RDP_SCALE=100
    #RDP_FLAGS=""
    #MULTIMON="true"
    #DEBUG="true"

#Check install
bin/winapps check

#install apps
./installer.sh

##Preaload
yay -S preaload
systemctl enable preload


##Grub Theme

git clone https://github.com/ChrisTitusTech/Top-5-Bootloader-Themes.git
cd Top-5-Bootloader-Themes
sudo ./install.sh

sudo pamcan -S grub-customizer

sudo vim etc/default/grub

#Do the following:
    #GRUB_THEME="/boot/grub/themes/Vimix/theme.txt"
    #GRUB_GFXMODE=auto
    #Place # marker in front: GRUB_TERMINAL_OUTPUT="console"

grub-mkconfig -o /boot/grub/grub.cfg

##Install envycontroll
yay -S envycontrol.
sudo envycontrol -s integrated

##Install tlp
sudo pacman -S tlp tlp-rdw

systemctl enable tlp

systemctl enable tlp-rdw

#Install thermald

sudo pacman -S thermald

systemctl enable thermald

##Samsung printer and scanner
yay -S samsung-unified-driver-printer 

yay -S samsung-unified-driver-scanner

##Install docker

sudo pacman -S docker

sudo usermod -aG docker $USER

sudo pacman -S docker-compose

##Configure Pacman
sudo vim /etc/pacman.conf #file is in GitHUB

#Uncomment #Color, #ParalellDownloads=5 and add ILoveCandy after Color

##Configure Fish
sudo pacman -S fish
cp config.fish ~/.config/fish/config.fish #file on GitHub


