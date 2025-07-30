#!/bin/bash
set -e

source ./config.env
source ./setup/shared.sh
load_config

log_title "Step 1: Downloading Required Files"

# Ensure build directory exists
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# URLs
STAGE3_URL="https://dev.drassal.net/genpi64/stage3-arm64-openrc-splitusr-20250112T234833Z.tar.xz"
STAGE3_DIGEST_URL="$STAGE3_URL.DIGESTS"
BOOTFS_URL="https://dev.drassal.net/genpi64/bootfs_20250128.tar.bz2"
MODULES_URL="https://dev.drassal.net/genpi64/rootfs_modules_20250128.tar.bz2"
FW_NONFREE_URL="https://dev.drassal.net/genpi64/rootfs_firmware-nonfree_20250128.tar.bz2"
FW_BLUEZ_URL="https://dev.drassal.net/genpi64/rootfs_firmware-bluez_20250128.tar.bz2"
KERNEL_SRC_URL="https://dev.drassal.net/genpi64/linux-6.6.74-raspberrypi_20250128.tar.bz2"
BINPKG_URL="https://dev.drassal.net/genpi64/binpkgs_202501210142.tar.bz2"
DISTFILES_URL="https://dev.drassal.net/genpi64/distfiles_202501210142.tar.bz2"

# Core downloads
log_step "Downloading stage3..."
wget -nc "$STAGE3_URL"
wget -nc "$STAGE3_DIGEST_URL"

log_step "Downloading bootfs and kernel components..."
wget -nc "$BOOTFS_URL"
wget -nc "$MODULES_URL"
wget -nc "$FW_NONFREE_URL"
wget -nc "$FW_BLUEZ_URL"
wget -nc "$KERNEL_SRC_URL"

# Optional content
if [[ "$BINPKGS_ENABLED" == "true" ]]; then
  log_step "Downloading binpkgs (2.3G)..."
  wget -nc "$BINPKG_URL"
fi

if [[ "$DISTFILES_ENABLED" == "true" ]]; then
  log_step "Downloading distfiles (7.7G)..."
  wget -nc "$DISTFILES_URL"
fi

# Verify integrity
log_step "Verifying stage3 hash..."
EXPECTED_HASH=$(sed -n '/SHA512 HASH/{n;p;}' "$(basename "$STAGE3_DIGEST_URL")" | grep "$(basename "$STAGE3_URL")"'$' | tail -n 1 | cut -f 1 -d' ')
ACTUAL_HASH=$(sha512sum "$(basename "$STAGE3_URL")" | cut -f 1 -d' ')

if [[ "$EXPECTED_HASH" != "$ACTUAL_HASH" ]]; then
  echo "❌ Hash mismatch!"
  exit 1
fi

# Final confirmation
log_step "Downloaded files:"
ls -lh "$BUILD_DIR"

log_success "All downloads complete and verified"
