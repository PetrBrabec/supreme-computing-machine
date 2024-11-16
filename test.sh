#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}$1${NC}"
    echo "$(printf '=%.0s' {1..${#1}})"
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

# Start testing
print_header "Configuration Test"

# Test Domain Configuration
echo -e "\n${BLUE}Domain Configuration${NC}"
check_variable "APP_DOMAIN"
check_variable "CADDY_ACME_EMAIL"

# Test Repository Configuration
echo -e "\n${BLUE}Repository Configuration${NC}"
check_variable "SETUP_REPOSITORY"

# Test PostgreSQL Configuration
echo -e "\n${BLUE}PostgreSQL Configuration${NC}"
check_variable "POSTGRES_USER"
check_variable "POSTGRES_PASSWORD"
check_variable "POSTGRES_DB"
check_variable "POSTGRES_NON_ROOT_USER"
check_variable "POSTGRES_NON_ROOT_PASSWORD"

# Test Appwrite Configuration
echo -e "\n${BLUE}Appwrite Configuration${NC}"
check_variable "APP_ENV"
check_variable "APP_OPENSSL_KEY"
check_variable "APP_DOMAIN_TARGET"

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
check_variable "KC_DB_URL"
check_variable "KC_DB_USERNAME"
check_variable "KC_DB_PASSWORD"
check_variable "KC_HOSTNAME"
check_variable "KC_PROXY"

# Test Backup Configuration
echo -e "\n${BLUE}Backup Configuration${NC}"
check_variable "RESTIC_PASSWORD"
check_variable "BACKUP_CRON"
check_variable "BACKUP_VOLUME_DEVICE"

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
    fi
else
    echo -e "${RED}✗ Docker is not installed${NC}"
fi

if command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}✓ Docker Compose is installed${NC}"
else
    echo -e "${RED}✗ Docker Compose is not installed${NC}"
fi

# Summary
print_header "Test Summary"
echo -e "If all tests passed, your configuration looks good!"
echo -e "Next steps:"
echo "1. Make sure all required ports are open on your server"
echo "2. Ensure your domain DNS is properly configured"
echo "3. Run the deployment script"
