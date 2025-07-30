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

# Core files
log_step "Downloading stage3..."
wget -nc "$STAGE3_URL"
wget -nc "$STAGE3_DIGEST_URL"

log_step "Downloading bootfs and kernel components..."
for url in "$BOOTFS_URL" "$MODULES_URL" "$FW_NONFREE_URL" "$FW_BLUEZ_URL" "$KERNEL_SRC_URL"; do
  wget -nc "$url"
done

# Optional files
if [[ "$BINPKGS_ENABLED" == "true" ]]; then
  log_step "Downloading binpkgs (2.3G)..."
  wget -nc "$BINPKG_URL"
fi

if [[ "$DISTFILES_ENABLED" == "true" ]]; then
  log_step "Downloading distfiles (7.7G)..."
  wget -nc "$DISTFILES_URL"
fi

# Hash check
log_step "Verifying stage3 hash..."
DIGEST_FILE=$(basename "$STAGE3_DIGEST_URL")
STAGE3_FILE=$(basename "$STAGE3_URL")
EXPECTED_HASH=$(grep "$STAGE3_FILE\$" "$DIGEST_FILE" | tail -n 1 | cut -d ' ' -f1)
ACTUAL_HASH=$(sha512sum "$STAGE3_FILE" | cut -d ' ' -f1)

if [[ "$EXPECTED_HASH" != "$ACTUAL_HASH" ]]; then
  echo "❌ Hash mismatch!"
  exit 1
fi

log_step "Downloaded files in $BUILD_DIR:"
ls -lh "$BUILD_DIR"

log_success "All downloads complete and verified"

