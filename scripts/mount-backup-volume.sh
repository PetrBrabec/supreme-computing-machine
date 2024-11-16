#!/bin/bash

# Source environment variables
source /root/.env

# Create backup mount point
mkdir -p /mnt/backup

# Format the volume if it's not already formatted
if ! blkid $BACKUP_VOLUME_DEVICE; then
    mkfs.ext4 $BACKUP_VOLUME_DEVICE
fi

# Add to fstab if not already there
if ! grep -q "$BACKUP_VOLUME_DEVICE /mnt/backup" /etc/fstab; then
    echo "$BACKUP_VOLUME_DEVICE /mnt/backup ext4 defaults 0 2" >> /etc/fstab
fi

# Mount the volume
mount -a

# Create backup directories
mkdir -p /mnt/backup/docker-volumes
mkdir -p /mnt/backup/restic-repo
