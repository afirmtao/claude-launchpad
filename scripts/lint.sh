#!/bin/bash

set -euo pipefail

echo "Linting YAML files..."

if command -v ansible-lint >/dev/null 2>&1; then
	ansible-lint *.yml roles/
else
	echo "Warning: ansible-lint not found, skipping Ansible linting"
fi

if command -v yamllint >/dev/null 2>&1; then
	yamllint .
else
	echo "Warning: yamllint not found, skipping YAML linting"
fi

echo "Linting complete"
