#!/bin/bash

set -euo pipefail

# Source common functions
source "$(dirname "$0")/common.sh"

FQDN="$1"

if [ -z "$FQDN" ]; then
	echo "Usage: $0 <FQDN>"
	exit 1
fi

echo "Verifying server setup for $FQDN..."
echo

# Get host information
get_host_info "$FQDN"

FAILED_CHECKS=0

# Check 1: Admin user exists and can login
echo -n "Checking admin user SSH access... "
if ssh -o ConnectTimeout=10 -o BatchMode=yes "$ADMIN_USER@$IPV4" "exit" 2>/dev/null; then
	echo "PASS"
else
	echo "FAIL"
	echo "  Admin user $ADMIN_USER cannot login via SSH"
	FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Check 2: Admin user has sudo privileges
echo -n "Checking admin user sudo access... "
if ssh -o ConnectTimeout=10 -o BatchMode=yes "$ADMIN_USER@$IPV4" "sudo -n true" 2>/dev/null; then
	echo "PASS"
else
	echo "FAIL"
	echo "  Admin user $ADMIN_USER does not have passwordless sudo"
	FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Check 3: Swap is configured
echo -n "Checking swap configuration... "
SWAP_INFO=$(ssh -o ConnectTimeout=10 -o BatchMode=yes "$ADMIN_USER@$IPV4" "free -m | grep Swap" 2>/dev/null || echo "")
if [ -n "$SWAP_INFO" ]; then
	SWAP_TOTAL=$(echo "$SWAP_INFO" | awk '{print $2}')
	if [ "$SWAP_TOTAL" -gt 0 ]; then
		echo "PASS (${SWAP_TOTAL}MB)"
	else
		echo "FAIL"
		echo "  Swap is configured but not enabled"
		FAILED_CHECKS=$((FAILED_CHECKS + 1))
	fi
else
	echo "FAIL"
	echo "  Could not retrieve swap information"
	FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Check 4: Swappiness value
echo -n "Checking swappiness value... "
SWAPPINESS=$(ssh -o ConnectTimeout=10 -o BatchMode=yes "$ADMIN_USER@$IPV4" "cat /proc/sys/vm/swappiness" 2>/dev/null || echo "")
if [ -n "$SWAPPINESS" ]; then
	if [ "$SWAPPINESS" -eq 20 ]; then
		echo "PASS ($SWAPPINESS)"
	else
		echo "WARN ($SWAPPINESS, expected 20)"
	fi
else
	echo "FAIL"
	echo "  Could not retrieve swappiness value"
	FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Check 5: SSH key authentication
echo -n "Checking SSH key authentication... "
if ssh -o ConnectTimeout=10 -o BatchMode=yes -o PreferredAuthentications=publickey "$ADMIN_USER@$IPV4" "exit" 2>/dev/null; then
	echo "PASS"
else
	echo "FAIL"
	echo "  SSH key authentication not working properly"
	FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Check 6: Timezone configuration
echo -n "Checking timezone configuration... "
TIMEZONE=$(ssh -o ConnectTimeout=10 -o BatchMode=yes "$ADMIN_USER@$IPV4" "timedatectl show --property=Timezone --value" 2>/dev/null || echo "")
if [ -n "$TIMEZONE" ]; then
	echo "PASS ($TIMEZONE)"
else
	echo "FAIL"
	echo "  Could not retrieve timezone information"
	FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Check 7: NTP synchronization
echo -n "Checking NTP synchronization... "
NTP_STATUS=$(ssh -o ConnectTimeout=10 -o BatchMode=yes "$ADMIN_USER@$IPV4" "timedatectl show --property=NTPSynchronized --value" 2>/dev/null || echo "")
if [ "$NTP_STATUS" = "yes" ]; then
	echo "PASS"
else
	echo "WARN (NTP not synchronized yet)"
fi

# Check 8: UFW firewall status
echo -n "Checking UFW firewall status... "
UFW_STATUS=$(ssh -o ConnectTimeout=10 -o BatchMode=yes "$ADMIN_USER@$IPV4" "sudo ufw status | grep -o 'Status: active'" 2>/dev/null || echo "")
if [ "$UFW_STATUS" = "Status: active" ]; then
	echo "PASS"
else
	echo "FAIL"
	echo "  UFW firewall is not active"
	FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Check 9: Root SSH login disabled
echo -n "Checking root SSH login disabled... "
if ssh -o ConnectTimeout=5 -o BatchMode=yes root@"$IPV4" "exit" 2>/dev/null; then
	echo "FAIL"
	echo "  Root SSH login is still enabled"
	FAILED_CHECKS=$((FAILED_CHECKS + 1))
else
	echo "PASS"
fi

# Check 10: /tmp directory writable
echo -n "Checking /tmp directory writable... "
TMP_WRITABLE=$(ssh -o ConnectTimeout=10 -o BatchMode=yes "$ADMIN_USER@$IPV4" "touch /tmp/test_write && rm /tmp/test_write && echo 'writable'" 2>/dev/null || echo "")
if [ "$TMP_WRITABLE" = "writable" ]; then
	echo "PASS"
else
	echo "FAIL"
	echo "  /tmp directory is not writable"
	FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Check 11: Docker is installed
echo -n "Checking Docker installation... "
DOCKER_VERSION=$(ssh -o ConnectTimeout=10 -o BatchMode=yes "$ADMIN_USER@$IPV4" "docker --version 2>/dev/null" || echo "")
if [ -n "$DOCKER_VERSION" ]; then
	echo "PASS ($DOCKER_VERSION)"
else
	echo "FAIL"
	echo "  Docker is not installed"
	FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Check 12: Admin user can run Docker without sudo
echo -n "Checking admin user Docker permissions... "
DOCKER_PERMISSION=$(ssh -o ConnectTimeout=10 -o BatchMode=yes "$ADMIN_USER@$IPV4" "docker info >/dev/null 2>&1 && echo 'allowed'" 2>/dev/null || echo "")
if [ "$DOCKER_PERMISSION" = "allowed" ]; then
	echo "PASS"
else
	echo "FAIL"
	echo "  Admin user cannot run Docker without sudo"
	FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

echo
echo "Verification Summary:"
if [ $FAILED_CHECKS -eq 0 ]; then
	echo "All critical checks passed! Server is properly configured."
	exit 0
else
	echo "$FAILED_CHECKS critical checks failed. Server needs attention."
	exit 1
fi
