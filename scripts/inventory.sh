#!/bin/bash

set -euo pipefail

# Source common functions
source "$(dirname "$0")/common.sh"

FQDN="${1:-}"

validate_fqdn "$FQDN"

HOST_VARS_FILE=$(get_host_vars_file "$FQDN")
EXAMPLE_HOST_VARS="$HOST_VARS_DIR/example.com.yml"

if [ -f "$HOST_VARS_FILE" ]; then
	echo "Inventory for $FQDN already exists at $HOST_VARS_FILE"
	exit 0
fi

echo "Setting up inventory for $FQDN..."

read -p "Enter SSH public key (leave empty to use ~/.ssh/id_rsa.pub): " SSH_KEY
if [ -z "$SSH_KEY" ]; then
	if [ -f ~/.ssh/id_rsa.pub ]; then
		SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
		echo "Using SSH key from ~/.ssh/id_rsa.pub"
	else
		echo "Error: No SSH key provided and ~/.ssh/id_rsa.pub not found"
		exit 1
	fi
fi

read -p "Enter IPv4 address (leave empty to resolve from DNS): " IPV4
if [ -z "$IPV4" ]; then
	echo "Resolving IPv4 for $FQDN..."
	IPV4=$(dig +short A "$FQDN" | head -n1)
	if [ -z "$IPV4" ]; then
		echo "Error: Could not resolve IPv4 for $FQDN"
		exit 1
	fi
	echo "Resolved IPv4: $IPV4"
fi

read -p "Enter IPv6 address (leave empty to resolve from DNS): " IPV6
if [ -z "$IPV6" ]; then
	echo "Resolving IPv6 for $FQDN..."
	IPV6=$(dig +short AAAA "$FQDN" | head -n1)
	if [ -z "$IPV6" ]; then
		echo "Warning: Could not resolve IPv6 for $FQDN"
		IPV6=""
	else
		echo "Resolved IPv6: $IPV6"
	fi
fi

read -p "Enter admin username [admin]: " ADMIN_USER
ADMIN_USER=${ADMIN_USER:-admin}

read -s -p "Enter Grafana admin password: " GRAFANA_PASSWORD
echo
if [ -z "$GRAFANA_PASSWORD" ]; then
	echo "Error: Grafana password cannot be empty"
	exit 1
fi

mkdir -p "$HOST_VARS_DIR"

# Copy example and replace variables
cp "$EXAMPLE_HOST_VARS" "$HOST_VARS_FILE"
sed -i "s/ansible_host: .*/ansible_host: $IPV4/" "$HOST_VARS_FILE"
sed -i "s/fqdn: .*/fqdn: $FQDN/" "$HOST_VARS_FILE"
sed -i "s/admin_user: .*/admin_user: $ADMIN_USER/" "$HOST_VARS_FILE"
sed -i "s|admin_ssh_key: .*|admin_ssh_key: \"$SSH_KEY\"|" "$HOST_VARS_FILE"
sed -i "s/grafana_admin_password: .*/grafana_admin_password: \"$GRAFANA_PASSWORD\"/" "$HOST_VARS_FILE"

if [ -n "$IPV6" ]; then
	sed -i "s/ansible_host_ipv6: .*/ansible_host_ipv6: \"$IPV6\"/" "$HOST_VARS_FILE"
else
	# Remove IPv6 line if no IPv6 provided
	sed -i "/ansible_host_ipv6:/d" "$HOST_VARS_FILE"
fi

# Create hosts.ini if it doesn't exist
ensure_hosts_ini

# Remove example.com from hosts.ini if it exists
sed -i '/^example\.com$/d' "$HOSTS_INI" 2>/dev/null || true

if ! grep -q "^$FQDN$" "$HOSTS_INI" 2>/dev/null; then
	echo "$FQDN" >>"$HOSTS_INI"
	echo "Added $FQDN to hosts.ini"
fi

# Remove domain and IP from SSH known_hosts to prevent conflicts
echo "Cleaning SSH known_hosts for $FQDN and $IPV4..."
ssh-keygen -R "$FQDN" 2>/dev/null || true
ssh-keygen -R "$IPV4" 2>/dev/null || true
if [ -n "$IPV6" ]; then
	ssh-keygen -R "$IPV6" 2>/dev/null || true
fi

echo "Inventory created successfully at $HOST_VARS_FILE"
