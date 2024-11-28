#!/bin/bash
set -e

# Source environment variables
source /root/supreme-computing-machine/.env

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"

# Function to send notification
send_notification() {
    "${SCRIPT_DIR}/scripts/notify.sh" "$1"
}

# Error handling function
handle_error() {
    send_notification "❌ *Backup Purge Failed*

Error: ${1}"
    exit 1
}

# Set up error handling
trap 'handle_error "Unexpected error occurred"' ERR

# Start notification
send_notification "🔄 *Purging backup volume*"

# Check if backup volume is mounted
if ! mountpoint -q /mnt/backup; then
    handle_error "Backup volume is not mounted at /mnt/backup"
fi

# Get the device path
DEVICE=$(findmnt -n -o SOURCE /mnt/backup)
if [ -z "$DEVICE" ]; then
    handle_error "Could not find device for /mnt/backup"
fi

# Unmount the volume
echo "Unmounting backup volume..."
umount /mnt/backup

# Wait for the device to be fully unmounted
sleep 2

# Verify it's unmounted
if mountpoint -q /mnt/backup; then
    handle_error "Failed to unmount backup volume"
fi

# Zero out the first 100MB of the volume (enough to clear the filesystem)
echo "Zeroing backup volume..."
dd if=/dev/zero of="$DEVICE" bs=1M count=100 status=progress

# Create new filesystem
echo "Creating new filesystem..."
mkfs.ext4 "$DEVICE"

# Mount the volume back
echo "Mounting backup volume..."
mount "$DEVICE" /mnt/backup

# Ensure mounted successfully
if ! mountpoint -q /mnt/backup; then
    handle_error "Failed to mount backup volume after formatting"
fi

# Send completion notification
send_notification "✅ *Backup volume purged*"
