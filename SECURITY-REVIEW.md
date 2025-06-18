# Security Review - VPS Provisioning Ansible Project

## Executive Summary

This Ansible project for VPS provisioning shows good security practices in many areas but contains several **CRITICAL** and **HIGH** severity security vulnerabilities that must be addressed immediately. The project uses established security hardening roles and implements basic security measures, but has significant weaknesses in container security, secrets management, and access control.

## Security Findings by Category

### 1. Authentication & Access Control

#### 🔴 CRITICAL: Passwordless Sudo Access for Admin User

**File:** `roles/user-management/tasks/main.yml` (lines 27-34)
**File:** `roles/base-container/templates/Dockerfile.j2` (line 24)

```yaml
- name: Configure passwordless sudo for admin user
  ansible.builtin.lineinfile:
    path: /etc/sudoers.d/{{ admin_user }}
    line: "{{ admin_user }} ALL=(ALL) NOPASSWD:ALL"
```

**Risk:** Grants unrestricted root access without password authentication. If the admin account is compromised, attackers have immediate root access.

**Recommendation:**

- Change to `{{ admin_user }} ALL=(ALL) PASSWD:ALL` to require password
- Or implement time-limited sudo sessions with `timestamp_timeout`
- Consider using specific command allowlists instead of `ALL`

#### 🟠 HIGH: SSH StrictHostKeyChecking Disabled in Scripts

**File:** `scripts/common.sh` (line 49)

```bash
ssh -o ConnectTimeout="$timeout" -o BatchMode=yes -o StrictHostKeyChecking=no "$user@$host" "exit" 2>/dev/null
```

**Risk:** Disables host key verification, making the system vulnerable to man-in-the-middle attacks.

**Recommendation:**

- Remove `StrictHostKeyChecking=no`
- Implement proper host key management
- Use `StrictHostKeyChecking=accept-new` for first connections

#### 🟡 MEDIUM: Hardcoded SSH Key in Configuration

**File:** `inventories/host_vars/persist.lol.yml` (lines 21-22)

**Risk:** SSH keys stored in version control can be exposed if repository is compromised.

**Recommendation:**

- Move SSH keys to encrypted ansible-vault files
- Use environment variables or external key management
- Rotate keys if already committed to git history

### 2. Network Security

#### 🟠 HIGH: Network Host Mode in Container

**File:** `roles/base-container/templates/compose.yml.j2` (line 8)

```yaml
network_mode: host
```

**Risk:** Container shares host network namespace, bypassing Docker's network isolation and potentially exposing host services.

**Recommendation:**

- Use bridge networking with explicit port mappings
- Create custom Docker networks for isolation
- Only expose necessary ports explicitly

#### 🟡 MEDIUM: Firewall IP Forwarding Enabled

**File:** `roles/security-hardening/defaults/main.yml` (line 7)

```yaml
sysctl_overwrite:
  net.ipv4.ip_forward: 1
```

**Risk:** Allows the server to forward network traffic, potentially bypassing firewall rules.

**Recommendation:**

- Disable IP forwarding unless specifically required for routing/NAT
- If needed, implement strict iptables rules to control forwarding

#### 🔵 LOW: Caddy Admin API Exposed

**File:** `roles/caddy-setup/templates/Caddyfile.j2` (line 4)

```
admin localhost:2019
```

**Risk:** Admin API accessible on localhost, could be exploited by other local services or users.

**Recommendation:**

- Disable admin API if not needed: `admin off`
- If needed, implement authentication or restrict to specific interfaces

### 3. Container Security

#### 🔴 CRITICAL: Docker Socket Mounted in Container

**File:** `roles/base-container/templates/compose.yml.j2` (line 16)

```yaml
- /var/run/docker.sock:/var/run/docker.sock
```

**Risk:** Grants container full control over Docker daemon, equivalent to root access on host.

**Recommendation:**

- Use Docker-in-Docker (DinD) instead of socket mounting
- Implement Docker socket proxy with restricted permissions
- Use rootless Docker or Podman for better isolation

#### 🔴 CRITICAL: Privileged Container User with Host Directory Access

**File:** `roles/base-container/templates/compose.yml.j2` (lines 11-14)

```yaml
user: "1000:996"
volumes:
  - /home/{{ admin_user }}:/home/{{ admin_user }}
```

**Risk:** Container can access and modify all admin user files on host, including SSH keys and sensitive data.

**Recommendation:**

- Mount only specific directories needed for development
- Use read-only mounts where possible
- Implement proper container user isolation

#### 🟠 HIGH: Running Latest Base Image Without Version Pinning

**File:** `roles/base-container/templates/Dockerfile.j2` (line 1)

```dockerfile
FROM archlinux:latest
```

**Risk:** Base image can change unexpectedly, potentially introducing vulnerabilities.

**Recommendation:**

- Pin to specific image versions/tags
- Regularly update and test with new versions
- Use minimal base images when possible

#### 🟠 HIGH: AUR Helper Installation from Source

**File:** `roles/base-container/templates/Dockerfile.j2` (lines 34-38)

```dockerfile
RUN git clone https://aur.archlinux.org/yay.git /tmp/yay && \
    cd /tmp/yay && \
    makepkg -si --noconfirm
```

**Risk:** Building packages from source without verification can introduce supply chain attacks.

**Recommendation:**

- Verify GPG signatures of AUR packages
- Use official repositories when possible
- Pin specific commits/versions of AUR helper

### 4. Secrets Management

#### 🟠 HIGH: Credentials Stored in Plain Text

