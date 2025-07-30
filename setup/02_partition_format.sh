#!/bin/bash
set -e
source ./config.env
source ./setup/shared.sh
load_config
check_root

log_title "Step 2: Partitioning and Formatting SD Card"

# Unmount if mounted
log_step "Unmounting existing partitions..."
umount "${SDCARD}"1 || true
umount "${SDCARD}"2 || true

# Partition
log_step "Creating partition table..."
parted --script "$SDCARD" \
  mklabel msdos \
  mkpart primary fat32 1MiB 512MiB \
  mkpart primary ext4 512MiB 100% \
  set 1 boot on \
  set 1 lba on

# Set PARTUUID for fstab later
log_step "Setting static PARTUUID..."
fdisk "$SDCARD" <<EOF &>/dev/null
x
i
0x6c586e13
r
w
EOF

# Format
log_step "Formatting partitions..."
mkfs.vfat -F 32 -n bootfs "${SDCARD}1"
mkfs.btrfs -f -L rootfs "${SDCARD}2"

# Mount points
mkdir -p bootfs rootfs

log_step "Mounting partitions..."
mount -o rw,nosuid,nodev,relatime "${SDCARD}1" bootfs
mount -o noatime,compress=zstd:15,ssd,discard,x-systemd.growfs "${SDCARD}2" rootfs

log_success "Partitions formatted and mounted"