#!/bin/bash
set -e

DIR="/root/RASPBERRY_PI_GENTOO"
source "$DIR/config.env"
source "$DIR/setup/shared.sh"
load_config
check_root

log_title "Step 3: Extracting Base System"

cd "$BUILD_DIR"

# Version variables (could move to config.env)
BOOTFS="bootfs_20250128.tar.bz2"
STAGE3=$(ls stage3-*-*.tar.xz | head -n1)
MODULES="rootfs_modules_20250128.tar.bz2"
FW_NONFREE="rootfs_firmware-nonfree_20250128.tar.bz2"
FW_BLUEZ="rootfs_firmware-bluez_20250128.tar.bz2"
KERNEL_SRC="linux-6.6.74-raspberrypi_20250128.tar.bz2"
KERNEL_SRC_DIR="linux-6.6.74-raspberrypi_20250128"

# Ensure required files exist
for f in "$BOOTFS" "$STAGE3" "$MODULES" "$FW_NONFREE" "$FW_BLUEZ" "$KERNEL_SRC"; do
    [[ -f "$f" ]] || { log_error "$f not found in $BUILD_DIR"; exit 1; }
done

# Extract archives
log_step "Extracting bootfs..."
tar xjfp "$BOOTFS" -C "$BUILD_DIR/bootfs" || { log_error "Failed to extract $BOOTFS"; exit 1; }

log_step "Extracting stage3 to rootfs..."
tar xfp "$STAGE3" -C "$BUILD_DIR/rootfs" || { log_error "Failed to extract $STAGE3"; exit 1; }

log_step "Extracting kernel modules..."
mkdir -p "$BUILD_DIR/rootfs/lib/modules"
tar xpjf "$MODULES" -C "$BUILD_DIR/rootfs/lib/modules" || { log_error "Failed to extract $MODULES"; exit 1; }

log_step "Extracting firmware..."
mkdir -p "$BUILD_DIR/rootfs/lib/firmware"
tar xpjf "$FW_NONFREE" -C "$BUILD_DIR/rootfs/lib/firmware" || { log_error "Failed to extract $FW_NONFREE"; exit 1; }
tar xpjf "$FW_BLUEZ" -C "$BUILD_DIR/rootfs/lib/firmware" || { log_error "Failed to extract $FW_BLUEZ"; exit 1; }

log_step "Extracting kernel sources..."
mkdir -p "$BUILD_DIR/rootfs/usr/src/$KERNEL_SRC_DIR"
tar xpjf "$KERNEL_SRC" -C "$BUILD_DIR/rootfs/usr/src/$KERNEL_SRC_DIR" || { log_error "Failed to extract $KERNEL_SRC"; exit 1; }

log_step "Creating kernel symlink..."
cd "$BUILD_DIR/rootfs/usr/src"
rm -f linux
ln -sf "$KERNEL_SRC_DIR" linux
cd "$BUILD_DIR"

log_success "All base files extracted"
