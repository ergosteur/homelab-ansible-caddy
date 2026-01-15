# Project Context: Homelab Ansible Caddy

## Overview
This project manages the deployment of a custom Caddy reverse proxy using Ansible. It builds a custom Caddy binary with specific plugins (`xcaddy`) and deploys it to target hosts defined in the inventory.

## Architecture
- **Build Host:** The machine running Ansible (localhost or a dedicated controller). Compiles the Caddy binary.
- **Target Hosts:** Servers (e.g., `caddy-rproxy1`, `caddy-rproxy2`) where Caddy is deployed.
- **Orchestration:** Ansible Playbooks (`site.yml`) manage the state of the target hosts.

## Key Components

### 1. Build System (`Makefile`)
- Wraps `xcaddy` and `ansible-playbook`.
- `make build`: Compiles `caddy` with plugins (Cloudflare DNS, RealIP, Cache, Transform Encoder).
- `make deploy`: Runs the Ansible playbook.

### 2. Ansible Role (`ansible/playbooks/roles/caddy`)
- **Templates:**
  - `Caddyfile.j2`: The core logic. Generates the Caddy configuration based on `caddy_sites` variable.
  - `caddy.service`: Systemd unit file.
- **Tasks:**
  - `main.yml`: User setup, binary distribution, config generation, service management.

### 3. Configuration (`ansible/inventory/hosts.yml`)
- Defines `caddy_sites` list.
- Supports advanced routing:
  - Simple reverse proxy
  - Wildcard subdomains (`subdomain_upstreams`)
  - Path-based routing (`upstreams`)
  - **New:** HTTPS Upstream SNI support (`upstream_sni`, `skip_upstream_cert_verify`).

## Recent Changes (Jan 2026)
- **HTTPS Upstream Support:** Updated `Caddyfile.j2` to automatically handle SNI when the upstream target is `https://`.
  - Automatically sets `tls_server_name` to the site domain or `upstream_sni`.
  - Supports `tls_insecure_skip_verify` via `skip_upstream_cert_verify` variable.
- **Documentation:** Updated README with full configuration reference and multi-group examples.

## Developer Notes
- **Git:** Project is version controlled. `caddy` binary is ignored.
- **Safety:** Always verify `Caddyfile` generation with `ansible-playbook --check` or by inspecting the generated file on a test host before full rollout.
- **Logs:** Caddy logs are stored in `/var/log/caddy/`.
