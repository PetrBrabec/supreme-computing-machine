#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Handle Ctrl+C gracefully
trap 'echo -e "\n\nSetup cancelled by user"; exit 1' SIGINT

# Check for existing .env file
if [ -f .env ]; then
    echo -e "\n${RED}Error: .env file already exists${NC}"
    echo "To reconfigure, please:"
    echo "1. Remove the existing .env file: rm .env"
    echo "2. Run this script again"
    exit 1
fi

# Function to generate a secure password
generate_password() {
    openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32
}

# Function to generate a hex key
generate_key() {
    hexdump -n 16 -e '4/4 "%08X" 1 "\n"' /dev/urandom | tr -d '\n'
}

# Function to get value from .default.env
get_default_value() {
    local var_name=$1
    if [ -f .default.env ]; then
        # Use grep with word boundaries to ensure exact variable name match
        local value=$(grep "^${var_name}=" .default.env | cut -d'=' -f2-)
        # Only return non-empty values
        if [ -n "$value" ] && [ "$value" != "your_bot_token" ] && [ "$value" != "your_chat_id" ]; then
            echo "$value"
        fi
    fi
}

# Function to prompt for value with default
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    local is_secret="${4:-false}"
    local value=""

    # Check .default.env first
    local default_value=$(get_default_value "$var_name")
    if [ -n "$default_value" ]; then
        echo "$default_value"
        return
    fi

    # If domain is provided or AUTO_YES is set, use defaults or generate passwords
    if [ -n "$DOMAIN" ] || [ "$AUTO_YES" = true ]; then
        if [ "$is_secret" = true ]; then
            generate_password
        elif [[ "$default" == \$\(generate_key\) ]]; then
            generate_key
        else
            # For domain-based values, use DOMAIN from .default.env if available
            if [[ "$default" == *"DOMAIN"* ]]; then
                default_domain=$(get_default_value "DOMAIN")
                if [ -n "$default_domain" ]; then
                    echo "${default/DOMAIN/$default_domain}"
                    return
                fi
            fi
            echo "$default"
        fi
        return
    fi

    if [ "$is_secret" = true ]; then
        read -p "$prompt [$default]: " -s value
        echo
    else
        read -p "$prompt [$default]: " value
    fi
    
    if [[ -z "$value" && "$default" == \$\(* ]]; then
        eval "$default"
    else
        echo "${value:-$default}"
    fi
}

# Parse command line arguments
while getopts "d:y" opt; do
    case $opt in
        d)
            DOMAIN="$OPTARG"
            ;;
        y)
            AUTO_YES=true
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# If no domain provided and .default.env exists, use it as a base
if [ -z "$DOMAIN" ] && [ -f .default.env ]; then
    echo -e "${BLUE}Using .default.env as template and generating missing values${NC}"
    DOMAIN=$(get_default_value "DOMAIN")
fi

# Require domain parameter if .default.env doesn't exist and no domain provided
if [ -z "$DOMAIN" ]; then
    echo -e "${RED}Error: Domain is required. Please use -d option to specify the domain (e.g., -d example.com)${NC}"
    echo -e "Alternatively, create a .default.env file to use as template"
    exit 1
fi

echo -e "${BLUE}🔧 Interactive Setup - The Setup${NC}"
echo "==============================="
if [ -n "$DOMAIN" ] || [ "$AUTO_YES" = true ]; then
    echo -e "Running in automatic mode"
    echo -e "Domain: ${GREEN}$DOMAIN${NC}"
    [ -f .default.env ] && echo -e "Using values from ${GREEN}.default.env${NC}"
    echo -e "Missing values will be generated automatically"
fi
echo

# Domain-based variables
APP_DOMAIN=$(prompt_with_default "Enter app domain" "$DOMAIN" "APP_DOMAIN")
KC_HOSTNAME=$(prompt_with_default "Enter Keycloak hostname" "auth.$DOMAIN" "KC_HOSTNAME")
APP_DOMAIN_TARGET=$(prompt_with_default "Enter app domain target" "appwrite.$DOMAIN" "APP_DOMAIN_TARGET")

