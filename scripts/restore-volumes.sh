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

# Function to send Telegram notification
send_notification() {
    if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
        curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
             -d "chat_id=${TELEGRAM_CHAT_ID}" \
             -d "text=${1}" \
             -d "parse_mode=Markdown"
    fi
}

# Error handling function
handle_error() {
    local error_message="❌ *Restore Failed*

Error: ${1}
Time: \`$(date)\`
Host: \`$(hostname)\`"
    
    send_notification "$error_message"
    
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
Time: \`$(date)\`
Host: \`$(hostname)\`"

send_notification "$COMPLETION_MESSAGE"
