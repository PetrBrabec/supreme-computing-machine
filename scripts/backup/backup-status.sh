#!/bin/bash

# Source environment variables
source /root/supreme-computing-machine/.env

# Create password file for restic
echo "$RESTIC_PASSWORD" > /root/.restic-pass
chmod 600 /root/.restic-pass

# Check restic repository stats
echo "Repository Statistics:"
restic -r "$RESTIC_REPOSITORY" --password-file /root/.restic-pass stats

echo -e "\nLatest Snapshots:"
restic -r "$RESTIC_REPOSITORY" --password-file /root/.restic-pass snapshots --latest 3

echo -e "\nSpace Usage:"
du -sh "$RESTIC_REPOSITORY"

# Clean up
rm -f /root/.restic-pass
