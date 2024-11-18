#!/bin/bash

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source environment variables
source /root/.env

# Function to check if Docker services are ready
check_docker_services() {
    local max_attempts=30
    local wait_seconds=10
    local attempt=1

    "${SCRIPT_DIR}/notify.sh" "🔄 Waiting for Docker services to be ready..."

    while [ $attempt -le $max_attempts ]; do
        # Get services that are not running or not healthy
        local unhealthy_services=$(docker compose -f /root/supreme-computing-machine/docker-compose.yml ps --format json | \
            jq -r '.[] | select(.State != "running" or (.Health != null and .Health != "healthy")) | .Service')

        if [ -z "$unhealthy_services" ]; then
            "${SCRIPT_DIR}/notify.sh" "✅ All Docker services are running and healthy"
            return 0
        fi

        if [ $attempt -lt $max_attempts ]; then
            echo "Attempt $attempt/$max_attempts: Some services are not ready yet, waiting ${wait_seconds} seconds..."
            echo "Services not ready: $unhealthy_services"
            sleep $wait_seconds
        fi

        attempt=$((attempt + 1))
    done

    "${SCRIPT_DIR}/notify.sh" "❌ Some Docker services failed to start properly after ${max_attempts} attempts"
    docker compose -f /root/supreme-computing-machine/docker-compose.yml ps
    return 1
}

# Function to check if a service endpoint is responding
check_service_endpoint() {
    local service_name=$1
    local url=$2
    local max_attempts=${3:-30}
    local wait_seconds=${4:-10}
    local attempt=1

    "${SCRIPT_DIR}/notify.sh" "🔍 Checking ${service_name} endpoint availability..."

    while [ $attempt -le $max_attempts ]; do
        if curl -s -k --head "$url" | grep "HTTP/" > /dev/null 2>&1; then
            "${SCRIPT_DIR}/notify.sh" "✅ ${service_name} endpoint is responding"
            return 0
        fi
        
        if [ $attempt -lt $max_attempts ]; then
            echo "Attempt $attempt/$max_attempts: ${service_name} endpoint not ready, waiting ${wait_seconds} seconds..."
            sleep $wait_seconds
        fi
        
        attempt=$((attempt + 1))
    done

    "${SCRIPT_DIR}/notify.sh" "❌ ${service_name} endpoint failed to respond after ${max_attempts} attempts"
    return 1
}

# First check if all Docker services are ready
if ! check_docker_services; then
    "${SCRIPT_DIR}/notify.sh" "❌ *Setup Incomplete*
Docker services failed to start properly. Please check the logs for more details."
    exit 1
fi

# Check all service endpoints
services_ready=true

# List of services to check
declare -A services=(
    ["Appwrite"]="https://appwrite.${APP_DOMAIN}"
    ["n8n"]="https://n8n.${APP_DOMAIN}"
    ["Baserow"]="https://baserow.${APP_DOMAIN}"
    ["Qdrant"]="https://qdrant.${APP_DOMAIN}"
    ["MinIO"]="https://minio.${APP_DOMAIN}"
    ["Keycloak"]="https://auth.${APP_DOMAIN}"
)

"${SCRIPT_DIR}/notify.sh" "🔄 Starting endpoint health checks..."

# Check each service endpoint
for service in "${!services[@]}"; do
    if ! check_service_endpoint "$service" "${services[$service]}"; then
        services_ready=false
    fi
done

# Only if all services are ready, send the final success message
if [ "$services_ready" = true ]; then
    # Build the success message
    message="✅ *Setup Complete*
Supreme Computing Machine is now running!

Services:"

    # Add each service URL to the message
    for service in "${!services[@]}"; do
        message="${message}
- ${service}: ${services[$service]}"
    done

    "${SCRIPT_DIR}/notify.sh" "$message"
    exit 0
else
    "${SCRIPT_DIR}/notify.sh" "❌ *Setup Incomplete*
Some service endpoints are not responding. Please check the logs for more details."
    exit 1
fi
