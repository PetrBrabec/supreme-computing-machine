#!/bin/bash

# Source environment variables
if [ -f /root/supreme-computing-machine/.env ]; then
    source /root/supreme-computing-machine/.env
else
    ./scripts/notify.sh "❌ *Setup Failed* - Missing .env file"
    echo "Error: .env file not found"
    exit 1
fi

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

# Check for and init from backup if available
./scripts/notify.sh "🔄 Checking for existing data..."
./scripts/init-volumes.sh

# Set up backup cron job
echo "${BACKUP_CRON} root /root/supreme-computing-machine/scripts/backup-volumes.sh >> /var/log/volume-backup.log 2>&1" > /etc/cron.d/volume-backup

# Create systemd service for Docker Compose
cat > /etc/systemd/system/docker-compose-supreme.service << EOL
[Unit]
Description=Docker Compose Supreme Computing Machine
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/root/supreme-computing-machine
ExecStart=/usr/bin/docker compose pull && /usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down

[Install]
WantedBy=multi-user.target
EOL

# Enable and start the service
systemctl enable docker-compose-supreme.service

# Send final notification
./scripts/notify.sh "✅ *Setup Complete*
Supreme Computing Machine has been initialized.

Services will be available at:
- n8n: https://n8n.${DOMAIN}
- Baserow: https://baserow.${DOMAIN}
- Qdrant: https://qdrant.${DOMAIN}
- MinIO: https://minio.${DOMAIN}"