# Critical Configuration (shown at the top of .env)
echo -e "\n${BLUE}Email Configuration${NC}"
echo "==================="
CADDY_ACME_EMAIL=$(prompt_with_default "Enter email for SSL certificates" "admin@$DOMAIN" "CADDY_ACME_EMAIL")

echo -e "\n${BLUE}Repository Configuration${NC}"
echo "====================="
SETUP_REPOSITORY=$(prompt_with_default "Enter the git repository URL" "https://github.com/PetrBrabec/supreme-computing-machine.git")

# Database Configuration
echo -e "\n${BLUE}Database Configuration${NC}"
echo "====================="
POSTGRES_USER=$(prompt_with_default "PostgreSQL admin username" "postgres")
POSTGRES_PASSWORD=$(prompt_with_default "PostgreSQL admin password" "$(generate_password)" "POSTGRES_PASSWORD" true)
POSTGRES_DB=$(prompt_with_default "PostgreSQL initial database" "n8n")
POSTGRES_NON_ROOT_USER=$(prompt_with_default "PostgreSQL non-root username" "n8n")
POSTGRES_NON_ROOT_PASSWORD=$(prompt_with_default "PostgreSQL non-root password" "$(generate_password)" "POSTGRES_NON_ROOT_PASSWORD" true)

BASEROW_SECRET_KEY=$(prompt_with_default "Baserow secret key" "$(generate_key)")
BASEROW_DB_PASSWORD=$(prompt_with_default "Baserow database password" "$(generate_password)" "BASEROW_DB_PASSWORD" true)

# Keycloak Configuration
echo -e "\n${BLUE}Keycloak Configuration${NC}"
echo "====================="
KEYCLOAK_ADMIN=$(prompt_with_default "Keycloak admin username" "admin")
KEYCLOAK_ADMIN_PASSWORD=$(prompt_with_default "Keycloak admin password" "$(generate_password)" "KEYCLOAK_ADMIN_PASSWORD" true)
KC_DB=$(prompt_with_default "Keycloak database name" "keycloak")
KC_DB_URL=$(prompt_with_default "Keycloak database URL" "jdbc:postgresql://postgres/$KC_DB")
KC_DB_USERNAME=$(prompt_with_default "Keycloak database username" "keycloak")
KC_DB_PASSWORD=$(prompt_with_default "Keycloak database password" "$(generate_password)" "KC_DB_PASSWORD" true)
KC_PROXY=$(prompt_with_default "Keycloak proxy mode" "edge")

# Backup Configuration
echo -e "\n${BLUE}Backup Configuration${NC}"
echo "====================="
BACKUP_VOLUME_PATH=$(prompt_with_default "Enter Hetzner volume path" "/dev/disk/by-id/scsi-0HC_Volume_101626985" "BACKUP_VOLUME_PATH")
BACKUP_MOUNT_POINT=$(prompt_with_default "Enter backup mount point" "/mnt/volume-scm-backup" "BACKUP_MOUNT_POINT")
RESTIC_PASSWORD=$(prompt_with_default "Restic backup password" "$(generate_password)" "RESTIC_PASSWORD" true)
BACKUP_CRON=$(prompt_with_default "Enter backup cron schedule" "0 2 * * *" "BACKUP_CRON")
RESTIC_REPOSITORY=$(prompt_with_default "Enter restic repository path" "$BACKUP_MOUNT_POINT/restic-repo" "RESTIC_REPOSITORY")

# Other Services Configuration
echo -e "\n${BLUE}Other Services Configuration${NC}"
echo "=========================="
APP_ENV=$(prompt_with_default "Appwrite environment" "production")
APP_OPENSSL_KEY=$(prompt_with_default "Appwrite OpenSSL key" "$(generate_key)")

QDRANT_API_KEY=$(prompt_with_default "Qdrant API key" "$(generate_key)")

