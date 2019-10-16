#!/bin/bash

# Usage: ./add-swapfile.sh [1G] [/swapfile]
SIZE=${1:-1G}
SWAPFILE=${2:-/swapfile}

# --------------------------------------------------------------
# Don't edit below this line unless you know what you're doing!
# --------------------------------------------------------------
date

if [ "$(id -u)" != "0" ]; then
  echo "Must be run as root, directly or with sudo"
  exit 1
fi

# Configure Swap Disk
if [ -f "$SWAPFILE" ]; then
    echo "Swap exists."
else
    fallocate -l "${SIZE^^}" "$SWAPFILE"
    chmod 600 "$SWAPFILE"
    mkswap "$SWAPFILE"
    swapon "$SWAPFILE"
    sysctl vm.swappiness=10
    echo "$SWAPFILE swap swap defaults 0 0" >> /etc/fstab
    echo "vm.swappiness=10" >> /etc/sysctl.conf
    echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf

    # Verify
    swapon --show
    free -hm
fi
