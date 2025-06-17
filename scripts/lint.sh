#!/bin/bash

set -euo pipefail

# Source common functions
source "$(dirname "$0")/common.sh"

echo "Linting YAML files..."

execute_if_available ansible-lint "skipping Ansible linting" \
	ansible-lint *.yml roles/

execute_if_available yamllint "skipping YAML linting" \
	yamllint .

echo "Linting complete"
