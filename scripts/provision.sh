#!/bin/bash

set -euo pipefail

# Source common functions
source "$(dirname "$0")/common.sh"

FQDN="$1"

if [ -z "$FQDN" ]; then
	echo "Usage: $0 <FQDN>"
	exit 1
fi

INVENTORY_DIR="inventories"
HOSTS_INI="$INVENTORY_DIR/hosts.ini"
HOST_VARS_FILE="$INVENTORY_DIR/host_vars/$FQDN.yml"

# Create hosts.ini if it doesn't exist
if [ ! -f "$HOSTS_INI" ]; then
	mkdir -p "$INVENTORY_DIR"
	echo "# Dynamic inventory - managed by scripts" >"$HOSTS_INI"
	echo "Created $HOSTS_INI"
fi

# Setup inventory if it doesn't exist
if [ ! -f "$HOST_VARS_FILE" ]; then
	./scripts/inventory.sh "$FQDN"
fi

# Get host information
get_host_info "$FQDN"

# Check if admin user exists and can SSH
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$ADMIN_USER@$IPV4" "exit" 2>/dev/null; then
	echo "Admin user $ADMIN_USER exists, using it for connection"
	ansible-playbook -i "$HOSTS_INI" playbook-provision.yml --limit "$FQDN" --become \
		-e ansible_user="$ADMIN_USER"
else
	echo "Admin user does not exist, using root to create it"
	ansible-playbook -i "$HOSTS_INI" playbook-provision.yml --limit "$FQDN" \
		-e ansible_user=root
fi

# Verify server setup after provisioning
echo
echo "Running verification checks..."
./scripts/verify.sh "$FQDN"
