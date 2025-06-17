#!/bin/bash

set -euo pipefail

# Source common functions
source "$(dirname "$0")/common.sh"

FQDN="${1:-}"

validate_fqdn "$FQDN"
ensure_hosts_ini

HOST_VARS_FILE=$(get_host_vars_file "$FQDN")

# Setup inventory if it doesn't exist
if [ ! -f "$HOST_VARS_FILE" ]; then
	./scripts/inventory.sh "$FQDN"
fi

get_host_info "$FQDN"

# Check if admin user exists and can SSH
if test_ssh_connection "$ADMIN_USER" "$IPV4" 5; then
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
