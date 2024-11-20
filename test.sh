#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    local title="$1"
    local len=${#title}
    echo -e "\n${BLUE}${title}${NC}"
    printf '%*s\n' "$len" | tr ' ' '='
}

# Function to check if a variable is set and not empty
check_variable() {
    local var_name=$1
    local var_value=${!var_name}
    
    if [ -z "$var_value" ]; then
        echo -e "${RED}✗ $var_name is not set${NC}"
        return 1
    else
        echo -e "${GREEN}✓ $var_name is set${NC}"
        return 0
    fi
}

# Function to test a URL is accessible
test_url() {
    local url=$1
    local description=$2
    
    echo -n "Testing $description... "
    if curl -s --head "$url" > /dev/null; then
        echo -e "${GREEN}✓ Success${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed${NC}"
        return 1
    fi
}

# Load environment variables
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    echo "Please run setup.sh first"
    exit 1
fi

source .env

# Override variables for localhost testing
export DOMAIN="localhost"
export _APP_DOMAIN="localhost"
export _APP_DOMAIN_TARGET="localhost"
export KC_HOSTNAME="localhost"
export CADDY_GLOBAL_OPTIONS="debug"
export CADDY_TLS_OPTIONS="tls internal"

# Start testing
print_header "Configuration Test"

# Test Domain Configuration
echo -e "\n${BLUE}Domain Configuration${NC}"
check_variable "_APP_DOMAIN"
check_variable "CADDY_ACME_EMAIL"

# Test Repository Configuration
echo -e "\n${BLUE}Repository Configuration${NC}"
check_variable "SETUP_REPOSITORY"

# Test PostgreSQL Configuration
echo -e "\n${BLUE}PostgreSQL Configuration${NC}"
check_variable "POSTGRES_USER"
check_variable "POSTGRES_PASSWORD"

# Test Appwrite Configuration
echo -e "\n${BLUE}Appwrite Configuration${NC}"
check_variable "_APP_ENV"
check_variable "_APP_OPENSSL_KEY_V1"
check_variable "_APP_DOMAIN_TARGET"

# Test Baserow Configuration
echo -e "\n${BLUE}Baserow Configuration${NC}"
check_variable "BASEROW_SECRET_KEY"
check_variable "BASEROW_DB_PASSWORD"

# Test Qdrant Configuration
echo -e "\n${BLUE}Qdrant Configuration${NC}"
check_variable "QDRANT_API_KEY"

# Test Minio Configuration
echo -e "\n${BLUE}Minio Configuration${NC}"
check_variable "MINIO_ROOT_USER"
check_variable "MINIO_ROOT_PASSWORD"

# Test Redis Configuration
echo -e "\n${BLUE}Redis Configuration${NC}"
check_variable "REDIS_PASSWORD"

# Test Keycloak Configuration
echo -e "\n${BLUE}Keycloak Configuration${NC}"
check_variable "KEYCLOAK_ADMIN"
check_variable "KEYCLOAK_ADMIN_PASSWORD"
check_variable "KC_DB"
check_variable "KC_DB_USERNAME"
check_variable "KC_DB_PASSWORD"
check_variable "KC_HOSTNAME"
check_variable "KC_PROXY"

# Test Backup Configuration
echo -e "\n${BLUE}Backup Configuration${NC}"
check_variable "RESTIC_PASSWORD"
check_variable "BACKUP_CRON"
check_variable "BACKUP_VOLUME_PATH"

# Test Telegram Configuration
echo -e "\n${BLUE}Telegram Configuration${NC}"
check_variable "TELEGRAM_BOT_TOKEN"
check_variable "TELEGRAM_CHAT_ID"

# Test Docker
print_header "Docker Test"
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓ Docker is installed${NC}"
    if docker info &> /dev/null; then
        echo -e "${GREEN}✓ Docker daemon is running${NC}"
    else
        echo -e "${RED}✗ Docker daemon is not running${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Docker is not installed${NC}"
    exit 1
fi

if ! docker compose version &> /dev/null; then
    echo -e "${RED}✗ Docker Compose V2 is not installed${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Docker Compose V2 is installed${NC}"
fi

# Start services test
print_header "Service Deployment Test"

# Start services
echo -e "\n${BLUE}Starting services...${NC}"
./scripts/notify.sh "🚀 Starting services for testing..."
./scripts/deploy-services.sh

# Summary
print_header "Test Summary"
echo -e "Services have been deployed for testing."
echo -e "You can access them at:"
echo -e "- Appwrite: http://appwrite.localhost"
echo -e "- n8n: http://n8n.localhost"
echo -e "- Baserow: http://baserow.localhost"
echo -e "- Qdrant: http://qdrant.localhost"
echo -e "- MinIO: http://minio.localhost"
echo -e "- Keycloak: http://auth.localhost"
echo -e "\nNote: Make sure your /etc/hosts file has entries for these domains pointing to 127.0.0.1"
echo -e "To stop the services, run: docker compose down"
