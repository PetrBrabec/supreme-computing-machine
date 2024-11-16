#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Handle Ctrl+C gracefully
trap 'echo -e "\n\nSetup cancelled"; exit 1' SIGINT

# Parse command line arguments
USE_DEFAULTS=false
while getopts "y" opt; do
    case $opt in
        y)
            USE_DEFAULTS=true
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# Function to generate a secure password
generate_password() {
    tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32 | tr -d '\n'
}

# Function to generate a hex key
generate_key() {
    hexdump -n 16 -e '4/4 "%08X" 1 "\n"' /dev/urandom | tr -d '\n'
}

# Function to prompt for value with default
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    local is_secret="${4:-false}"
    local value=""

    if [ "$USE_DEFAULTS" = true ]; then
        echo "$default"
        return
    fi

    if [ "$is_secret" = true ]; then
        read -p "$prompt [$default]: " -s value
        echo
    else
        read -p "$prompt [$default]: " value
    fi
    
    # If default is a command substitution (starts with $(...)), evaluate it only if no value provided
    if [ -z "$value" ] && [ "${default:0:2}" = '$(' ]; then
        eval "$default"
    else
        echo "${value:-$default}"
    fi
}

echo -e "${BLUE}🔧 Interactive Setup - The Setup${NC}"
echo "==============================="
echo
echo "This script will help you configure your environment."
echo "Press Enter to accept the default values or input your own."
echo

# Check if .env already exists
if [ -f .env ]; then
    read -p "An .env file already exists. Do you want to overwrite it? (y/N) " overwrite
    if [[ ! $overwrite =~ ^[Yy]$ ]]; then
        echo "Setup cancelled"
        exit 1
    fi
fi

# Domain Configuration
echo -e "\n${BLUE}Domain Configuration${NC}"
echo "-------------------"
DOMAIN=$(prompt_with_default "Enter your domain name" "example.com")
CADDY_ACME_EMAIL=$(prompt_with_default "Enter email for Let's Encrypt certificates" "admin@${DOMAIN}")

# Repository Configuration
echo -e "\n${BLUE}Repository Configuration${NC}"
echo "-----------------------"
SETUP_REPOSITORY=$(prompt_with_default "Enter the git repository URL" "https://github.com/PetrBrabec/the-setup.git")

# PostgreSQL Configuration
echo -e "\n${BLUE}PostgreSQL Configuration${NC}"
echo "----------------------"
POSTGRES_USER=$(prompt_with_default "PostgreSQL admin username" "postgres")
POSTGRES_PASSWORD=$(prompt_with_default "PostgreSQL admin password" "$(generate_password)" "POSTGRES_PASSWORD" true)
POSTGRES_DB=$(prompt_with_default "PostgreSQL initial database" "n8n")
POSTGRES_NON_ROOT_USER=$(prompt_with_default "PostgreSQL non-root username" "n8n")
POSTGRES_NON_ROOT_PASSWORD=$(prompt_with_default "PostgreSQL non-root password" "$(generate_password)" "POSTGRES_NON_ROOT_PASSWORD" true)

# Appwrite Configuration
echo -e "\n${BLUE}Appwrite Configuration${NC}"
echo "---------------------"
APP_ENV=$(prompt_with_default "Appwrite environment" "production")
APP_OPENSSL_KEY=$(prompt_with_default "Appwrite OpenSSL key" "$(generate_key)" "APP_OPENSSL_KEY" true)
APP_DOMAIN_TARGET=$(prompt_with_default "Appwrite domain target" "${DOMAIN}")

# Baserow Configuration
echo -e "\n${BLUE}Baserow Configuration${NC}"
echo "--------------------"
BASEROW_SECRET_KEY=$(prompt_with_default "Baserow secret key" "$(generate_key)")
BASEROW_DB_PASSWORD=$(prompt_with_default "Baserow database password" "$(generate_password)" "BASEROW_DB_PASSWORD" true)

# Qdrant Configuration
echo -e "\n${BLUE}Qdrant Configuration${NC}"
echo "------------------"
QDRANT_API_KEY=$(prompt_with_default "Qdrant API key" "$(generate_key)")

# Minio Configuration
echo -e "\n${BLUE}Minio Configuration${NC}"
echo "-----------------"
MINIO_ROOT_USER=$(prompt_with_default "Minio root username" "admin")
MINIO_ROOT_PASSWORD=$(prompt_with_default "Minio root password" "$(generate_password)" "MINIO_ROOT_PASSWORD" true)

