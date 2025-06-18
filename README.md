# Claude Launchpad 🚀

A live development tool for provisioning Debian 12 VPS servers with Docker and development containers.

## Features

- Automated VPS provisioning with security hardening
- Docker installation with user permissions
- Caddy web server with automatic HTTPS
- Arch Linux development container with modern tools
- Zellij terminal multiplexer with fish shell

## Quick Start

1. **Install requirements**

   ```bash
   make requirements
   ```

2. **Provision server**

   ```bash
   make provision FQDN=your-server.com
   ```

   The script will prompt you for:
   - SSH public key (defaults to ~/.ssh/id_rsa.pub)
   - IPv4 address (auto-resolved from DNS if empty)
   - IPv6 address (auto-resolved from DNS if empty)
   - Admin username (defaults to "admin")

3. **Access development container**

   ```bash
   make login-base FQDN=your-server.com
   ```

## Commands

| Command | Description |
| --------------------------------- | ---------------------------- |
| `make provision FQDN=domain.com` | Provision server |
| `make verify FQDN=domain.com` | Verify configuration |
| `make login FQDN=domain.com` | SSH to server |
| `make login-base FQDN=domain.com` | Access development container |
| `make lint` | Lint YAML files |
| `make format` | Format code |

## Development Container

The base container includes:

- Arch Linux with development tools (nodejs, npm, deno, fish, go, rust, git, htop)
- Package managers (pacman, yay AUR helper)
- Docker tools with host socket access
- Claude-code CLI pre-installed
- Zellij with fish shell and Dracula theme
- Home directory mounted from host

## Project Structure

```
├── inventories/          # Server configurations
├── roles/               # Ansible roles
│   ├── system-update/   # Package updates
│   ├── user-management/ # Admin user setup
│   ├── security-hardening/ # Security configuration
│   ├── docker-setup/    # Docker installation
│   ├── caddy-setup/     # Web server
│   └── base-container/  # Development container
├── scripts/             # Helper scripts
└── playbook-provision.yml # Main playbook
```

## Security Notice

This project contains multiple critical security vulnerabilities including:

- Passwordless sudo access
- Docker socket mounting in containers
- SSH host key verification bypass
- Plain text credential storage

Review `SECURITY-REVIEW.md` for complete security analysis before use.

## Requirements

- Ansible >= 2.1
- Python 3.x
- SSH access to target servers
