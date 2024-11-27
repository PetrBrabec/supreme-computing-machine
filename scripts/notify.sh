#!/bin/bash

# Get environment variables
source /root/supreme-computing-machine/.env

# Function to send telegram message
send_telegram_message() {
    local message="$1"
    local hostname=$(hostname | sed -e 's/^supreme-computing-//')
    local formatted_message="🖥️ *$hostname* - $message"
    
    curl -s -X POST \
        "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${formatted_message}" \
        -d "parse_mode=Markdown" > /dev/null
}

# If message is provided as argument, send it
if [ -n "$1" ]; then
    send_telegram_message "$1"
fi
