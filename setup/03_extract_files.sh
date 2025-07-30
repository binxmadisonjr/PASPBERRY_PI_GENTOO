#!/bin/bash
set -e

source ./setup/shared.sh
source ./config.env
load_config
check_root

log_title "Step 3: Extracting Base System"

cd "$BUILD_DIR"
mkdir -p bootfs rootfs

[[ -f bootfs_20250128.tar.bz2 ]] || { echo "❌ bootfs not found in $BUILD_DIR"; exit 1; }

log_step "Extracting bootfs..."
tar xjfp bootfs_20250128.tar.bz2 -C bootfs

log_step "Extracting stage3 to rootfs..."
tar xfp stage3-arm64-openrc-splitusr-*.tar.xz -C rootfs

log_step "Extracting kernel modules..."
mkdir -p rootfs/lib/modules
tar xpjf rootfs_modules_20250128.tar.bz2 -C rootfs/lib/modules

log_step "Extracting firmware..."
mkdir -p rootfs/lib/firmware
tar xpjf rootfs_firmware-nonfree_20250128.tar.bz2 -C rootfs/lib/firmware
tar xpjf rootfs_firmware-bluez_20250128.tar.bz2 -C rootfs/lib/firmware

log_step "Extracting kernel sources..."
mkdir -p rootfs/usr/src/linux-6.6.74-raspberrypi_20250128
tar xpjf linux-6.6.74-raspberrypi_20250128.tar.bz2 -C rootfs/usr/src/linux-6.6.74-raspberrypi_20250128

log_step "Creating kernel symlink..."
cd rootfs/usr/src
ln -s linux-6.6.74-raspberrypi_20250128 linux || true
cd ../../..

log_success "All base files extracted"

