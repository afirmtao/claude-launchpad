# Ansible Project Best Practices

## Directory Structure

Follow this standard directory layout:

```
inventories/
   hosts.ini             # inventory file
   group_vars/
      all.yml            # variables for all hosts
   host_vars/
      hostname.yml       # variables for specific hosts
roles/
   system-update/        # system package updates
   user-management/      # admin user creation
   swap-setup/           # swap file configuration
   time-setup/           # timezone and NTP setup
   security-hardening/   # security configuration
   docker-setup/         # Docker installation
   caddy-setup/          # Caddy web server
   base-container/       # Development container
   metrics-container/    # Monitoring stack
       tasks/
           main.yml      # main tasks file
       handlers/         # event handlers (optional)
       templates/        # jinja2 templates (optional)
       files/           # static files (optional)
       defaults/        # default variables (optional)
playbook-provision.yml   # main provisioning playbook
scripts/                # helper scripts
```

## Role Best Practices

- Use `ansible-galaxy init` to create role structure
- Prefix role variables with role name
- Keep roles focused on single responsibility
- Use defaults/ for default variables
- Use vars/ for role-specific variables
- Document role purpose and variables in meta/main.yml

## Playbook Organization

- Use descriptive names for tasks and plays
- Keep playbooks simple and focused
- Use roles for reusable components
- Separate playbooks by environment or function

## Variable Management

- Use group_vars/ for group-specific variables
- Use host_vars/ for host-specific variables
- Use consistent naming conventions
- Quote strings properly (double quotes for variables, single for literals)
- Pass connection variables (ansible_user, ansible_ssh_common_args) via command line rather than storing in host_vars
- Keep host_vars focused on host-specific configuration, not connection details

## Code Quality

- Use ansible-lint for linting YAML files
- Use yamllint for YAML formatting
- Use shfmt for bash script formatting
- Store projects in version control
- Test playbooks before deployment

## Security

- Avoid storing secrets in plain text
- Use ansible-vault for sensitive data
- Create non-root users with sudo access
- Use SSH key authentication
- Disable root SSH access after setup

## Docker Setup

- Docker is installed via the `docker-setup` role using `geerlingguy.docker`
- Admin user is automatically added to the `docker` group for sudo-less access
- Docker installation occurs after security hardening
- Verification checks ensure Docker is properly installed and accessible

## Caddy Setup

- Caddy is installed from official repository with GPG verification
- Configuration stored in `~/caddy/` directory with `logs/` subdirectory
- Automatic HTTPS with Let's Encrypt certificate provisioning
- Security headers configured (HSTS, XSS protection, content type options)
- Structured JSON logging with log rotation
- Hardened systemd service with security features
- Email for certificate notifications configurable via `caddy_email` variable
- Automatic configuration reload when `~/caddy/Caddyfile` changes via systemd path units
- Admin API enabled on localhost:2019 for zero-downtime configuration updates
- Metrics subdomain (metrics.{fqdn}) configured with reverse proxy to Grafana on port 3000

## Base Container Setup

- Arch Linux container with comprehensive development tools:
  - Base development: base-devel, git, htop
  - Languages & runtimes: nodejs, npm, deno, fish, go, rust
  - Package managers: pacman (system), yay (AUR helper)
- Docker tools (docker, docker-compose, docker-buildx) with host socket access
- Environment configuration:
  - Fish shell with Dracula theme and no welcome message
  - Proper PATH configuration for Go (~/.go/bin), Rust (~/.cargo/bin), and npm (~/.npm-global/bin)
  - Configuration files stored in roles/base-container/files/.config/
- Claude Code CLI tool pre-installed via npm global installation:
  - Installed to `~/.npm-global/bin/claude` for user-only access
  - Supports auto-updates via `claude update` without requiring system permissions
  - Configuration and cache persist in `~/.claude/` between container rebuilds
  - Settings stored in `~/.claude/settings.json` and user memory in `~/.claude/CLAUDE.md`
- Zellij terminal multiplexer with Dracula theme using fish as default shell
- Persistent volume mounts for seamless development:
  - `~/base` → container home directory (preserves npm packages, shell config, and user files)
  - `~/stacks` → container `~/stacks` (project files and development work)
  - `~/caddy` → container `~/caddy` (web server configuration)
  - `~/.claude` → container `~/.claude` (Claude Code settings, credentials, and cache)
- User/group mapping (1000:996) for proper Docker socket permissions (admin user : docker group)
- Container accessible via `make login-base FQDN=domain.com`

## Metrics Container Setup

- Comprehensive monitoring stack using Docker Compose:
  - **Grafana**: Web-based analytics and monitoring platform on port 3000
  - **Prometheus**: Time-series database for metrics collection on port 9090
  - **Node Exporter**: System and hardware metrics on port 9100
  - **cAdvisor**: Container resource usage and performance metrics on port 8080
- Grafana configuration:
  - Admin credentials use `admin_user` and `grafana_admin_password` variables
  - Pre-configured Prometheus data source
  - Dashboard provisioning for Node Exporter and cAdvisor metrics
  - Persistent data storage via Docker volumes
- Network isolation via dedicated monitoring network
- Accessible via HTTPS at `https://metrics.{fqdn}` through Caddy reverse proxy
- Automatic startup and restart policies for all services

## Postfix Setup

- Postfix is installed via the `postfix-setup` role with secure configuration
- SMTP server configured for localhost-only access (inet_interfaces = loopback-only)
- External connections to port 25 are blocked for security
- Applications can send emails via localhost:25 without authentication
- Email aliases configured to forward root mail to admin user
- TLS support enabled for outgoing mail
- Local delivery disabled for security (applications use external relays)
- Verification checks ensure SMTP functionality and security

## Roles Overview

- **system-update**: Updates system packages and checks for reboot requirements
- **user-management**: Creates admin user with sudo access and SSH key authentication
- **swap-setup**: Configures optimal swap file based on system memory
- **time-setup**: Sets timezone and configures NTP synchronization
- **security-hardening**: Applies OS hardening, SSH hardening, and firewall configuration
- **docker-setup**: Installs Docker and configures user permissions
- **postfix-setup**: Installs and configures Postfix SMTP server for local application email delivery
- **caddy-setup**: Installs Caddy web server with automatic HTTPS, security headers, and structured logging
- **caddy-auto-reload**: Configures automatic Caddy configuration reload on file changes
- **base-container**: Creates development container with tools and persistent sessions
- **metrics-container**: Deploys monitoring stack with Grafana, Prometheus, and exporters

## Commands

- `make provision FQDN=domain.com` - Provision a new server
- `make verify FQDN=domain.com` - Verify server configuration
- `make login FQDN=domain.com` - SSH into server as admin user
- `make login-base FQDN=domain.com` - Login to base development container
- `make tag FQDN=domain.com TAG=role` - Run specific playbook tag (e.g., postfix-setup, metrics-container, docker-setup)
- `make mount FQDN=domain.com` - Mount server's ~/stacks directory to ~/mnt/domain.com-stacks
- `make unmount FQDN=domain.com` - Unmount server's stacks directory
- `make requirements` - Install Ansible requirements
- `make lint` - Lint YAML files
- `make format` - Format YAML and shell scripts

## Commit Message Guidelines

- When writing commit messages, don't mention Claude. Or Co-authored by Claude. or generated by Claude.
