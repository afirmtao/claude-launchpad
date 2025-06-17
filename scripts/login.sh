#!/bin/bash

set -euo pipefail

# Source common functions
source "$(dirname "$0")/common.sh"

FQDN="${1:-}"

validate_fqdn "$FQDN"
get_host_info "$FQDN"

echo "Connecting to $ADMIN_USER@$IPV4..."
TERM=xterm ssh "$ADMIN_USER@$IPV4"
