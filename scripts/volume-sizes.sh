#!/bin/bash

# Get list of volumes
VOLUMES=$(docker volume ls --format '{{.Name}}')

echo "Docker Volume Sizes:"
echo "------------------"

for VOLUME in $VOLUMES; do
    SIZE=$(docker run --rm -v "$VOLUME":/volume alpine du -sh /volume | cut -f1)
    printf "%-40s %10s\n" "$VOLUME" "$SIZE"
done
