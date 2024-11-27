#!/bin/bash
set -e

# Source environment variables
source /root/supreme-computing-machine/.env

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Function to send notification
send_notification() {
    "${SCRIPT_DIR}/notify.sh" "$1"
}

# Error handling function
handle_error() {
    send_notification "❌ *Volume Init Failed*

Error: ${1}"
    exit 1
}

# Set up error handling
trap 'handle_error "Unexpected error occurred"' ERR

# Create password file for restic
echo "$RESTIC_PASSWORD" > /root/.restic-pass
chmod 600 /root/.restic-pass

# Check if any snapshots exist
SNAPSHOTS=$(restic -r "$RESTIC_REPOSITORY" --password-file /root/.restic-pass snapshots 2>/dev/null || true)
if [ -z "$SNAPSHOTS" ]; then
    echo "No snapshots found in repository - starting fresh"
    rm -f /root/.restic-pass
    exit 0
fi

# Get the latest snapshot ID
SNAPSHOT_ID=$(restic -r "$RESTIC_REPOSITORY" --password-file /root/.restic-pass snapshots | grep -A1 "^ID" | tail -n1 | awk '{print $1}')
if [ -z "$SNAPSHOT_ID" ]; then
    echo "No valid snapshot ID found - starting fresh"
    rm -f /root/.restic-pass
    exit 0
fi

RESTORE_DIR="/mnt/backup/restore_${SNAPSHOT_ID}"

# Start init notification
send_notification "*🔄 Initializing volumes from backup...*
Snapshot: \`${SNAPSHOT_ID}\`"

# Restore from restic
restic -r "$RESTIC_REPOSITORY" --password-file /root/.restic-pass restore "$SNAPSHOT_ID" --target "$RESTORE_DIR"

# Debug: List backup contents
echo "Backup contents:"
ls -R "$RESTORE_DIR"

VOLUMES_DIR="$RESTORE_DIR/mnt/backup/docker-volumes"
if [ ! -d "$VOLUMES_DIR" ]; then
    echo "Error: Docker volumes directory not found at $VOLUMES_DIR"
    ls -la "$RESTORE_DIR"
    ls -la "$RESTORE_DIR/mnt"
    ls -la "$RESTORE_DIR/mnt/backup" || true
    handle_error "Volumes directory not found"
fi

echo "Available volumes in backup:"
ls -la "$VOLUMES_DIR"

# Initialize each volume
for VOLUME_DIR in "$VOLUMES_DIR"/*/; do
    if [ -d "$VOLUME_DIR" ]; then
        VOLUME_NAME=$(basename "$VOLUME_DIR")
        DATA_DIR="$VOLUME_DIR/_data"
        
        if [ ! -d "$DATA_DIR" ]; then
            echo "Error: Data directory not found at $DATA_DIR"
            ls -la "$VOLUME_DIR"
            handle_error "Data directory not found"
        fi

        echo "Initializing volume: $VOLUME_NAME"
        echo "Volume contents:"
        ls -la "$DATA_DIR"
        
        docker volume create "$VOLUME_NAME" || true
        VOLUME_MOUNTPOINT=$(docker volume inspect "$VOLUME_NAME" --format '{{ .Mountpoint }}')
        echo "Volume mountpoint: $VOLUME_MOUNTPOINT"
        
        rm -rf "${VOLUME_MOUNTPOINT:?}"/* # Safety check to ensure VOLUME_MOUNTPOINT is not empty
        rsync -av --inplace --progress "$DATA_DIR/" "$VOLUME_MOUNTPOINT/"
        
        # Set correct permissions for postgres data
        if [[ "$VOLUME_NAME" == *"postgres"* ]]; then
            echo "Setting postgres data permissions"
            chown -R 999:999 "$VOLUME_MOUNTPOINT"  # 999 is postgres user in container
            chmod 700 "$VOLUME_MOUNTPOINT"
        else
            chown -R root:root "$VOLUME_MOUNTPOINT"
        fi
    fi
done

# Debug: List restored volumes
echo "Restored volumes:"
docker volume ls

# Cleanup
rm -rf "$RESTORE_DIR"
rm -f /root/.restic-pass

# Send completion notification
COMPLETION_MESSAGE="✅ *Volume initialization completed successfully!*
Initialized from snapshot: \`${SNAPSHOT_ID}\`"

send_notification "$COMPLETION_MESSAGE"
