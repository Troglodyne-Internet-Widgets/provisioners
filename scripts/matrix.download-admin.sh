#!/bin/bash
# Download and extract Synapse Admin

ADMIN_DIR="$1"
mkdir -p "$ADMIN_DIR"

wget -O - https://github.com/etkecc/synapse-admin/releases/latest/download/synapse-admin.tar.gz | tar -xz -C "$ADMIN_DIR" --strip-components=1

# Set permissions
chown -R www-data:www-data "$ADMIN_DIR"