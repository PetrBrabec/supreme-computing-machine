#!/bin/bash

# Stay in the repository root directory
cd "$(dirname "$0")/.."

# Source environment variables
if [ -f .env ]; then
    source .env
elif [ -f /root/.env ]; then
    source /root/.env
    cp /root/.env .env
else
    echo "No .env file found"
    exit 1
fi

# Function to send notification with logs
send_notification() {
    local status=$1
    local message=$2
    local logs=$3
    
    if [ -n "$logs" ]; then
        # Truncate logs if too long (Telegram has a 4096 character limit)
        logs=$(echo "$logs" | tail -c 3500)
        ./scripts/notify.sh "$message\n\nLogs:\n\`\`\`\n$logs\n\`\`\`"
    else
        ./scripts/notify.sh "$message"
    fi
}

# Pull images
echo "Pulling Docker images..."
if ! docker compose pull; then
    send_notification "error" "❌ Failed to pull Docker images"
    exit 1
fi

# Start services
echo "Starting services..."
if ! docker compose up -d; then
    # Collect logs from failed services
    logs=$(docker compose logs --tail=50)
    send_notification "error" "❌ Failed to start services" "$logs"
    exit 1
fi

send_notification "success" "✅ Services started successfully"
