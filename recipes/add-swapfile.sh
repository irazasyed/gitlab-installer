#!/bin/bash

SIZE=2G
SWAPFILE=/swapfile

# Configure Swap Disk
if [ -f $SWAPFILE ]; then
    echo "Swap exists."
else
    fallocate -l $SIZE $SWAPFILE
    chmod 600 $SWAPFILE
    mkswap $SWAPFILE
    swapon $SWAPFILE
    sysctl vm.swappiness=10
    echo "$SWAPFILE swap swap defaults 0 0" >> /etc/fstab
    echo "vm.swappiness=10" >> /etc/sysctl.conf
    echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf

    # Verify
    swapon --show
    free -hm
fi
