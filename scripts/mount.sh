#!/bin/bash

set -euo pipefail

# Source common functions
source "$(dirname "$0")/common.sh"

FQDN="${1:-}"
ACTION="${2:-}"

if [ -z "$FQDN" ] || [ -z "$ACTION" ]; then
	echo "Usage: $0 <FQDN> <mount|unmount>"
	exit 1
fi

validate_fqdn "$FQDN"

# Check if sshfs is available
if ! command_exists sshfs; then
	die "sshfs is not installed. Install it with: sudo pacman -S sshfs"
fi

# Create local mount directory
LOCAL_MOUNT_DIR="$HOME/mnt/${FQDN}-stacks"
mkdir -p "$LOCAL_MOUNT_DIR"

case "$ACTION" in
mount)
	# Check if already mounted
	if mountpoint -q "$LOCAL_MOUNT_DIR" 2>/dev/null; then
		echo "Directory already mounted at $LOCAL_MOUNT_DIR"
		exit 0
	fi

	get_host_info "$FQDN"

	# Test SSH connection first
	if ! test_ssh_connection "$ADMIN_USER" "$IPV4" 5; then
		die "Cannot connect to $ADMIN_USER@$IPV4"
	fi

	# Ensure stacks directory exists on remote
	ssh_execute "$ADMIN_USER" "$IPV4" "mkdir -p ~/stacks" 10 || die "Failed to create ~/stacks directory on remote server"

	# Mount using sshfs
	echo "Mounting $ADMIN_USER@$IPV4:~/stacks to $LOCAL_MOUNT_DIR"
	sshfs "$ADMIN_USER@$IPV4:stacks" "$LOCAL_MOUNT_DIR" \
		-o reconnect \
		-o ServerAliveInterval=15 \
		-o ServerAliveCountMax=3

	echo "Successfully mounted to $LOCAL_MOUNT_DIR"
	;;

unmount)
	# Check if mounted
	if ! mountpoint -q "$LOCAL_MOUNT_DIR" 2>/dev/null; then
		echo "Directory not mounted at $LOCAL_MOUNT_DIR"
		exit 0
	fi

	echo "Unmounting $LOCAL_MOUNT_DIR"
	if command_exists fusermount3; then
		fusermount3 -u "$LOCAL_MOUNT_DIR"
	elif command_exists fusermount; then
		fusermount -u "$LOCAL_MOUNT_DIR"
	else
		die "Neither fusermount3 nor fusermount found"
	fi
	echo "Successfully unmounted"
	;;

*)
	echo "Error: Action must be 'mount' or 'unmount'"
	exit 1
	;;
esac
