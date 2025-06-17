#!/bin/bash

get_host_info() {
	local fqdn="$1"

	if [ -z "$fqdn" ]; then
		echo "Error: FQDN is required" >&2
		return 1
	fi

	local host_vars_file="inventories/host_vars/$fqdn.yml"

	if [ ! -f "$host_vars_file" ]; then
		echo "Error: Host vars file not found at $host_vars_file" >&2
		return 1
	fi

	# Extract variables and set them globally
	IPV4=$(grep "^ansible_host:" "$host_vars_file" | cut -d':' -f2 | tr -d ' ')
	ADMIN_USER=$(grep "^admin_user:" "$host_vars_file" | cut -d':' -f2 | tr -d ' ')
}
