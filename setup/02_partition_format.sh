#!/bin/bash
set -e

source $BUILD_DIR/config.env
source $BUILD_DIR/setup/shared.sh
load_config
check_root

log_title "Step 2: Partitioning and Formatting SD Card"

# Unmount existing partitions if mounted
log_step "Unmounting existing partitions..."
umount "${SDCARD}1" || true
umount "${SDCARD}2" || true

# Create partition table
log_step "Creating partition table..."
parted --script "$SDCARD" \
  mklabel msdos \
  mkpart primary fat32 1MiB 512MiB \
  mkpart primary ext4 512MiB 100% \
  set 1 boot on \
  set 1 lba on

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
mkfs.btrfs -f -L rootfs "${SDCARD}2"

# Create and mount to build directory
log_step "Creating mountpoints in build directory..."
mkdir -p "$BUILD_DIR/bootfs" "$BUILD_DIR/rootfs"

log_step "Mounting partitions..."
mount -o rw,nosuid,nodev,relatime "${SDCARD}1" "$BUILD_DIR/bootfs"
mount -o noatime,compress=zstd:15,ssd,discard,x-systemd.growfs "${SDCARD}2" "$BUILD_DIR/rootfs"

log_success "Partitions formatted and mounted"
