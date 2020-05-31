#!/bin/sh

test -z $XDG_CONFIG_HOME && XDG_CONFIG_HOME="$HOME/.config"

! systemctl is-enabled NetworkManager.service > /dev/null && sudo systemctl enable --now NetworkManager.service
systemctl is-enabled NetworkManager-wait-online.service > /dev/null && sudo systemctl disable --now NetworkManager-wait-online.service

nmtui

sudo pacman --needed --noconfirm -Syyuu git

mkdir -p $HOME/repo
if [ ! -d $HOME/repo/archlinux ];then
    git clone https://github.com/HerrMAzik/archlinux.git $HOME/repo/archlinux
    sh -c 'cd $HOME/repo/archlinux; git remote set-url origin git@github.com:HerrMAzik/archlinux.git'
fi

test -z $CONFIGDIR && CONFIGDIR=$HOME/repo/archlinux
sh -c "cd ${CONFIGDIR}; git pull"

cpu=$(cat /proc/cpuinfo | grep 'vendor' | uniq | awk '{ print $3 }')
case "$cpu" in
"GenuineIntel")
    ucode="intel-ucode"
    ;;
"AuthenticAMD")
    ucode="amd-ucode"
    ;;
*)
    ucode=""
    ;;
esac

cat <<EOF | sudo sh
cp -f $CONFIGDIR/etc/pacman.conf /etc/pacman.conf

pacman --needed --noconfirm -Syu unzip zip p7zip pigz pbzip2 xz
pacman --needed --noconfirm -S $ucode dnscrypt-proxy chezmoi systemd-swap man
pacman --needed --noconfirm -S noto-fonts noto-fonts-extra noto-fonts-cjk noto-fonts-emoji
pacman --needed --noconfirm -S ttf-jetbrains-mono ttf-dejavu ttf-opensans
pacman --needed --noconfirm -S xdg-user-dirs plasma-desktop sddm plasma-pa plasma-nm sddm-kcm
pacman --needed --noconfirm -S konsole okular ark powerdevil gwenview dolphin kcalc kolourpaint
pacman --needed --noconfirm -S mpv youtube-dl firefox spectacle flameshot ncdu qbittorrent
pacman --needed --noconfirm -S pass oath-toolkit keepassxc keybase kbfs gnupg
pacman --needed --noconfirm -S mc curl wget htop neovim jq expect
pacman --needed --noconfirm -S exa ripgrep fd bat skim
pacman --needed --noconfirm -S git-crypt gcc gdb cmake go go-tools rustup rust-analyzer

sed -i 's/^[\s\t]*COMPRESSION\s*=\s*"/#COMPRESSION="/g' /etc/mkinitcpio.conf
sed -i 's/^#COMPRESSION="lz4/COMPRESSION="lz4/g' /etc/mkinitcpio.conf

mkdir -p /etc/modprobe.d
cp -f $CONFIGDIR/etc/modprobe.d/blacklist.conf /etc/modprobe.d/blacklist.conf

mkdir -p /etc/dnscrypt-proxy
cp -f $CONFIGDIR/etc/dnscrypt-proxy/dnscrypt-proxy.toml /etc/dnscrypt-proxy/dnscrypt-proxy.toml
cp -f $CONFIGDIR/etc/dnscrypt-proxy/forwarding-rules.txt /etc/dnscrypt-proxy/forwarding-rules.txt

cp -f $CONFIGDIR/etc/NetworkManager/conf.d/dns-servers.conf /etc/NetworkManager/conf.d/dns-servers.conf

sed -i 's/relatime/noatime/' /etc/fstab

mkdir -p /etc/sysctl.d
cp -f $CONFIGDIR/etc/sysctl.d/90-swappiness.conf /etc/sysctl.d/90-swappiness.conf

mkdir -p /etc/systemd/swap.conf.d
cp -f $CONFIGDIR/etc/systemd/swap.conf.d/swap.conf /etc/systemd/swap.conf.d/swap.conf

sed -i 's/.*GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub

systemctl enable dnscrypt-proxy.service fstrim.timer systemd-swap.service sddm.service
mkinitcpio -P
grub-mkconfig -o /boot/grub/grub.cfg
EOF

rm $HOME/system.sh
