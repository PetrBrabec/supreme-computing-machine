#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <snapshot-id>"
  echo "Available snapshots:"
  restic -r /mnt/backup/restic-repo snapshots
  exit 1
fi

SNAPSHOT_ID=$1
RESTORE_DIR="/mnt/backup/restore_${SNAPSHOT_ID}"

# Source environment variables
source /root/.env

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Function to send notification
send_notification() {
    "${SCRIPT_DIR}/notify.sh" "$1"
}

# Error handling function
handle_error() {
    send_notification "❌ *Restore Failed*

Error: ${1}
Host: \`$(hostname)\`"
    
    # Try to restart services if they're down
    cd /root
    docker compose up -d
    
    exit 1
}

# Set up error handling
trap 'handle_error "Unexpected error occurred"' ERR

# Start restore notification
send_notification "*🔄 Starting volume restore...*
Snapshot: \`${SNAPSHOT_ID}\`"

# Restore from restic
restic -r /mnt/backup/restic-repo restore $SNAPSHOT_ID --target "$RESTORE_DIR"

# Stop services
cd /root
docker compose down

# Restore each volume
for VOLUME_DIR in "$RESTORE_DIR"/docker-volumes/*/; do
  VOLUME_NAME=$(basename "$VOLUME_DIR")
  echo "Restoring volume: $VOLUME_NAME"
  docker run --rm \
    -v $VOLUME_NAME:/target \
    -v "$VOLUME_DIR":/backup \
    ubuntu bash -c "cd /target && tar xzf /backup/data.tar.gz"
done

# Restart services
docker compose up -d

# Cleanup
rm -rf "$RESTORE_DIR"

# Send completion notification
COMPLETION_MESSAGE="✅ *Volume restore completed successfully!*

Restored from snapshot: \`${SNAPSHOT_ID}\`
Host: \`$(hostname)\`"

send_notification "$COMPLETION_MESSAGE"
