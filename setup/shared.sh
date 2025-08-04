#!/bin/bash

# Only load once
[[ -n "$__SHARED_SH_INCLUDED" ]] && return
__SHARED_SH_INCLUDED=1

log_title() {
  echo -e "\n\033[1;34m==> $1\033[0m"
}

log_step() {
  echo -e "\033[1;33m--> $1\033[0m"
}

log_success() {
  echo -e "\033[1;32m✔ $1\033[0m"
}

log_error() {
  echo -e "\033[1;31m✖ $1\033[0m"
  exit 1
}

log_info() {
  echo -e "\033[1;36m$1\033[0m"
}

check_root() {
  if [[ $EUID -ne 0 ]]; then
    log_error "Please run as root or with sudo"
  fi
}

require_vars() {
  local vars=("$@")
  for var in "${vars[@]}"; do
    if [[ -z "${!var}" ]]; then
      log_error "Missing required config value: $var (current value: '${!var}')"
    fi
  done
}

load_config() {
  require_vars SDCARD ROOT_PASSWORD HOSTNAME KEYMAP TIMEZONE USERNAME BUILD_DIR
}
