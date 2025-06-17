#!/bin/bash

set -euo pipefail

# Source common functions
source "$(dirname "$0")/common.sh"

echo "Formatting shell scripts..."

execute_if_available shfmt "skipping shell script formatting" \
	find scripts/ -name "*.sh" -exec shfmt -w {} \;

if command_exists shfmt; then
	echo "Shell scripts formatted successfully"
fi

echo "Formatting complete"
