#!/bin/bash

# Source environment variables
source /root/.env

if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
    echo "Error: TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID must be set in .env"
    echo
    echo "To set up Telegram notifications:"
    echo "1. Create a bot with @BotFather on Telegram"
    echo "2. Get the bot token from BotFather"
    echo "3. Start a chat with your bot"
    echo "4. Get your chat ID by visiting:"
    echo "   https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates"
    echo
    echo "Then update your .env file with:"
    echo "TELEGRAM_BOT_TOKEN=your_bot_token"
    echo "TELEGRAM_CHAT_ID=your_chat_id"
    exit 1
fi

# Test message
TEST_MESSAGE="🔧 *Backup System Test*

This is a test message from your backup system.

*System Info:*
🖥️ Host: \`$(hostname)\`
📅 Time: \`$(date)\`
💾 Volume: \`$BACKUP_VOLUME_DEVICE\`"

# Send test message
curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
     -d "chat_id=${TELEGRAM_CHAT_ID}" \
     -d "text=${TEST_MESSAGE}" \
     -d "parse_mode=Markdown"

if [ $? -eq 0 ]; then
    echo "✅ Test message sent successfully!"
    echo "Check your Telegram for the message."
else
    echo "❌ Failed to send test message."
    echo "Please verify your bot token and chat ID."
fi
