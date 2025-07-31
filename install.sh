#!/bin/bash
set -e

# Load config and shared functions
source $BUILD_DIR/config.env
source $BUILD_DIR/setup/shared.sh

# Main script steps
log_title "Starting Gentoo Install Script for Raspberry Pi (5)"

$BUILD_DIR/setup/01_downloads.sh
$BUILD_DIR/setup/02_partition_format.sh
$BUILD_DIR/setup/03_extract_files.sh
$BUILD_DIR/setup/04_config_system.sh
$BUILD_DIR/setup/05_finalize.sh

log_success "Gentoo installation complete. You may now boot your Raspberry Pi."
