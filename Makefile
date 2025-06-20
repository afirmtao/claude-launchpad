.PHONY: help provision login lint format mount unmount tag

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*##"; printf ""} /^[a-zA-Z_-]+:.*?##/ { printf "  %-15s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

requirements: ## Install Ansible requirements (roles and collections)
	@./scripts/requirements.sh

lint: ## Lint YAML files
	@./scripts/lint.sh

format: ## Format YAML and shell scripts
	@./scripts/format.sh

provision: ## Provision server (usage: make provision FQDN=domain.com)
	@./scripts/provision.sh $(FQDN)

verify: ## Verify server setup (usage: make verify FQDN=domain.com)
	@./scripts/verify.sh $(FQDN)

login: ## SSH login to server (usage: make login FQDN=domain.com)
	@./scripts/login.sh $(FQDN)

login-base: ## Login to base container (usage: make login-base FQDN=domain.com)
	@./scripts/login.sh $(FQDN) "docker exec -it base zellij attach --create default"

mount: ## Mount server stacks directory locally (usage: make mount FQDN=domain.com)
	@./scripts/mount.sh $(FQDN) mount

unmount: ## Unmount server stacks directory (usage: make unmount FQDN=domain.com)
	@./scripts/mount.sh $(FQDN) unmount

tag: ## Run specific playbook tag (usage: make tag FQDN=domain.com TAG=metrics-container)
	@./scripts/tag.sh $(FQDN) $(TAG)
