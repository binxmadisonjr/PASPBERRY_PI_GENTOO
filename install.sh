#!/bin/bash
set -e

# Load config and shared functions
source ./config.env
source ./setup/shared.sh

# Main script steps
log_title "Starting Gentoo Install Script for Raspberry Pi (5)"

./setup/01_downloads.sh
./setup/02_partition_format.sh
./setup/03_extract_files.sh
./setup/04_config_system.sh
./setup/05_finalize.sh

log_success "Gentoo installation complete. You may now boot your Raspberry Pi."
