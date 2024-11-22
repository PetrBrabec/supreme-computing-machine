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
    send_notification "❌ *Restore Failed*

Error: ${1}"
    
    # Try to restart services if they're down
    cd /root/supreme-computing-machine
    docker compose up -d
    
    exit 1
}

# Set up error handling
trap 'handle_error "Unexpected error occurred"' ERR

# Create password file for restic
echo "$RESTIC_PASSWORD" > /root/.restic-pass
chmod 600 /root/.restic-pass

# Check if a snapshot ID was provided or get latest
if [ -z "$1" ]; then
    # Check if any snapshots exist
    SNAPSHOTS=$(restic -r "$RESTIC_REPOSITORY" --password-file /root/.restic-pass snapshots)
    if [ $? -ne 0 ] || [ -z "$SNAPSHOTS" ]; then
        echo "No snapshots found in repository"
        rm -f /root/.restic-pass
        exit 0
    fi
    
    # Get the latest snapshot ID
    SNAPSHOT_ID=$(echo "$SNAPSHOTS" | grep "^[a-z0-9]\+" | head -n1 | cut -d' ' -f1)
    if [ -z "$SNAPSHOT_ID" ]; then
        echo "No valid snapshot ID found"
        rm -f /root/.restic-pass
        exit 1
    fi
    echo "Using latest snapshot: $SNAPSHOT_ID"
else
    SNAPSHOT_ID=$1
fi

RESTORE_DIR="/mnt/backup/restore_${SNAPSHOT_ID}"

# Start restore notification
send_notification "*🔄 Starting volume restore...*
Snapshot: \`${SNAPSHOT_ID}\`"

# Restore from restic
restic -r "$RESTIC_REPOSITORY" --password-file /root/.restic-pass restore "$SNAPSHOT_ID" --target "$RESTORE_DIR"

# Stop services
cd /root/supreme-computing-machine
docker compose down

# Restore each volume
for VOLUME_DIR in "$RESTORE_DIR"/docker-volumes/*/; do
    if [ -d "$VOLUME_DIR" ]; then
        VOLUME_NAME=$(basename "$VOLUME_DIR")
        echo "Restoring volume: $VOLUME_NAME"
        docker volume create "$VOLUME_NAME" || true
        docker run --rm \
            -v "$VOLUME_NAME":/target \
            -v "$VOLUME_DIR":/backup \
            ubuntu bash -c "rm -rf /target/* && cp -a /backup/. /target/ && chown -R root:root /target"
    fi
done

# Restart services
docker compose up -d

# Cleanup
rm -rf "$RESTORE_DIR"
rm -f /root/.restic-pass

# Send completion notification
COMPLETION_MESSAGE="✅ *Volume restore completed successfully!*

Restored from snapshot: \`${SNAPSHOT_ID}\`"

send_notification "$COMPLETION_MESSAGE"
