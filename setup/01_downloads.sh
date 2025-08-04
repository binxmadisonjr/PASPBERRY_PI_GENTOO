#!/bin/bash
set -e

DIR="/root/RASPBERRY_PI_GENTOO"
source "$DIR/config.env"
source "$DIR/setup/shared.sh"
load_config

log_title "Step 1: Downloading Required Files"

# Ensure build directory exists
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Check for wget or curl
if ! command -v wget &>/dev/null && ! command -v curl &>/dev/null; then
    log_error "wget or curl required!"
    exit 1
fi

# Helper: download with retries
download() {
    local url="$1"
    local out="${2:-}"
    for attempt in {1..5}; do
        if [[ -n "$out" ]]; then
            wget -c "$url" -O "$out" && return 0
        else
            wget -c "$url" && return 0
        fi
        log_step "Retry $attempt for $url..."
        sleep 2
    done
    log_error "Failed to download $url"
    exit 1
}

# URLs (recommend moving to config.env)
STAGE3_URL="https://dev.drassal.net/genpi64/stage3-arm64-openrc-splitusr-20250112T234833Z.tar.xz"
STAGE3_DIGEST_URL="$STAGE3_URL.DIGESTS"
BOOTFS_URL="https://dev.drassal.net/genpi64/bootfs_20250128.tar.bz2"
MODULES_URL="https://dev.drassal.net/genpi64/rootfs_modules_20250128.tar.bz2"
FW_NONFREE_URL="https://dev.drassal.net/genpi64/rootfs_firmware-nonfree_20250128.tar.bz2"
FW_BLUEZ_URL="https://dev.drassal.net/genpi64/rootfs_firmware-bluez_20250128.tar.bz2"
KERNEL_SRC_URL="https://dev.drassal.net/genpi64/linux-6.6.74-raspberrypi_20250128.tar.bz2"
BINPKG_URL="https://dev.drassal.net/genpi64/binpkgs_202501210142.tar.bz2"
DISTFILES_URL="https://dev.drassal.net/genpi64/distfiles_202501210142.tar.bz2"

# Download files
log_step "Downloading stage3..."
download "$STAGE3_URL"
download "$STAGE3_DIGEST_URL"

log_step "Downloading bootfs and kernel components..."
for url in "$BOOTFS_URL" "$MODULES_URL" "$FW_NONFREE_URL" "$FW_BLUEZ_URL" "$KERNEL_SRC_URL"; do
  download "$url"
done

if [[ "$BINPKGS_ENABLED" == "true" ]]; then
  log_step "Downloading binpkgs (2.3G)..."
  download "$BINPKG_URL"
fi

if [[ "$DISTFILES_ENABLED" == "true" ]]; then
  log_step "Downloading distfiles (7.7G)..."
  download "$DISTFILES_URL"
fi

# Hash check
log_step "Verifying stage3 hash..."
DIGEST_FILE=$(basename "$STAGE3_DIGEST_URL")
STAGE3_FILE=$(basename "$STAGE3_URL")
EXPECTED_HASH=$(grep "$STAGE3_FILE\$" "$DIGEST_FILE" | tail -n 1 | cut -d ' ' -f1)
ACTUAL_HASH=$(sha512sum "$STAGE3_FILE" | cut -d ' ' -f1)

if [[ "$EXPECTED_HASH" != "$ACTUAL_HASH" ]]; then
  log_error "Hash mismatch! Exiting."
  exit 1
fi

log_step "Checking all downloaded files exist..."
for f in "$STAGE3_FILE" "$DIGEST_FILE" \
         "$(basename "$BOOTFS_URL")" "$(basename "$MODULES_URL")" \
         "$(basename "$FW_NONFREE_URL")" "$(basename "$FW_BLUEZ_URL")" \
         "$(basename "$KERNEL_SRC_URL")"
do
    [[ -f "$f" ]] || { log_error "Missing file: $f"; exit 1; }
done

log_step "Downloaded files in $BUILD_DIR:"
ls -lh "$BUILD_DIR"

log_success "All downloads complete and verified"
