# Makefile for building a custom Caddy binary with plugins
# This Makefile uses xcaddy to build a custom Caddy binary with specified plugins.
# Ensure you have xcaddy installed: `go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest`
# You can run `make` to build the binary, `make install` to install it, and `make clean` to remove the binary.

# Customize this list with all plugins you want
PLUGINS = \
	--with github.com/caddy-dns/cloudflare \
	--with github.com/kirsch33/realip \
	--with github.com/caddyserver/cache-handler

# Output binary name
CADDY_BIN = caddy.custom

.PHONY: all build install restart clean update

## Default target: build the custom binary
all: build

## Build the custom Caddy binary using xcaddy
build:
	@echo "🚧 Building Caddy with plugins..."
	xcaddy build $(PLUGINS) --output $(CADDY_BIN)

## Stop Caddy, replace the system binary, restart
install:
	@echo "🛠️  Installing custom binary to /usr/bin/caddy..."
	sudo systemctl stop caddy || true
	sudo cp $(CADDY_BIN) /usr/bin/caddy
	sudo chmod +x /usr/bin/caddy
	sudo systemctl start caddy
	@echo "✅ Installed and restarted."

## Rebuild and reinstall in one step
update: build install

## Just restart the Caddy service
restart:
	sudo systemctl restart caddy

## Clean up build artifacts
clean:
	rm -f $(CADDY_BIN)
