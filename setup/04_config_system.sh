#!/bin/bash
set -e

source $DIR/config.env
source $DIR/setup/shared.sh
load_config
check_root

log_title "Step 4: System Configuration"

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

log_step "Linking net.end0 for Ethernet..."
ln -sf net.lo "$ROOTFS/etc/init.d/net.end0"

log_step "Fixing ttyAMA0 bug..."
sed -i 's/^f0/#f0/' "$ROOTFS/etc/inittab"

log_step "Adding fstab entry..."
echo "PARTUUID=6c586e13-01 /boot vfat defaults,noatime 0 0" >> "$ROOTFS/etc/fstab"

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
sync-uri = rsync://dev.drassal.net/gentoo-portage_20250115
auto-sync = yes
EOF

cat > "$ROOTFS/etc/portage/repos.conf/genpi64.conf" <<EOF
[DEFAULT]
main-repo = gentoo

[genpi64]
location = /var/db/repos/genpi64
sync-type = rsync
sync-uri = rsync://dev.drassal.net/genpi64-portage_20250115
priority = 100
auto-sync = yes
EOF

log_step "Writing make.conf..."
cat > "$ROOTFS/etc/portage/make.conf" <<EOF
MAKEOPTS="-j5 -l4"
EMERGE_DEFAULT_OPTS="--jobs=5 --load-average=4"
VIDEO_CARDS="fbdev vc4 v3d"
INPUT_DEVICES="evdev synaptics"
FEATURES="\${FEATURES} getbinpkg"
PORTAGE_BINHOST="https://dev.drassal.net/genpi64/pi64pie_20250115_binpkgs"
GENTOO_MIRRORS="https://mirrors.evowise.com/gentoo/ https://mirrors.lug.mtu.edu/gentoo/ http://distfiles.gentoo.org"
PKGDIR=/var/cache/binpkgs
DISTDIR=/var/cache/distfiles
PYTHON_TARGETS="python3_11 python3_12"
EOF

log_step "Enabling SSH login for root (temporary)..."
sed -i 's|^#PermitRootLogin.*|PermitRootLogin yes|' "$ROOTFS/etc/ssh/sshd_config" || true

log_success "System base config complete"
