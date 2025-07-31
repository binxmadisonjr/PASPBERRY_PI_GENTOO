#!/bin/bash
set -e

DIR="/root/RASPBERRY_PI_GENTOO"
source "$DIR/config.env"
source "$DIR/setup/shared.sh"
load_config
check_root

log_title "Step 3: Extracting Base System"

cd "$BUILD_DIR"

# Ensure target dirs exist
mkdir -p "$BUILD_DIR/bootfs" "$BUILD_DIR/rootfs"

# Check for bootfs archive
[[ -f bootfs_20250128.tar.bz2 ]] || { echo "bootfs not found in $BUILD_DIR"; exit 1; }

log_step "Extracting bootfs..."
tar xjfp bootfs_20250128.tar.bz2 -C "$BUILD_DIR/bootfs"

log_step "Extracting stage3 to rootfs..."
tar xfp stage3-arm64-openrc-splitusr-*.tar.xz -C "$BUILD_DIR/rootfs"

log_step "Extracting kernel modules..."
mkdir -p "$BUILD_DIR/rootfs/lib/modules"
tar xpjf rootfs_modules_20250128.tar.bz2 -C "$BUILD_DIR/rootfs/lib/modules"

log_step "Extracting firmware..."
mkdir -p "$BUILD_DIR/rootfs/lib/firmware"
tar xpjf rootfs_firmware-nonfree_20250128.tar.bz2 -C "$BUILD_DIR/rootfs/lib/firmware"
tar xpjf rootfs_firmware-bluez_20250128.tar.bz2 -C "$BUILD_DIR/rootfs/lib/firmware"

log_step "Extracting kernel sources..."
mkdir -p "$BUILD_DIR/rootfs/usr/src/linux-6.6.74-raspberrypi_20250128"
tar xpjf linux-6.6.74-raspberrypi_20250128.tar.bz2 -C "$BUILD_DIR/rootfs/usr/src/linux-6.6.74-raspberrypi_20250128"

log_step "Creating kernel symlink..."
cd "$BUILD_DIR/rootfs/usr/src"
ln -sf linux-6.6.74-raspberrypi_20250128 linux
cd "$BUILD_DIR"

log_success "All base files extracted"
