#!/bin/bash

log_title() {
  echo -e "\n\033[1;34m==> $1\033[0m"
}

log_step() {
  echo -e "\033[1;33m--> $1\033[0m"
}

log_success() {
  echo -e "\033[1;32m✔ $1\033[0m"
}

check_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Please run as root"
    exit 1
  fi
}

require_vars() {
  local vars=("$@")
  for var in "${vars[@]}"; do
    if [[ -z "${!var}" ]]; then
      echo "Missing required config value: $var"
      exit 1
    fi
  done
}

load_config() {
  require_vars SDCARD ROOT_PASSWORD HOSTNAME KEYMAP TIMEZONE USERNAME
}
