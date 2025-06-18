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

echo "Formatting markdown files..."

execute_if_available mdformat "skipping markdown formatting" \
	mdformat .

if command_exists mdformat; then
	echo "Markdown files formatted successfully"
fi

echo "Formatting complete"
