#!/bin/bash

set -euo pipefail

# Source common functions
source "$(dirname "$0")/common.sh"

FQDN="${1:-}"

validate_fqdn "$FQDN"

echo "Verifying server setup for $FQDN..."
echo

get_host_info "$FQDN"

FAILED_CHECKS=0

# Check 1: Admin user exists and can login
echo -n "Checking admin user SSH access... "
if test_ssh_connection "$ADMIN_USER" "$IPV4"; then
	echo "PASS"
else
	echo "FAIL"
	echo "  Admin user $ADMIN_USER cannot login via SSH"
	FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Check 2: Admin user has sudo privileges
echo -n "Checking admin user sudo access... "
if ssh_execute "$ADMIN_USER" "$IPV4" "sudo -n true" >/dev/null; then
	echo "PASS"
else
	echo "FAIL"
	echo "  Admin user $ADMIN_USER does not have passwordless sudo"
	FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Check 3: Swap is configured
echo -n "Checking swap configuration... "
SWAP_INFO=$(ssh_execute "$ADMIN_USER" "$IPV4" "free -m | grep Swap" || echo "")
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
SWAPPINESS=$(ssh_execute "$ADMIN_USER" "$IPV4" "cat /proc/sys/vm/swappiness" || echo "")
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
TIMEZONE=$(ssh_execute "$ADMIN_USER" "$IPV4" "timedatectl show --property=Timezone --value" || echo "")
if [ -n "$TIMEZONE" ]; then
	echo "PASS ($TIMEZONE)"
else
	echo "FAIL"
	echo "  Could not retrieve timezone information"
	FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Check 7: NTP synchronization
echo -n "Checking NTP synchronization... "
NTP_STATUS=$(ssh_execute "$ADMIN_USER" "$IPV4" "timedatectl show --property=NTPSynchronized --value" || echo "")
if [ "$NTP_STATUS" = "yes" ]; then
	echo "PASS"
else
	echo "WARN (NTP not synchronized yet)"
fi

# Check 8: UFW firewall status
echo -n "Checking UFW firewall status... "
UFW_STATUS=$(ssh_execute "$ADMIN_USER" "$IPV4" "sudo ufw status | grep -o 'Status: active'" || echo "")
if [ "$UFW_STATUS" = "Status: active" ]; then
	echo "PASS"
else
	echo "FAIL"
	echo "  UFW firewall is not active"
	FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Check 9: Root SSH login disabled
echo -n "Checking root SSH login disabled... "
if test_ssh_connection "root" "$IPV4" 5; then
	echo "FAIL"
	echo "  Root SSH login is still enabled"
	FAILED_CHECKS=$((FAILED_CHECKS + 1))
else
	echo "PASS"
fi

# Check 10: /tmp directory writable
echo -n "Checking /tmp directory writable... "
TMP_WRITABLE=$(ssh_execute "$ADMIN_USER" "$IPV4" "touch /tmp/test_write && rm /tmp/test_write && echo 'writable'" || echo "")
if [ "$TMP_WRITABLE" = "writable" ]; then
	echo "PASS"
else
	echo "FAIL"
	echo "  /tmp directory is not writable"
	FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Check 11: Docker is installed
echo -n "Checking Docker installation... "
DOCKER_VERSION=$(ssh_execute "$ADMIN_USER" "$IPV4" "docker --version" || echo "")
if [ -n "$DOCKER_VERSION" ]; then
	echo "PASS ($DOCKER_VERSION)"
else
	echo "FAIL"
	echo "  Docker is not installed"
	FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Check 12: Admin user can run Docker without sudo
echo -n "Checking admin user Docker permissions... "
DOCKER_PERMISSION=$(ssh_execute "$ADMIN_USER" "$IPV4" "docker info >/dev/null 2>&1 && echo 'allowed'" || echo "")
if [ "$DOCKER_PERMISSION" = "allowed" ]; then
	echo "PASS"
else
	echo "FAIL"
	echo "  Admin user cannot run Docker without sudo"
	FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Check 13: Caddy is installed
echo -n "Checking Caddy installation... "
CADDY_VERSION=$(ssh_execute "$ADMIN_USER" "$IPV4" "caddy version" || echo "")
if [ -n "$CADDY_VERSION" ]; then
	echo "PASS ($CADDY_VERSION)"
else
	echo "FAIL"
	echo "  Caddy is not installed"
	FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Check 14: Caddy service is running
echo -n "Checking Caddy service status... "
CADDY_STATUS=$(ssh_execute "$ADMIN_USER" "$IPV4" "systemctl is-active caddy" || echo "")
if [ "$CADDY_STATUS" = "active" ]; then
	echo "PASS"
else
	echo "FAIL"
	echo "  Caddy service is not running"
	FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Check 15: Caddy configuration directory exists
echo -n "Checking Caddy configuration directory... "
CADDY_DIR=$(ssh_execute "$ADMIN_USER" "$IPV4" "[ -d /home/$ADMIN_USER/caddy ] && echo 'exists'" || echo "")
if [ "$CADDY_DIR" = "exists" ]; then
	echo "PASS"
else
	echo "FAIL"
	echo "  Caddy configuration directory does not exist"
	FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Check 16: Caddy responds with expected content
echo -n "Checking Caddy server response... "
CADDY_RESPONSE=$(curl -L -s --connect-timeout 10 "http://$FQDN" || echo "")
if echo "$CADDY_RESPONSE" | grep -q "Hello from $FQDN"; then
	echo "PASS"
else
	echo "FAIL"
	echo "  Server did not return expected 'Hello from $FQDN' content"
	echo "  Response: $CADDY_RESPONSE"
	FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Check 17: HTTPS redirect is working
echo -n "Checking HTTPS redirect... "
HTTPS_RESPONSE=$(curl -s -I --connect-timeout 10 "https://$FQDN" | head -n 1 || echo "")
if echo "$HTTPS_RESPONSE" | grep -q "200 OK"; then
	echo "PASS"
else
	echo "WARN (HTTPS may not be ready yet - certificate provisioning can take time)"
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
