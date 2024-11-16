#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    echo "Please either:"
    echo "1. Run './setup.sh' to configure your environment interactively, or"
    echo "2. Copy .env.example to .env and fill in your values manually"
    exit 1
fi

# Source environment variables
source .env

# Create build directory if it doesn't exist
mkdir -p build

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

# Create cloud-init.yaml from template
echo "Creating cloud-init.yaml..."
cat templates/cloud-init.yaml.template | \
    # Replace script placeholders
    sed "/{{BACKUP_VOLUMES_SCRIPT}}/c\\${BACKUP_VOLUMES_SCRIPT}" | \
    sed "/{{BACKUP_STATUS_SCRIPT}}/c\\${BACKUP_STATUS_SCRIPT}" | \
    sed "/{{TEST_TELEGRAM_SCRIPT}}/c\\${TEST_TELEGRAM_SCRIPT}" | \
    sed "/{{MOUNT_BACKUP_SCRIPT}}/c\\${MOUNT_BACKUP_SCRIPT}" | \
    sed "/{{RESTORE_VOLUMES_SCRIPT}}/c\\${RESTORE_VOLUMES_SCRIPT}" | \
    # Replace environment variables
    sed "s/{{POSTGRES_USER}}/${POSTGRES_USER}/g" | \
    sed "s/{{POSTGRES_PASSWORD}}/${POSTGRES_PASSWORD}/g" | \
    sed "s/{{POSTGRES_DB}}/${POSTGRES_DB}/g" | \
    sed "s/{{POSTGRES_NON_ROOT_USER}}/${POSTGRES_NON_ROOT_USER}/g" | \
    sed "s/{{POSTGRES_NON_ROOT_PASSWORD}}/${POSTGRES_NON_ROOT_PASSWORD}/g" | \
    sed "s/{{APP_ENV}}/${APP_ENV}/g" | \
    sed "s/{{APP_OPENSSL_KEY}}/${APP_OPENSSL_KEY}/g" | \
    sed "s/{{APP_DOMAIN}}/${APP_DOMAIN}/g" | \
    sed "s!{{SETUP_REPOSITORY}}!${SETUP_REPOSITORY}!g" | \
    sed "s/{{BACKUP_VOLUME_DEVICE}}/${BACKUP_VOLUME_DEVICE}/g" | \
    sed "s/{{BASEROW_SECRET_KEY}}/${BASEROW_SECRET_KEY}/g" | \
    sed "s/{{BASEROW_DB_PASSWORD}}/${BASEROW_DB_PASSWORD}/g" | \
    sed "s/{{QDRANT_API_KEY}}/${QDRANT_API_KEY}/g" | \
    sed "s/{{MINIO_ROOT_USER}}/${MINIO_ROOT_USER}/g" | \
    sed "s/{{MINIO_ROOT_PASSWORD}}/${MINIO_ROOT_PASSWORD}/g" | \
    sed "s/{{REDIS_PASSWORD}}/${REDIS_PASSWORD}/g" | \
    sed "s/{{KEYCLOAK_ADMIN}}/${KEYCLOAK_ADMIN}/g" | \
    sed "s/{{KEYCLOAK_ADMIN_PASSWORD}}/${KEYCLOAK_ADMIN_PASSWORD}/g" | \
    sed "s/{{KC_DB}}/${KC_DB}/g" | \
    sed "s/{{KC_DB_URL}}/${KC_DB_URL}/g" | \
    sed "s/{{KC_DB_USERNAME}}/${KC_DB_USERNAME}/g" | \
    sed "s/{{KC_DB_PASSWORD}}/${KC_DB_PASSWORD}/g" | \
    sed "s/{{KC_HOSTNAME}}/${KC_HOSTNAME}/g" | \
    sed "s/{{KC_PROXY}}/${KC_PROXY}/g" | \
    sed "s/{{RESTIC_PASSWORD}}/${RESTIC_PASSWORD}/g" | \
    sed "s/{{BACKUP_CRON}}/${BACKUP_CRON}/g" | \
    sed "s/{{TELEGRAM_BOT_TOKEN}}/${TELEGRAM_BOT_TOKEN}/g" | \
    sed "s/{{TELEGRAM_CHAT_ID}}/${TELEGRAM_CHAT_ID}/g" \
    > build/cloud-init.yaml

echo -e "${GREEN}✓ cloud-init.yaml has been generated in the build directory${NC}"