#!/bin/bash
set -e

# ----------- Dependency Pre-flight Check -----------
REQUIRED_PKGS=(btrfs-progs parted fdisk dosfstools tar wget openssl sudo coreutils)

missing=()
for pkg in "${REQUIRED_PKGS[@]}"; do
    dpkg -s "$pkg" &>/dev/null || missing+=("$pkg")
done

if (( ${#missing[@]} )); then
    echo -e "\n\033[1;31m✖ Missing packages: ${missing[*]}\033[0m"
    echo "Installing required packages with apt..."
    sudo apt update
    sudo apt install -y "${missing[@]}"
    echo -e "\n\033[1;32m✔ All required packages are now installed.\033[0m"
else
    echo -e "\n\033[1;32m✔ All required packages are already installed.\033[0m"
fi

# ----------- Script Setup -----------
DIR="/root/RASPBERRY_PI_GENTOO"

# Load config and shared functions
source "$DIR/config.env"
source "$DIR/setup/shared.sh"

log_title "Starting Gentoo Install Script for Raspberry Pi (5)"

"$DIR/setup/01_downloads.sh"
"$DIR/setup/02_partition_format.sh"
"$DIR/setup/03_extract_files.sh"
"$DIR/setup/04_config_system.sh"
"$DIR/setup/05_finalize.sh"

log_success "Gentoo installation complete. You may now boot your Raspberry Pi."
