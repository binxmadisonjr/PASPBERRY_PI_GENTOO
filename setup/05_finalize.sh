#!/bin/bash
set -e
source ./config.env
source ./setup/shared.sh
load_config
check_root

log_title "Step 5: Final Setup (User, Services, Display)"

# Mount rootfs inside chroot
log_step "Entering chroot..."
mount --bind /dev rootfs/dev
mount --bind /proc rootfs/proc
mount --bind /sys rootfs/sys

chroot rootfs /bin/bash <<EOF

# Sync portage and set profile
emerge --sync
eselect profile set genpi64:default/linux/arm64/23.0/split-usr/desktop/genpi64

# Set package.use
mkdir -p /etc/portage/package.use
cat > /etc/portage/package.use/rpi-64bit-meta <<USEFLAGS
dev-embedded/rpi-64bit-meta apps -weekly-genup
USEFLAGS

# Add required licenses
mkdir -p /etc/portage/package.license
echo "media-fonts/ipamonafont grass-ipafonts" > /etc/portage/package.license/ipamonafont

# Install all packages (binary by default)
emerge --ask -j5 --keep-going rpi-64bit-meta

# Cleanup
etc-update --automode -3

# Set timezone
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
env-update && source /etc/profile

# Add user
useradd $USERNAME
echo "$USERNAME:$ROOT_PASSWORD" | chpasswd
usermod -aG wheel $USERNAME

# Set up sudo
sed -i 's|# %wheel|%wheel|' /etc/sudoers
sed -i 's|ALL=(ALL:ALL) ALL|ALL=(ALL:ALL) NOPASSWD: ALL|' /etc/sudoers

# Disable root login
passwd -l root
sed -i 's|^PermitRootLogin.*|#PermitRootLogin prohibit-password|' /etc/ssh/sshd_config

# Enable system services
rc-update add dbus default
rc-update add NetworkManager default
rc-update add display-manager default
rc-update add sshd default
rc-update add ntpd default

# Set display manager and session
echo 'DISPLAY_MANAGER="lightdm"' > /etc/conf.d/display-manager
echo 'XSESSION="Xfce4"' > /etc/env.d/90xsession
env-update && source /etc/profile

# Clean lightdm wallpaper
sed -i 's|user-background=true|user-background=false|' /etc/lightdm/lightdm-gtk-greeter.conf

# Keyboard and video tweaks for Xorg
mkdir -p /etc/X11/xorg.conf.d

cat > /etc/X11/xorg.conf.d/99-keyboard-layout.conf <<KBD
Section "InputClass"
  Identifier "system-keyboard"
  MatchIsKeyboard "on"
  Option "XkbLayout" "$KEYMAP"
EndSection
KBD

cat > /etc/X11/xorg.conf.d/99-video.conf <<VID
Section "OutputClass"
  Identifier "vc4"
  MatchDriver "vc4"
  Driver "modesetting"
  Option "Accel" "true"
  Option "PrimaryGPU" "true"
EndSection
VID

EOF

# Unmount all
umount -l rootfs/dev
umount -l rootfs/proc
umount -l rootfs/sys
umount bootfs
umount rootfs
rmdir bootfs rootfs

log_success "Install finalized. SD card ready to boot."