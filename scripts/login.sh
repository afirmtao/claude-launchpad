#!/bin/bash

set -euo pipefail

# Source common functions
source "$(dirname "$0")/common.sh"

FQDN="${1:-}"
COMMAND="${2:-}"

validate_fqdn "$FQDN"
get_host_info "$FQDN"

if [ -n "$COMMAND" ]; then
	echo "Executing '$COMMAND' on $ADMIN_USER@$IPV4..."
	# Force TTY allocation for interactive commands like docker exec -it
	if [[ "$COMMAND" == *"docker exec -it"* ]]; then
		TERM=xterm ssh -tt "$ADMIN_USER@$IPV4" "$COMMAND"
	else
		TERM=xterm ssh -t "$ADMIN_USER@$IPV4" "$COMMAND"
	fi
else
	echo "Connecting to $ADMIN_USER@$IPV4..."
	TERM=xterm ssh "$ADMIN_USER@$IPV4"
fi
