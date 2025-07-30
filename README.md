# Gentoo Raspberry Pi 5 Installer

This is a fully automated script to install a complete Gentoo Linux system on a Raspberry Pi 5, including XFCE and LightDM.
Based largely on @allans-workshop on YouTube 

## Features
- Uses up-to-date GenPi64 kernel and firmware
- Full desktop environment (XFCE)
- SSH, NetworkManager, LightDM preconfigured
- Auto-configurable via `config.env`

## Usage

1. **Edit `config.env`** to match your SD/USB/SSD card and settings.
2. **Run** the install script as root:

```bash
chmod +x install.sh
sudo ./install.sh