MINIO_ROOT_USER=$(prompt_with_default "MinIO root username" "admin")
MINIO_ROOT_PASSWORD=$(prompt_with_default "MinIO root password" "$(generate_password)" "MINIO_ROOT_PASSWORD" true)

REDIS_PASSWORD=$(prompt_with_default "Redis password" "$(generate_password)" "REDIS_PASSWORD" true)

# Telegram Configuration
echo -e "\n${BLUE}Telegram Configuration${NC}"
echo "====================="
TELEGRAM_BOT_TOKEN=$(prompt_with_default "Telegram bot token" "your_bot_token" "TELEGRAM_BOT_TOKEN")
TELEGRAM_CHAT_ID=$(prompt_with_default "Telegram chat ID" "your_chat_id" "TELEGRAM_CHAT_ID")

# Generate .env file
cat > .env << EOL
# Critical Configuration
DOMAIN=${DOMAIN}
CADDY_ACME_EMAIL=${CADDY_ACME_EMAIL}
SETUP_REPOSITORY=${SETUP_REPOSITORY}

# Database Credentials
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=${POSTGRES_DB}
POSTGRES_NON_ROOT_USER=${POSTGRES_NON_ROOT_USER}
POSTGRES_NON_ROOT_PASSWORD=${POSTGRES_NON_ROOT_PASSWORD}

# Keycloak Configuration
KEYCLOAK_ADMIN=${KEYCLOAK_ADMIN}
KEYCLOAK_ADMIN_PASSWORD=${KEYCLOAK_ADMIN_PASSWORD}
KC_DB=${KC_DB}
KC_DB_URL=${KC_DB_URL}
KC_DB_USERNAME=${KC_DB_USERNAME}
KC_DB_PASSWORD=${KC_DB_PASSWORD}
KC_HOSTNAME=${KC_HOSTNAME}
KC_PROXY=${KC_PROXY}

# Backup Configuration
RESTIC_PASSWORD=${RESTIC_PASSWORD}
BACKUP_CRON=${BACKUP_CRON}
BACKUP_VOLUME_PATH=${BACKUP_VOLUME_PATH}
BACKUP_MOUNT_POINT=${BACKUP_MOUNT_POINT}
RESTIC_REPOSITORY=${RESTIC_REPOSITORY}

# Telegram Notifications
TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
TELEGRAM_CHAT_ID=${TELEGRAM_CHAT_ID}

# Service Endpoints
APP_DOMAIN=${APP_DOMAIN}
APP_DOMAIN_TARGET=${APP_DOMAIN_TARGET}

# Baserow Configuration
BASEROW_SECRET_KEY=${BASEROW_SECRET_KEY}
BASEROW_DB_PASSWORD=${BASEROW_DB_PASSWORD}

# Appwrite Configuration
APP_ENV=${APP_ENV}
APP_OPENSSL_KEY=${APP_OPENSSL_KEY}

# Qdrant Configuration
QDRANT_API_KEY=${QDRANT_API_KEY}

# Minio Configuration
MINIO_ROOT_USER=${MINIO_ROOT_USER}
MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}

# Redis Configuration
REDIS_PASSWORD=${REDIS_PASSWORD}
EOL

echo -e "\n${GREEN}Configuration complete! .env file has been generated.${NC}"
echo -e "Domain configured as: ${BLUE}$DOMAIN${NC}"
echo -e "Services will be available at:"
echo -e "- Appwrite: ${BLUE}appwrite.$DOMAIN${NC}"
echo -e "- n8n: ${BLUE}n8n.$DOMAIN${NC}"
echo -e "- Baserow: ${BLUE}baserow.$DOMAIN${NC}"
echo -e "- Qdrant: ${BLUE}qdrant.$DOMAIN${NC}"
echo -e "- MinIO API: ${BLUE}s3.$DOMAIN${NC}"
echo -e "- MinIO Console: ${BLUE}minio.$DOMAIN${NC}"
echo -e "- Keycloak: ${BLUE}auth.$DOMAIN${NC}"
