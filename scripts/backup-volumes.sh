#!/bin/bash

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
    local error_message="❌ *Backup Failed*

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

# Start backup notification
send_notification "*🔄 Starting backup process...*"

# Initialize restic repository if not already initialized
if [ ! -f /mnt/backup/restic-repo/config ]; then
    restic init --repo /mnt/backup/restic-repo
fi

# Get list of volumes
VOLUMES=$(docker volume ls --format '{{.Name}}')

# Create backup directory
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/mnt/backup/docker-volumes/$BACKUP_DATE"
mkdir -p "$BACKUP_DIR"

# Stop services for consistent backup
cd /root
docker compose down

# Backup each volume
for VOLUME in $VOLUMES; do
    echo "Backing up volume: $VOLUME"
    mkdir -p "$BACKUP_DIR/$VOLUME"
    docker run --rm \
        -v $VOLUME:/source:ro \
        -v "$BACKUP_DIR/$VOLUME":/backup \
        ubuntu tar czf /backup/data.tar.gz -C /source .
done

# Restart services
docker compose up -d

# Backup to restic repository
SNAPSHOT_ID=$(restic -r /mnt/backup/restic-repo backup /mnt/backup/docker-volumes | grep 'snapshot' | awk '{print $2}')

# Keep last 7 daily, 4 weekly, and 3 monthly backups
restic -r /mnt/backup/restic-repo forget \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 3 \
    --prune

# Clean up old direct volume backups (keep last 3)
cd /mnt/backup/docker-volumes
ls -t | tail -n +4 | xargs -r rm -rf

# Generate status report
STATUS_REPORT=$(RESTIC_PASSWORD=$RESTIC_PASSWORD /root/backup-status.sh)

# Format status report for Telegram
TELEGRAM_REPORT="✅ *Backup completed successfully!*
Latest snapshot ID: \`$SNAPSHOT_ID\`

\`\`\`
$STATUS_REPORT
\`\`\`"

# Send completion notification with status
send_notification "$TELEGRAM_REPORT"
