# Ansible VPS Provisioning

A comprehensive Ansible project for provisioning and securing Debian 12 VPS servers with Docker support.

## Features

- **System Updates**: Automated package updates and reboot management
- **User Management**: Non-root admin user with SSH key authentication
- **Swap Configuration**: Optimal swap file setup based on system memory
- **Time Synchronization**: Timezone configuration and NTP setup
- **Security Hardening**: OS hardening, SSH hardening, and UFW firewall
- **Docker Installation**: Docker with user permissions for sudo-less access
- **Caddy Web Server**: Automatic HTTPS with Let's Encrypt, security headers, and auto-reload
- **Development Container**: Arch Linux container with development tools and claude-code
- **Comprehensive Verification**: Automated checks for all configurations

## Quick Start

1. **Install Requirements**
   ```bash
   make requirements
   ```

2. **Configure Server**
   - Copy `inventories/host_vars/example.com.yml` to your server's FQDN
   - Update server details, SSH key, and configuration

3. **Provision Server**
   ```bash
   make provision FQDN=your-server.com
   ```

4. **Verify Setup**
   ```bash
   make verify FQDN=your-server.com
   ```

## Available Commands

| Command | Description |
|---------|-------------|
| `make help` | Show all available commands |
| `make requirements` | Install Ansible requirements |
| `make provision FQDN=domain.com` | Provision a new server |
| `make verify FQDN=domain.com` | Verify server configuration |
| `make login FQDN=domain.com` | SSH into server as admin user |
| `make login-base FQDN=domain.com` | Login to base development container |
| `make lint` | Lint YAML files |
| `make format` | Format YAML and shell scripts |

## Project Structure

```
├── inventories/
│   ├── hosts.ini                    # Dynamic inventory
│   ├── group_vars/all.yml          # Global variables
│   └── host_vars/
│       ├── example.com.yml         # Example configuration
│       └── your-server.yml         # Server-specific config
├── roles/
│   ├── system-update/              # Package updates
│   ├── user-management/            # Admin user setup
│   ├── swap-setup/                 # Swap configuration
│   ├── time-setup/                 # Timezone & NTP
│   ├── security-hardening/         # Security configuration
│   ├── docker-setup/               # Docker installation
│   ├── caddy-setup/                # Caddy web server
│   └── base-container/             # Development container
├── scripts/                        # Helper scripts
├── playbook-provision.yml          # Main playbook
├── requirements.yml                # External roles/collections
└── Makefile                        # Task launcher
```

## Configuration

### Host Variables

Each server requires a host_vars file with the following configuration:

```yaml
---
# Server connection details
ansible_host: 192.168.1.100
ansible_host_ipv6: "2001:db8::1"

# Server configuration
fqdn: your-server.com
server_timezone: Europe/Berlin

# Firewall configuration
firewall_allowed_ports:
  - port: "22"
    proto: "tcp"
  - port: "80"
    proto: "tcp"
  - port: "443"
    proto: "tcp"

# Admin user configuration
admin_user: admin
admin_ssh_key: "ssh-ed25519 AAAAC3... your-key-here"
```

### Security Features

- **OS Hardening**: Applied via `devsec.hardening` collection
- **SSH Hardening**: Secure SSH configuration with key-only authentication
- **UFW Firewall**: Configured with minimal required ports
- **Root Access**: SSH root login disabled after setup
- **User Isolation**: Non-root admin user with sudo access

### Docker Integration

- Docker installed via `geerlingguy.docker` role
- Admin user added to docker group for sudo-less access
- Docker service enabled and started automatically
- Verification checks ensure proper installation

### Caddy Web Server

- Automatic HTTPS with Let's Encrypt certificates
- Security headers (HSTS, XSS protection, content type options)
- Structured JSON logging with rotation
- Hardened systemd service configuration
- Automatic configuration reload when Caddyfile changes (zero-downtime)
- Admin API enabled on localhost:2019 for seamless updates

### Development Container

- Arch Linux base with development tools (base-devel, nodejs, npm)
- Docker tools (docker, docker-compose, docker-buildx) with host socket access
- Claude-code CLI tool pre-installed
- Zellij terminal multiplexer with Dracula theme and session persistence
- Home directory and Docker socket mounted from host

## Verification Checks

The verification script checks:

- ✅ Admin user SSH access
- ✅ Admin user sudo privileges
- ✅ Swap configuration and swappiness
- ✅ SSH key authentication
- ✅ Timezone configuration
- ✅ NTP synchronization
- ✅ UFW firewall status
- ✅ Root SSH login disabled
- ✅ /tmp directory writable
- ✅ Docker installation
- ✅ Docker user permissions
- ✅ Caddy web server installation and HTTPS
- ✅ Caddy automatic configuration reload functionality
- ✅ Base container running with all tools
- ✅ Development tools (claude-code, docker, zellij) in container

## Requirements

- Ansible >= 2.1
- Python 3.x
- SSH access to target servers
- External roles: `geerlingguy.security`, `geerlingguy.docker`
- External collections: `devsec.hardening`

## Best Practices

- Keep connection variables (user, SSH args) out of host_vars
- Use the Makefile for consistent task execution
- Run verification after each provisioning
- Test changes on non-production servers first
- Follow security guidelines in CLAUDE.md

## License

This project follows Ansible best practices and is designed for educational and production use.