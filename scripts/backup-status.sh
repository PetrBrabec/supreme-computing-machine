#!/bin/bash

# Source environment variables
source /root/supreme-computing-machine/.env

# Check restic repository stats
echo "Repository Statistics:"
restic -r "$RESTIC_REPOSITORY" --password-file /root/.restic-pass stats

echo -e "\nLatest Snapshots:"
restic -r "$RESTIC_REPOSITORY" --password-file /root/.restic-pass snapshots --latest 3

echo -e "\nSpace Usage:"
du -sh /mnt/backup/docker-volumes
du -sh "$RESTIC_REPOSITORY"
