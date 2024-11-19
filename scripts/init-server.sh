# Source environment variables
source /root/.env

#!/bin/bash
./scripts/notify.sh "🌱 Creating new server..."

# Configure firewall
./scripts/notify.sh "🛡️ Configuring firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Mount backup volume and initialize
./scripts/notify.sh "💾 Mounting backup volume..."
./scripts/mount-backup-volume.sh

# Set up backup cron job
echo "${BACKUP_CRON} root /root/supreme-computing-machine/scripts/backup-volumes.sh >> /var/log/volume-backup.log 2>&1" > /etc/cron.d/volume-backup

# Start services
./scripts/notify.sh "🚀 Starting services..."
./scripts/deploy-services.sh

# Run health checks only if SKIP_SERVICES_CHECK is not set
# if [ "${SKIP_SERVICES_CHECK}" != "true" ]; then
#   /root/supreme-computing-machine/scripts/check-services.sh
# else
#   echo "Skipping services check as SKIP_SERVICES_CHECK=true"
# fi

# Check services and send final notification
./scripts/notify.sh "✅ *Setup Complete*
Supreme Computing Machine is now running!

Services:
- Appwrite: https://appwrite.${DOMAIN}
- n8n: https://n8n.${DOMAIN}
- Baserow: https://baserow.${DOMAIN}
- Qdrant: https://qdrant.${DOMAIN}
- MinIO: https://minio.${DOMAIN}
- Keycloak: https://auth.${DOMAIN}"
