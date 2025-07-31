#!/bin/bash
set -e

# Set directory
DIR="/root/RASPBERRY_PI_GENTOO"

# Load config and shared functions
source "$DIR/config.env"
source "$DIR/setup/shared.sh"

# Main script steps
log_title "Starting Gentoo Install Script for Raspberry Pi (5)"

"$DIR/setup/01_downloads.sh"
"$DIR/setup/02_partition_format.sh"
"$DIR/setup/03_extract_files.sh"
"$DIR/setup/04_config_system.sh"
"$DIR/setup/05_finalize.sh"

log_success "Gentoo installation complete. You may now boot your Raspberry Pi."
