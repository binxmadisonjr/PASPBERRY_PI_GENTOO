#!/bin/bash
set -e

source ./config.env
source ./setup/shared.sh
load_config
check_root

log_title "Step 5: Final Setup (User, Services, Display)"

# Ensure mountpoints exist
cd "$BUILD_DIR"
mkdir -p $BUILD_DIR/rootfs/dev $BUILD_DIR/rootfs/proc $BUILD_DIR_rootfs/sys

# Mount virtual filesystems
log_step "Mounting /dev, /proc, /sys to chroot..."
mount --bind /dev "$BUILD_DIR/rootfs/dev"
mount --bind /proc "$BUILD_DIR/rootfs/proc"
mount --bind /sys "$BUILD_DIR/rootfs/sys"

log_step "Entering chroot environment..."

# Export variables to chroot
export USERNAME ROOT_PASSWORD TIMEZONE KEYMAP

# Run commands in chroot
env -i USERNAME="$USERNAME" ROOT_PASSWORD="$ROOT_PASSWORD" TIMEZONE="$TIMEZONE" KEYMAP="$KEYMAP" chroot "$BUILD_DIR/rootfs" /bin/bash <<'EOF'
set -e

export PS1="(RASPBERRY_PI_GENTOO@chroot) # "
# Sync and set profile
emerge --sync
eselect profile set genpi64:default/linux/arm64/23.0/split-usr/desktop/genpi64

# Package use flags
mkdir -p /etc/portage/package.use
cat > /etc/portage/package.use/rpi-64bit-meta <<USEFLAGS
dev-embedded/rpi-64bit-meta apps -weekly-genup
USEFLAGS

# License acceptance
mkdir -p /etc/portage/package.license
echo "media-fonts/ipamonafont grass-ipafonts" > /etc/portage/package.license/ipamonafont

# Install meta packages
emerge --ask=n -j5 --keep-going rpi-64bit-meta

# Config updates
etc-update --automode -3
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
env-update && source /etc/profile

# Create user
useradd "$USERNAME"
echo "$USERNAME:$ROOT_PASSWORD" | chpasswd
usermod -aG wheel "$USERNAME"

# Sudo privileges
sed -i 's|# %wheel|%wheel|' /etc/sudoers
sed -i 's|ALL=(ALL:ALL) ALL|ALL=(ALL:ALL) NOPASSWD: ALL|' /etc/sudoers

# Lock root login
passwd -l root
sed -i 's|^PermitRootLogin.*|#PermitRootLogin prohibit-password|' /etc/ssh/sshd_config

# Enable services
rc-update add dbus default
rc-update add NetworkManager default
rc-update add display-manager default
rc-update add sshd default
rc-update add ntpd default

# Configure display manager
echo 'DISPLAY_MANAGER="lightdm"' > /etc/conf.d/display-manager
echo 'XSESSION="Xfce4"' > /etc/env.d/90xsession
env-update && source /etc/profile

# Optional: fix LightDM background if default exists
sed -i 's|user-background=true|user-background=false|' /etc/lightdm/lightdm-gtk-greeter.conf || true

# X11 keyboard + video
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

# Clean up mounts
log_step "Unmounting and cleaning..."
umount -l "$BUILD_DIR/rootfs/dev" || true
umount -l "$BUILD_DIR/rootfs/proc" || true
umount -l "$BUILD_DIR/rootfs/sys" || true
umount "$BUILD_DIR/bootfs" || true
umount "$BUILD_DIR/rootfs" || true
rmdir "$BUILD_DIR/bootfs" "$BUILD_DIR/rootfs" || true

log_success "Install finalized. SD card ready to boot."
