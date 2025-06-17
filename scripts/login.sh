#!/bin/bash

set -euo pipefail

# Source common functions
source "$(dirname "$0")/common.sh"

FQDN="$1"

if [ -z "$FQDN" ]; then
	echo "Usage: $0 <FQDN>"
	exit 1
fi

# Get host information
get_host_info "$FQDN"

echo "Connecting to $ADMIN_USER@$IPV4..."
TERM=xterm ssh "$ADMIN_USER@$IPV4"
