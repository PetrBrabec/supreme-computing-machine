#!/bin/bash

# Source environment variables
source /root/.env

# Check restic repository stats
echo "Repository Statistics:"
restic -r /mnt/backup/restic-repo stats

echo -e "\nLatest Snapshots:"
restic -r /mnt/backup/restic-repo snapshots --last 3

echo -e "\nSpace Usage:"
du -sh /mnt/backup/docker-volumes
du -sh /mnt/backup/restic-repo