# Redis Configuration
echo -e "\n${BLUE}Redis Configuration${NC}"
echo "-----------------"
REDIS_PASSWORD=$(prompt_with_default "Redis password" "$(generate_password)" "REDIS_PASSWORD" true)

# Keycloak Configuration
echo -e "\n${BLUE}Keycloak Configuration${NC}"
echo "--------------------"
KEYCLOAK_ADMIN=$(prompt_with_default "Keycloak admin username" "admin")
KEYCLOAK_ADMIN_PASSWORD=$(prompt_with_default "Keycloak admin password" "$(generate_password)" "KEYCLOAK_ADMIN_PASSWORD" true)
KC_DB_USERNAME=$(prompt_with_default "Keycloak database username" "keycloak")
KC_DB_PASSWORD=$(prompt_with_default "Keycloak database password" "$(generate_password)" "KC_DB_PASSWORD" true)

# Backup Configuration
echo -e "\n${BLUE}Backup Configuration${NC}"
echo "--------------------"
RESTIC_PASSWORD=$(prompt_with_default "Restic backup password" "$(generate_password)" "RESTIC_PASSWORD" true)
BACKUP_CRON=$(prompt_with_default "Backup cron schedule" "0 3 * * *")
BACKUP_VOLUME_DEVICE=$(prompt_with_default "Backup volume device" "/dev/sdb")

# Telegram Configuration
echo -e "\n${BLUE}Telegram Configuration${NC}"
echo "---------------------"
echo "To set up Telegram notifications:"
echo "1. Create a bot with @BotFather"
echo "2. Get the bot token"
echo "3. Start a chat with your bot"
echo "4. Get your chat ID from https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates"
echo
TELEGRAM_BOT_TOKEN=$(prompt_with_default "Telegram bot token" "your_bot_token")
TELEGRAM_CHAT_ID=$(prompt_with_default "Telegram chat ID" "your_chat_id")

cat > .env << EOF
# Domain Configuration
APP_DOMAIN=${DOMAIN}
CADDY_ACME_EMAIL=${CADDY_ACME_EMAIL}

# Repository Configuration
SETUP_REPOSITORY=${SETUP_REPOSITORY}

# PostgreSQL Configuration
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=${POSTGRES_DB}
POSTGRES_NON_ROOT_USER=${POSTGRES_NON_ROOT_USER}
POSTGRES_NON_ROOT_PASSWORD=${POSTGRES_NON_ROOT_PASSWORD}

# Appwrite Configuration
APP_ENV=${APP_ENV}
APP_OPENSSL_KEY=${APP_OPENSSL_KEY}
APP_DOMAIN_TARGET=${DOMAIN}

# Baserow Configuration
BASEROW_SECRET_KEY=${BASEROW_SECRET_KEY}
BASEROW_DB_PASSWORD=${BASEROW_DB_PASSWORD}

# Qdrant Configuration
QDRANT_API_KEY=${QDRANT_API_KEY}

# Minio Configuration
MINIO_ROOT_USER=${MINIO_ROOT_USER}
MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}

# Redis Configuration
REDIS_PASSWORD=${REDIS_PASSWORD}

# Keycloak Configuration
KEYCLOAK_ADMIN=${KEYCLOAK_ADMIN}
KEYCLOAK_ADMIN_PASSWORD=${KEYCLOAK_ADMIN_PASSWORD}
KC_DB=postgres
KC_DB_URL=jdbc:postgresql://postgres:5432/keycloak
KC_DB_USERNAME=${KC_DB_USERNAME}
KC_DB_PASSWORD=${KC_DB_PASSWORD}
KC_HOSTNAME=${DOMAIN}
KC_PROXY=edge

# Backup Configuration
RESTIC_PASSWORD=${RESTIC_PASSWORD}
BACKUP_CRON=${BACKUP_CRON}
BACKUP_VOLUME_DEVICE=${BACKUP_VOLUME_DEVICE}
TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
TELEGRAM_CHAT_ID=${TELEGRAM_CHAT_ID}
EOF

echo -e "\n${GREEN}✓ Configuration complete!${NC}"
echo
echo "Your environment has been configured and saved to .env"
echo
echo "Next steps:"
echo "1. Review the .env file and make any necessary adjustments"
echo "2. Run './build.sh' to generate your cloud-init configuration"
echo "3. Use the generated configuration to deploy your server"
echo
echo "To test your configuration:"
echo "./test-setup.sh"
