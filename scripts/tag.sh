#!/bin/bash

set -euo pipefail

# Source common functions
source "$(dirname "$0")/common.sh"

FQDN="${1:-}"
TAG="${2:-}"

validate_fqdn "$FQDN" "tag.sh"

if [ -z "$TAG" ]; then
	echo "Usage: tag.sh <FQDN> <TAG>"
	echo "Example: tag.sh example.com metrics-container"
	exit 1
fi

echo "Running tag '$TAG' on $FQDN..."

# Get host information
get_host_info "$FQDN"

if [ -z "$ADMIN_USER" ]; then
	die "Could not determine admin_user from host vars"
fi

echo "Using admin user: $ADMIN_USER"

# Run ansible playbook with specific tag and user
ansible-playbook -i inventories/hosts.ini playbook-provision.yml \
	--limit "$FQDN" \
	--tags "$TAG" \
	-u "$ADMIN_USER"

echo "Tag '$TAG' completed successfully on $FQDN"
