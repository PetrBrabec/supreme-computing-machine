#!/bin/bash

# Source environment variables
source /root/supreme-computing-machine/.env

# Set and export required environment variables for restic
echo "$RESTIC_PASSWORD" > /root/.restic-pass
chmod 600 /root/.restic-pass
export RESTIC_PASSWORD_FILE=/root/.restic-pass

# Get script directory
SCRIPT_DIR="/root/supreme-computing-machine/scripts"

# Function to send Telegram notification
send_notification() {
    "${SCRIPT_DIR}/notify.sh" "$1"
}

# Error handling function
handle_error() {
    local error_message="❌ *Backup Failed*

Error: ${1}"
    
    send_notification "$error_message"
    
    # Try to restart services if they're down
    cd /root/supreme-computing-machine
    /usr/bin/docker compose up -d
    
    exit 1
}

# Set up error handling
trap 'handle_error "Unexpected error occurred"' ERR

# Start backup notification
send_notification "🔄 *Starting backup*"

# Initialize restic repository if not already initialized
if [ ! -f "${RESTIC_REPOSITORY}/config" ]; then
    echo "Initializing restic repository at ${RESTIC_REPOSITORY}"
    /usr/bin/restic init \
        -r "$RESTIC_REPOSITORY" \
        --password-file /root/.restic-pass
fi

# Get list of volumes
VOLUMES=$(/usr/bin/docker volume ls --format '{{.Name}}')

# Stop services for consistent backup
cd /root/supreme-computing-machine
/usr/bin/docker compose down

# Backup to restic repository
echo "Creating restic backup..."
SNAPSHOT_ID=$(/usr/bin/restic \
    -r "$RESTIC_REPOSITORY" \
    --password-file /root/.restic-pass \
    backup /var/lib/docker/volumes | grep 'snapshot' | awk '{print $3}')

# Keep last 7 daily, 4 weekly, and 3 monthly backups
echo "Pruning old backups..."
/usr/bin/restic \
    -r "$RESTIC_REPOSITORY" \
    --password-file /root/.restic-pass \
    forget \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 3 \
    --prune

# Restart services
/usr/bin/docker compose up -d

# Show available snapshots for debugging
echo "Available snapshots:"
/usr/bin/restic \
    -r "$RESTIC_REPOSITORY" \
    --password-file /root/.restic-pass \
    snapshots

# Generate status report
STATUS_REPORT=$(${SCRIPT_DIR}/backup/backup-status.sh)

# Format status report for Telegram
TELEGRAM_REPORT="✅ *Backup completed successfully!*
Latest snapshot ID: \`$SNAPSHOT_ID\`

\`\`\`
$STATUS_REPORT
\`\`\`"

# Send completion notification with status
send_notification "$TELEGRAM_REPORT"

# Clean up password file
rm -f /root/.restic-pass