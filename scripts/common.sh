#!/bin/bash

# Common directory and file paths
INVENTORY_DIR="inventories"
HOSTS_INI="$INVENTORY_DIR/hosts.ini"
HOST_VARS_DIR="$INVENTORY_DIR/host_vars"

# Common error handling
die() {
	echo "Error: $*" >&2
	exit 1
}

# Validate required FQDN argument
validate_fqdn() {
	local fqdn="$1"
	local script_name="${2:-$0}"

	if [ -z "$fqdn" ]; then
		echo "Usage: $script_name <FQDN>"
		exit 1
	fi
}

# Check if command is available
command_exists() {
	command -v "$1" >/dev/null 2>&1
}

# Execute command with optional warning if not available
execute_if_available() {
	local cmd="$1"
	local warning_msg="$2"
	shift 2

	if command_exists "$cmd"; then
		"$@"
	else
		echo "Warning: $cmd not found, $warning_msg"
	fi
}

# Test SSH connectivity with standard parameters
test_ssh_connection() {
	local user="$1"
	local host="$2"
	local timeout="${3:-10}"

	ssh -o ConnectTimeout="$timeout" -o BatchMode=yes -o StrictHostKeyChecking=no "$user@$host" "exit" 2>/dev/null
}

# Execute SSH command with standard parameters
ssh_execute() {
	local user="$1"
	local host="$2"
	local command="$3"
	local timeout="${4:-10}"

	ssh -o ConnectTimeout="$timeout" -o BatchMode=yes "$user@$host" "$command" 2>/dev/null
}

# Get host information from vars file
get_host_info() {
	local fqdn="$1"

	if [ -z "$fqdn" ]; then
		die "FQDN is required"
	fi

	local host_vars_file="$HOST_VARS_DIR/$fqdn.yml"

	if [ ! -f "$host_vars_file" ]; then
		die "Host vars file not found at $host_vars_file"
	fi

	# Extract variables and set them globally
	IPV4=$(grep "^ansible_host:" "$host_vars_file" | cut -d':' -f2 | tr -d ' ')
	ADMIN_USER=$(grep "^admin_user:" "$host_vars_file" | cut -d':' -f2 | tr -d ' ')
}

# Ensure hosts.ini exists
ensure_hosts_ini() {
	if [ ! -f "$HOSTS_INI" ]; then
		mkdir -p "$INVENTORY_DIR"
		echo "# Dynamic inventory - managed by scripts" >"$HOSTS_INI"
		echo "Created $HOSTS_INI"
	fi
}

# Get host vars file path
get_host_vars_file() {
	local fqdn="$1"
	echo "$HOST_VARS_DIR/$fqdn.yml"
}
