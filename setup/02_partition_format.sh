#!/bin/bash
set -e

DIR="/root/RASPBERRY_PI_GENTOO"
source "$DIR/config.env"
source "$DIR/setup/shared.sh"
load_config
check_root

log_title "Step 2: Partitioning and Formatting SD Card"

# Unmount all existing partitions on the target device
log_step "Unmounting existing partitions..."
for part in $(lsblk -ln -o NAME "${SDCARD}" | grep -E "^$(basename ${SDCARD})" | grep -v "^$(basename ${SDCARD})$"); do
    umount "/dev/$part" || true
done

# Create partition table
log_step "Creating partition table..."
parted --script "$SDCARD" \
  mklabel msdos \
  mkpart primary fat32 1MiB 512MiB \
  mkpart primary ext4 512MiB 100% \
  set 1 boot on \
  set 1 lba on || { log_error "Partitioning failed!"; exit 1; }

# Set static PARTUUID for reproducible boot
log_step "Setting static PARTUUID..."
fdisk "$SDCARD" <<EOF &>/dev/null
x
i
0x6c586e13
r
w
EOF

# Format partitions
log_step "Formatting partitions..."
mkfs.vfat -F 32 -n bootfs "${SDCARD}1"
mkfs.btrfs -f -L rootfs "${SDCARD}2"  # Change to mkfs.ext4 if you prefer

# Create and mount to build directory
log_step "Creating mountpoints in build directory..."
mkdir -p "$BUILD_DIR/bootfs" "$BUILD_DIR/rootfs"

log_step "Mounting partitions..."
mount -o rw,nosuid,nodev,relatime "${SDCARD}1" "$BUILD_DIR/bootfs"
mount -o noatime,compress=zstd:15,ssd,discard,x-systemd.growfs "${SDCARD}2" "$BUILD_DIR/rootfs"

log_step "Resulting partition layout:"
lsblk "$SDCARD"

log_success "Partitions formatted and mounted"
