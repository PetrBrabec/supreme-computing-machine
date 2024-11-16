#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m'

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    echo "Please either:"
    echo "1. Run './setup.sh' to configure your environment interactively, or"
    echo "2. Copy .env.example to .env and fill in your values manually"
    exit 1
fi

# Create build directory if it doesn't exist
mkdir -p build

echo "Creating cloud-init.yaml..."

# Load and export environment variables
set -a
source .env
set +a

# Function to escape script content for yaml
escape_script() {
    echo "      |"
    sed 's/^/      /' "$1"
}

# Read script contents
BACKUP_VOLUMES_SCRIPT=$(escape_script scripts/backup-volumes.sh)
BACKUP_STATUS_SCRIPT=$(escape_script scripts/backup-status.sh)
TEST_TELEGRAM_SCRIPT=$(escape_script scripts/test-telegram.sh)
MOUNT_BACKUP_SCRIPT=$(escape_script scripts/mount-backup-volume.sh)
RESTORE_VOLUMES_SCRIPT=$(escape_script scripts/restore-volumes.sh)

# Read the template and perform substitutions
cat templates/cloud-init.yaml.template | \
envsubst '${DOMAIN}
${CADDY_ACME_EMAIL}
${SETUP_REPOSITORY}
${POSTGRES_USER}
${POSTGRES_PASSWORD}
${POSTGRES_DB}
${POSTGRES_NON_ROOT_USER}
${POSTGRES_NON_ROOT_PASSWORD}
${APP_ENV}
${APP_OPENSSL_KEY}
${APP_DOMAIN}
${APP_DOMAIN_TARGET}
${BASEROW_SECRET_KEY}
${BASEROW_DB_PASSWORD}
${QDRANT_API_KEY}
${MINIO_ROOT_USER}
${MINIO_ROOT_PASSWORD}
${REDIS_PASSWORD}
${KEYCLOAK_ADMIN}
${KEYCLOAK_ADMIN_PASSWORD}
${KC_DB}
${KC_DB_URL}
${KC_DB_USERNAME}
${KC_DB_PASSWORD}
${KC_HOSTNAME}
${KC_PROXY}
${RESTIC_PASSWORD}
${BACKUP_CRON}
${BACKUP_VOLUME_DEVICE}
${TELEGRAM_BOT_TOKEN}
${TELEGRAM_CHAT_ID}
${BACKUP_VOLUMES_SCRIPT}
${BACKUP_STATUS_SCRIPT}
${TEST_TELEGRAM_SCRIPT}
${MOUNT_BACKUP_SCRIPT}
${RESTORE_VOLUMES_SCRIPT}' > build/cloud-init.yaml

echo -e "${GREEN}✓ cloud-init.yaml has been generated in the build directory${NC}"