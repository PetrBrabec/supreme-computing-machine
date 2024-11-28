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
    send_notification "⚠ *No snapshots found - starting fresh*"
    rm -f /root/.restic-pass
    exit 0
fi

# Get the latest snapshot ID
SNAPSHOT_ID=$(restic -r "$RESTIC_REPOSITORY" --password-file /root/.restic-pass snapshots | grep '^[a-f0-9]\{8\}' | tail -n1 | awk '{print $1}')
if [ -z "$SNAPSHOT_ID" ]; then
    echo "No valid snapshot ID found - starting fresh"
    rm -f /root/.restic-pass
    exit 0
fi

# Start init notification
send_notification "🔄 *Initializing* (snapshot: \`${SNAPSHOT_ID}\`)"

# Clean up existing volumes
rm -rf /var/lib/docker/volumes/*

# Restore volumes directly from restic
restic -r "$RESTIC_REPOSITORY" --password-file /root/.restic-pass restore "$SNAPSHOT_ID" --target /

# Clean up
rm -f /root/.restic-pass

# Send completion notification
COMPLETION_MESSAGE="✅ *Initialization successful* (snapshot: \`${SNAPSHOT_ID}\`)"

send_notification "$COMPLETION_MESSAGE"
