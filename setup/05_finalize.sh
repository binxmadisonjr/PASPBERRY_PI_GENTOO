#!/bin/bash
set -e
source ./config.env
source ./setup/shared.sh
load_config
check_root

log_title "Step 5: Final Setup (User, Services, Display)"

# Make mountpoints before attempting to mount
cd "$BUILD_DIR"
mkdir -p rootfs/dev rootfs/proc rootfs/sys

# Mount virtual filesystems
log_step "Mounting /dev, /proc, /sys to chroot..."
mount --bind /dev "$BUILD_DIR/rootfs/dev"
mount --bind /proc "$BUILD_DIR/rootfs/proc"
mount --bind /sys "$BUILD_DIR/rootfs/sys"

log_step "Entering chroot environment..."

# Export variables to pass them into chroot
export USERNAME ROOT_PASSWORD TIMEZONE KEYMAP

# Run commands in chroot
env -i USERNAME="$USERNAME" ROOT_PASSWORD="$ROOT_PASSWORD" TIMEZONE="$TIMEZONE" KEYMAP="$KEYMAP" chroot "$BUILD_DIR/rootfs" /bin/bash <<'EOF'
set -e

emerge --sync
eselect profile set genpi64:default/linux/arm64/23.0/split-usr/desktop/genpi64

mkdir -p /etc/portage/package.use
cat > /etc/portage/package.use/rpi-64bit-meta <<USEFLAGS
dev-embedded/rpi-64bit-meta apps -weekly-genup
USEFLAGS

mkdir -p /etc/portage/package.license
echo "media-fonts/ipamonafont grass-ipafonts" > /etc/portage/package.license/ipamonafont

emerge --ask=n -j5 --keep-going rpi-64bit-meta

etc-update --automode -3

ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
env-update && source /etc/profile

useradd "$USERNAME"
echo "$USERNAME:$ROOT_PASSWORD" | chpasswd
usermod -aG wheel "$USERNAME"

sed -i 's|# %wheel|%wheel|' /etc/sudoers
sed -i 's|ALL=(ALL:ALL) ALL|ALL=(ALL:ALL) NOPASSWD: ALL|' /etc/sudoers

passwd -l root
sed -i 's|^PermitRootLogin.*|#PermitRootLogin prohibit-password|' /etc/ssh/sshd_config

rc-update add dbus default
rc-update add NetworkManager default
rc-update add display-manager default
rc-update add sshd default
rc-update add ntpd default

echo 'DISPLAY_MANAGER="lightdm"' > /etc/conf.d/display-manager
echo 'XSESSION="Xfce4"' > /etc/env.d/90xsession
env-update && source /etc/profile

sed -i 's|user-background=true|user-background=false|' /etc/lightdm/lightdm-gtk-greeter.conf || true

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
umount -l rootfs/dev || true
umount -l rootfs/proc || true
umount -l rootfs/sys || true
umount bootfs || true
umount rootfs || true
rmdir bootfs rootfs || true

log_success "Install finalized. SD card ready to boot."
