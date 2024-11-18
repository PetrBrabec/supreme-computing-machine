#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Create build directory if it doesn't exist
mkdir -p build

echo "Creating cloud-init.yaml..."

# Load and export environment variables
set -a
source .env

# Set default values for missing variables
# Critical Configuration
: ${DOMAIN:=localhost}
: ${CADDY_ACME_EMAIL:=admin@localhost}
: ${SETUP_REPOSITORY:=https://github.com/PetrBrabec/supreme-computing-machine.git}

# PostgreSQL Configuration
: ${POSTGRES_HOST:=postgres}
: ${POSTGRES_PORT:=5432}
: ${POSTGRES_USER:=postgres}
: ${POSTGRES_PASSWORD:=}

# N8N Database Configuration
: ${N8N_DB_USER:=n8n}
: ${N8N_DB_PASSWORD:=}

# Baserow Database Configuration
: ${BASEROW_DB_USER:=baserow}
: ${BASEROW_DB_PASSWORD:=}

# Keycloak Database Configuration
: ${KC_DB_USERNAME:=keycloak}
: ${KC_DB_PASSWORD:=}

# Appwrite Configuration
: ${APPWRITE_ENV:=production}
: ${APPWRITE_OPENSSL_KEY:=$(hexdump -n 16 -e '4/4 "%08X" 1 "\n"' /dev/urandom | tr -d '\n')}
: ${APPWRITE_DOMAIN:=appwrite.$DOMAIN}
: ${APPWRITE_DOMAIN_TARGET:=$DOMAIN}

# Minio Configuration
: ${MINIO_ROOT_USER:=admin}
: ${MINIO_ROOT_PASSWORD:=}

# Redis Configuration
: ${REDIS_PASSWORD:=}

# Backup Configuration
: ${BACKUP_CRON:=0 3 * * *}
: ${BACKUP_MOUNT_POINT:=/mnt/volume-scm-backup}
: ${BACKUP_VOLUME_PATH:=}
: ${RESTIC_PASSWORD:=}
: ${RESTIC_REPOSITORY:=/mnt/volume-scm-backup/restic-repo}

# Telegram Configuration
: ${TELEGRAM_BOT_TOKEN:=}
: ${TELEGRAM_CHAT_ID:=}

# Qdrant Configuration
: ${QDRANT_API_KEY:=}

# Set SKIP_SERVICES_CHECK=true for now
export SKIP_SERVICES_CHECK=true
set +a

# Create a temporary file for validation
TMP_FILE=$(mktemp)
trap 'rm -f "$TMP_FILE"' EXIT

# Read the template and perform substitutions
cat templates/cloud-init.yaml.template | \
envsubst '${DOMAIN}
${CADDY_ACME_EMAIL}
${SETUP_REPOSITORY}
${POSTGRES_HOST}
${POSTGRES_PORT}
${POSTGRES_USER}
${POSTGRES_PASSWORD}
${N8N_DB_USER}
${N8N_DB_PASSWORD}
${BASEROW_DB_USER}
${BASEROW_DB_PASSWORD}
${KC_DB_USERNAME}
${KC_DB_PASSWORD}
${APPWRITE_ENV}
${APPWRITE_OPENSSL_KEY}
${APPWRITE_DOMAIN}
${APPWRITE_DOMAIN_TARGET}
${QDRANT_API_KEY}
${MINIO_ROOT_USER}
${MINIO_ROOT_PASSWORD}
${REDIS_PASSWORD}
${RESTIC_PASSWORD}
${BACKUP_CRON}
${BACKUP_VOLUME_PATH}
${BACKUP_MOUNT_POINT}
${TELEGRAM_BOT_TOKEN}
${TELEGRAM_CHAT_ID}
${RESTIC_REPOSITORY}
${SKIP_SERVICES_CHECK}' > "$TMP_FILE"

# Basic validation - check for cloud-config header
if ! grep -q "^#cloud-config" "$TMP_FILE"; then
    echo -e "${RED}Error: Missing #cloud-config header${NC}"
    exit 1
fi

# Python YAML validation
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}Warning: Python 3 not found. Skipping YAML validation${NC}"
else
    # Check if PyYAML is installed
    if [ ! -d "$HOME/Library/Python/3.9/lib/python/site-packages/yaml" ]; then
        echo -e "${YELLOW}Warning: PyYAML not installed. Installing...${NC}"
        pip3 install --user pyyaml
        # Verify installation
        if [ ! -d "$HOME/Library/Python/3.9/lib/python/site-packages/yaml" ]; then
            echo -e "${RED}Error: Failed to install PyYAML. Please install it manually:${NC}"
            echo "pip3 install --user pyyaml"
            exit 1
        fi
    fi
    
    # Set Python path
    export PYTHONPATH="$HOME/Library/Python/3.9/lib/python/site-packages:$PYTHONPATH"
    
    # Validate YAML
    YAML_ERROR=$(python3 -c "import yaml; yaml.safe_load(open('$TMP_FILE'))" 2>&1)
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Invalid YAML syntax${NC}"
        echo "Python error message:"
        echo "$YAML_ERROR"
        exit 1
    fi
    echo -e "${GREEN}✓ YAML validation successful${NC}"
fi

# Move the file to its final location
mv "$TMP_FILE" build/cloud-init.yaml
echo -e "${GREEN}✓ cloud-init.yaml has been generated in the build directory${NC}"

# Print first few lines to verify
echo -e "\nFirst few lines of generated cloud-init.yaml:"
head -n 10 build/cloud-init.yaml