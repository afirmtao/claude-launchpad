#!/bin/bash

set -euo pipefail

# Source common functions
source "$(dirname "$0")/common.sh"

FQDN="${1:-}"

validate_fqdn "$FQDN"

echo "Verifying server setup for $FQDN..."
echo

get_host_info "$FQDN"

# Check if admin user exists and can login
echo -n "Checking admin user SSH access... "
if test_ssh_connection "$ADMIN_USER" "$IPV4"; then
	echo "PASS"
else
	echo "FAIL"
	echo "  Admin user $ADMIN_USER cannot login via SSH"
	exit 1
fi

# Run the verification playbook as admin user with elevation
ansible-playbook -i inventories/hosts.ini playbook-verify.yml --limit "$FQDN" \
	--user "$ADMIN_USER" --become --become-method sudo
