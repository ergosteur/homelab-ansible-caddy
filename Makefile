# Makefile for building a custom Caddy binary with plugins
# This Makefile uses xcaddy to build a custom Caddy binary with specified plugins.
# Ensure you have xcaddy installed: `go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest`
# You can run `make` to build the binary, `make install` to install it, and `make clean` to remove the binary.
# The `make update` target is for use on servers with an existing Caddy installation via systemd.

# Ansible environment variables setup
VENV_DIR := $(HOME)/ansible-venv
INVENTORY ?= ansible/inventory/hosts.ini
LIMIT ?=

# Check if venv exists and activate it for Ansible commands
ifdef VIRTUAL_ENV
	ANSIBLE_BIN := ansible-playbook
else
	ifeq ($(wildcard $(VENV_DIR)/bin/activate),)
		$(error ❌ Ansible venv not found at $(VENV_DIR). Run setup-caddy-ansible.sh first.)
	else
		ANSIBLE_BIN := . $(VENV_DIR)/bin/activate && ansible-playbook
	endif
endif


# Customize this list with all plugins you want
PLUGINS = \
	--with github.com/caddy-dns/cloudflare \
	--with github.com/kirsch33/realip \
	--with github.com/caddyserver/cache-handler

# Output binary name
CADDY_BIN = build/caddy.custom

.PHONY: all build install restart clean update

## Default target: build the custom binary
all: build

## Build the custom Caddy binary using xcaddy
build:
	@if [ -f $(CADDY_BIN) ] && [ "$(FORCE)" != "1" ]; then \
		echo "✅ Caddy binary already exists at $(CADDY_BIN). Use 'make build FORCE=1' to rebuild."; \
	else \
		mkdir -p $(dir $(CADDY_BIN)); \
		echo "🚧 Building Caddy with plugins..."; \
		xcaddy build $(PLUGINS) --output $(CADDY_BIN); \
		echo "✅ Build complete: $(CADDY_BIN)"; \
	fi


## Stop Caddy, replace the system binary, restart
update:
	@if [ ! -f $(CADDY_BIN) ]; then \
		echo "❌ Custom binary $(CADDY_BIN) not found. Run 'make build' first."; \
		exit 1; \
	fi
	@echo "🛠️  Installing custom binary to /usr/bin/caddy..."
	sudo systemctl stop caddy || true
	sudo cp $(CADDY_BIN) /usr/bin/caddy
	sudo chmod +x /usr/bin/caddy
	sudo systemctl start caddy
	@echo "✅ Installed and restarted."

## Install the custom binary to /usr/bin/caddy (requires sudo)
install:
	@if [ ! -f $(CADDY_BIN) ]; then \
		echo "❌ Custom binary $(CADDY_BIN) not found. Run 'make build' first."; \
		exit 1; \
	fi
	@echo "🛠️  Installing custom binary to /usr/bin/caddy..."
	sudo cp $(CADDY_BIN) /usr/bin/caddy
	sudo chmod +x /usr/bin/caddy
	@echo "✅ Binary installed. Remember to start Caddy via systemd or Ansible."

## Just restart the Caddy service
restart:
	sudo systemctl restart caddy

## Build and deploy in one step
deploy: build
	@echo "🚀 Deploying to $(LIMIT) (leave LIMIT blank to deploy to all in inventory)"
	$(ANSIBLE_BIN) -i $(INVENTORY) ansible/playbooks/site.yml $(if $(LIMIT),--limit $(LIMIT))


## Clean up build artifacts
clean:
	rm -f $(CADDY_BIN)
