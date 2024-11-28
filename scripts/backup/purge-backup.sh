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
    send_notification "❌ *Backup Clear Failed*

Error: ${1}"
    exit 1
}

# Set up error handling
trap 'handle_error "Unexpected error occurred"' ERR

# Start notification
send_notification "🔄 *Purging backup volume*
volume: `${BACKUP_VOLUME_PATH}`"

# Check if backup volume is mounted
if ! mountpoint -q /mnt/backup; then
    handle_error "Backup volume is not mounted at /mnt/backup"
fi

# Clear the backup volume
echo "Clearing backup volume at /mnt/backup..."
rm -rf /mnt/backup/*

# Send completion notification
send_notification "✅ *Backup volume purged*"
