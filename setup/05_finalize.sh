#!/bin/bash
set -e

DIR="/root/RASPBERRY_PI_GENTOO"
source "$DIR/config.env"
source "$DIR/setup/shared.sh"
load_config
check_root

log_title "Step 5: Final Setup (User, Services, Display, systemd)"

cd "$BUILD_DIR"
mkdir -p "$BUILD_DIR/rootfs/dev" "$BUILD_DIR/rootfs/proc" "$BUILD_DIR/rootfs/sys"

# Mount virtual filesystems
log_step "Mounting /dev, /proc, /sys to chroot..."
mount --bind /dev "$BUILD_DIR/rootfs/dev"
mount --bind /proc "$BUILD_DIR/rootfs/proc"
mount --bind /sys "$BUILD_DIR/rootfs/sys"

cp /etc/resolv.conf "$BUILD_DIR/rootfs/etc/resolv.conf"

# Write environment variables for chroot session
cat > "$BUILD_DIR/rootfs/tmp/chroot_env.sh" <<EOF
export USERNAME="$USERNAME"
export ROOT_PASSWORD="$ROOT_PASSWORD"
export TIMEZONE="$TIMEZONE"
export KEYMAP="$KEYMAP"
EOF

log_step "Entering chroot environment..."

chroot "$BUILD_DIR/rootfs" /bin/bash -c 'set -e
source /tmp/chroot_env.sh

export PS1="(RASPBERRY_PI_GENTOO@chroot) # "

# Sync Portage and set profile to official systemd desktop
emerge --sync
eselect profile set default/linux/arm64/23.0/desktop/systemd

# Set up timezone
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
echo $TIMEZONE > /etc/timezone

env-update && source /etc/profile

# Install systemd services and desktop stack
emerge --ask=n -j5 --keep-going net-misc/networkmanager net-misc/openssh sys-apps/systemd-timesyncd \
x11-base/xorg-server x11-terms/xterm x11-wm/i3 x11-misc/i3blocks kde-plasma/sddm

# Enable systemd services
systemctl enable NetworkManager
systemctl enable sshd
systemctl enable systemd-timesyncd
systemctl enable sddm

# Create user and set password
useradd -m -G wheel,audio,video,users -s /bin/bash "$USERNAME"
echo "$USERNAME:$ROOT_PASSWORD" | chpasswd

# Sudo privileges (NOPASSWD for wheel group)
echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel

# X11 keyboard + video config
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

# .xinitrc for i3 (if user wants startx)
echo 'exec i3' > /home/$USERNAME/.xinitrc
chown $USERNAME:$USERNAME /home/$USERNAME/.xinitrc

# Lock root login for security
passwd -l root
sed -i "s|^#PermitRootLogin.*|PermitRootLogin prohibit-password|" /etc/ssh/sshd_config || true

# Clean up temp env file
rm -f /tmp/chroot_env.sh
'

# Clean up mounts
log_step "Unmounting and cleaning..."
sync
sleep 1
umount -l "$BUILD_DIR/rootfs/dev" || true
umount -l "$BUILD_DIR/rootfs/proc" || true
umount -l "$BUILD_DIR/rootfs/sys" || true
umount "$BUILD_DIR/bootfs" || true
umount "$BUILD_DIR/rootfs" || true
rmdir "$BUILD_DIR/bootfs" "$BUILD_DIR/rootfs" || true

log_success "Install finalized. SD card ready to boot."
