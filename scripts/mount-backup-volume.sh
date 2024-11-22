#!/bin/bash

# Source environment variables
source /root/supreme-computing-machine/.env

# Ensure required environment variables are set
if [ -z "$BACKUP_VOLUME_PATH" ]; then
    echo "Error: BACKUP_VOLUME_PATH is not set"
    exit 1
fi

if [ -z "$BACKUP_MOUNT_POINT" ]; then
    BACKUP_MOUNT_POINT="/mnt/backup"
fi

# Create backup mount point
mkdir -p "$BACKUP_MOUNT_POINT"

# Create restic repository directory
mkdir -p "$BACKUP_MOUNT_POINT/restic-repo"

# Check if restic is installed, install if not
if ! command -v restic &> /dev/null; then
    echo "Restic not found, installing..."
    apt-get update && apt-get install -y restic
fi

# Format the volume if it's not already formatted
if ! blkid "$BACKUP_VOLUME_PATH"; then
    echo "Formatting volume $BACKUP_VOLUME_PATH..."
    mkfs.ext4 "$BACKUP_VOLUME_PATH"
fi

# Add to fstab if not already there
FSTAB_ENTRY="$BACKUP_VOLUME_PATH $BACKUP_MOUNT_POINT ext4 discard,nofail,defaults 0 0"
if ! grep -q "$BACKUP_VOLUME_PATH $BACKUP_MOUNT_POINT" /etc/fstab; then
    echo "Adding volume to fstab..."
    echo "$FSTAB_ENTRY" >> /etc/fstab
fi

# Mount the volume
echo "Mounting volume..."
mount -o discard,defaults "$BACKUP_VOLUME_PATH" "$BACKUP_MOUNT_POINT"

# Set proper permissions
chown -R root:root "$BACKUP_MOUNT_POINT"
chmod -R 700 "$BACKUP_MOUNT_POINT"

echo "Volume mounted successfully at $BACKUP_MOUNT_POINT"
