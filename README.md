# Gentoo Raspberry Pi 5 Installer

This is a **fully automated installer** for Gentoo Linux on Raspberry Pi 5, including a full desktop environment and systemd.  
Inspired by @allans-workshop on YouTube, but modernized and modular.

## Features

- Official Gentoo stage3, systemd, and Portage tree
- Supports both Btrfs and Ext4 for root filesystem
- Up-to-date GenPi64 kernel and firmware
- Full desktop environment (i3wm + SDDM by default; easy to change to XFCE, KDE, etc)
- SSH, NetworkManager, and display manager pre-configured
- User account and sudo configured automatically
- Auto-configurable via `config.env`
- Color-coded logging, clear error handling, dependency auto-check for APT-based hosts

## Usage

1. **Edit `config.env`**  
   - Set your target SD/USB/SSD device and preferences

2. **Make scripts executable**  
   ```bash
   chmod +x setup/*.sh install.sh
