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