**Files:** Multiple host_vars files contain sensitive data unencrypted

**Risk:** SSH keys, email addresses, and configuration details stored in plain text.

**Recommendation:**

- Use ansible-vault to encrypt sensitive variables
- Implement external secrets management (HashiCorp Vault, etc.)
- Separate sensitive data from configuration

#### 🟡 MEDIUM: SSH Key Handling in Scripts

**File:** `scripts/inventory.sh` (lines 22-31)

```bash
read -p "Enter SSH public key (leave empty to use ~/.ssh/id_rsa.pub): " SSH_KEY
if [ -z "$SSH_KEY" ]; then
    if [ -f ~/.ssh/id_rsa.pub ]; then
        SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
```

**Risk:** SSH keys handled in shell variables and written to files without proper validation.

**Recommendation:**

- Validate SSH key format before using
- Use secure methods for key input (avoid echo)
- Implement key rotation mechanisms

### 5. Input Validation & Configuration

#### 🟡 MEDIUM: Insufficient Input Validation in Scripts

**File:** `scripts/inventory.sh` (lines 63-66)

```bash
sed -i "s/ansible_host: .*/ansible_host: $IPV4/" "$HOST_VARS_FILE"
sed -i "s/fqdn: .*/fqdn: $FQDN/" "$HOST_VARS_FILE"
sed -i "s/admin_user: .*/admin_user: $ADMIN_USER/" "$HOST_VARS_FILE"
sed -i "s|admin_ssh_key: .*|admin_ssh_key: \"$SSH_KEY\"|" "$HOST_VARS_FILE"
```

**Risk:** User input directly substituted into sed commands without validation.

**Recommendation:**

- Validate IP addresses, FQDNs, usernames before use
- Escape special characters in sed patterns
- Use more secure templating methods

#### 🔵 LOW: File Permission Issues

**File:** `roles/security-hardening/tasks/main.yml` (line 24)

```yaml
mode: "0644"
```

**Risk:** Hardening flag file is world-readable.

**Recommendation:**

- Use restrictive permissions (0600) for security flags
- Ensure consistent permission management across all files

### 6. Supply Chain Security

#### 🟡 MEDIUM: External Repository Dependencies

**File:** `roles/caddy-setup/vars/main.yml`

```yaml
caddy_gpg_key_url: "https://dl.cloudsmith.io/public/caddy/stable/gpg.key"
caddy_repository: "deb https://dl.cloudsmith.io/public/caddy/stable/deb/debian any-version main"
```

**Risk:** Dependency on external repositories without integrity verification.

**Recommendation:**

- Pin GPG key fingerprints instead of downloading
- Use repository mirrors or internal mirrors
- Implement checksum verification

#### 🟡 MEDIUM: Ansible Galaxy Dependencies

**File:** `requirements.yml`

**Risk:** External role dependencies without version pinning in some cases.

**Recommendation:**

- Pin specific versions of all external roles
- Regularly audit and update dependencies
- Use internal role mirrors when possible

## Severity Summary

| Severity | Count | Issues |
| ----------- | ----- | ---------------------------------------------------------------------------- |
| 🔴 CRITICAL | 3 | Passwordless sudo, Docker socket mount, Host directory access |
| 🟠 HIGH | 5 | SSH bypass, Host networking, Latest images, AUR builds, Plain text secrets |
| 🟡 MEDIUM | 6 | Hardcoded keys, IP forwarding, SSH handling, Input validation, External deps |
| 🔵 LOW | 2 | Admin API, File permissions |

## Remediation Priority

### Immediate Actions Required (CRITICAL/HIGH)

1. **Remove passwordless sudo configuration** - Require password authentication
1. **Disable StrictHostKeyChecking bypass** - Implement proper host key management
1. **Implement proper container isolation** - Remove host networking and Docker socket mounting
1. **Pin container base image versions** - Use specific tags instead of `latest`
1. **Encrypt sensitive data** - Use ansible-vault for SSH keys and secrets

### Medium Priority Actions

1. Implement proper secrets management system
1. Add comprehensive input validation to all scripts
1. Review and restrict firewall configurations
1. Implement proper SSH key management workflow

### Long-term Security Improvements

1. Implement infrastructure as code scanning (ansible-lint, security scanners)
1. Add automated security testing to CI/CD pipeline
1. Implement log monitoring and alerting
1. Regular security audits and penetration testing
1. Implement backup and disaster recovery procedures

## Positive Security Practices Identified

✅ **Use of established security hardening roles** (`devsec.hardening`, `geerlingguy.security`)\
✅ **SSH key-based authentication** instead of passwords\
✅ **UFW firewall configuration** with minimal required ports\
✅ **Non-root admin user creation** with sudo access\
✅ **SSH root login disabled** after initial setup\
✅ **System package updates** as part of provisioning\
✅ **Caddy automatic HTTPS** with Let's Encrypt certificates\
✅ **Security headers configuration** in web server

## Conclusion

While this project demonstrates good understanding of basic security principles through the use of established hardening roles, it contains several critical vulnerabilities that provide pathways for privilege escalation and system compromise. The most critical issues involve container security and privileged access management.

**Immediate remediation of CRITICAL and HIGH severity findings is essential before deploying to production environments.**

The project would benefit from implementing a comprehensive security framework including:

- Secrets management strategy
- Container security best practices
- Input validation and sanitization
- Regular security assessments
- Automated security testing

______________________________________________________________________

_Security review conducted on: $(date)_\
_Reviewer: Automated Security Analysis_\
_Next review due: 90 days from implementation of critical fixes_
