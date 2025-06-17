#!/bin/bash

set -euo pipefail

echo "Formatting shell scripts..."

if command -v shfmt >/dev/null 2>&1; then
	find scripts/ -name "*.sh" -exec shfmt -w {} \;
	echo "Shell scripts formatted successfully"
else
	echo "Warning: shfmt not found, skipping shell script formatting"
fi

echo "Formatting complete"
