#!/bin/bash
set -e

DIR="/root/RASPBERRY_PI_GENTOO"
source "$DIR/config.env"
source "$DIR/setup/shared.sh"
load_config
check_root

log_title "Step 4: System Configuration (systemd)"

ROOTFS="$BUILD_DIR/rootfs"
BOOTFS="$BUILD_DIR/bootfs"

# Hash root password
ROOT_PASSWORD_SALT=$(openssl rand -base64 12)
ROOT_PASSWORD_HASHED=$(openssl passwd -6 -salt "$ROOT_PASSWORD_SALT" "$ROOT_PASSWORD")

log_step "Setting root password..."
sed -i "s|^root:[^:]*:|root:${ROOT_PASSWORD_HASHED}:|" "$ROOTFS/etc/shadow"

log_step "Setting keyboard layout: $KEYMAP"
echo "KEYMAP=\"$KEYMAP\"" > "$ROOTFS/etc/conf.d/keymaps"

log_step "Setting hostname: $HOSTNAME"
echo "$HOSTNAME" > "$ROOTFS/etc/hostname"

log_step "Setting up timezone..."
echo "$TIMEZONE" > "$ROOTFS/etc/timezone"
ln -sf "/usr/share/zoneinfo/$TIMEZONE" "$ROOTFS/etc/localtime"

log_step "Adding fstab entry..."
cat > "$ROOTFS/etc/fstab" <<EOF
PARTUUID=6c586e13-01  /boot  vfat  defaults,noatime  0 2
PARTUUID=6c586e13-02  /      btrfs defaults,noatime,compress=zstd:15  0 1
EOF

log_step "Editing cmdline.txt..."
sed -i "s|root=.* |root=PARTUUID=6c586e13-02 rootfstype=btrfs rootdelay=0 |" "$BOOTFS/cmdline.txt"

log_step "Setting up Portage repos.conf..."
mkdir -p "$ROOTFS/etc/portage/repos.conf"

cat > "$ROOTFS/etc/portage/repos.conf/gentoo.conf" <<EOF
[DEFAULT]
main-repo = gentoo

[gentoo]
location = /var/db/repos/gentoo
sync-type = rsync
sync-uri = rsync://rsync.gentoo.org/gentoo-portage
auto-sync = yes
EOF

log_step "Writing make.conf (systemd profile, no drassal binhost)..."
cat > "$ROOTFS/etc/portage/make.conf" <<EOF
MAKEOPTS="-j5 -l4"
EMERGE_DEFAULT_OPTS="--jobs=5 --load-average=4"
VIDEO_CARDS="vc4 fbdev"
INPUT_DEVICES="evdev libinput"
FEATURES="\${FEATURES} getbinpkg"
# Set only if you have a known good binhost for ARM64/Pi5:
# PORTAGE_BINHOST=""
GENTOO_MIRRORS="https://mirrors.evowise.com/gentoo/ https://mirrors.lug.mtu.edu/gentoo/ http://distfiles.gentoo.org"
PKGDIR=/var/cache/binpkgs
DISTDIR=/var/cache/distfiles
PYTHON_TARGETS="python3_11 python3_12"
USE="systemd"
EOF

log_step "Enabling SSH login for root (temporary)..."
sed -i 's|^#PermitRootLogin.*|PermitRootLogin yes|' "$ROOTFS/etc/ssh/sshd_config" || true

log_success "System base config complete (systemd)"
