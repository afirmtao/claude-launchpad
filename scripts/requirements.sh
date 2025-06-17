#!/bin/bash

set -euo pipefail

echo "Installing Ansible requirements..."

# Install roles to user directory
echo "Installing roles..."
ansible-galaxy install -r requirements.yml --roles-path ~/.ansible/roles

# Install collections to user directory
echo "Installing collections..."
ansible-galaxy collection install -r requirements.yml --collections-path ~/.ansible/collections

echo "Ansible requirements installed successfully!"
echo "Roles installed to: ~/.ansible/roles"
echo "Collections installed to: ~/.ansible/collections"
