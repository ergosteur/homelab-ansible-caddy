# homelab-ansible-caddy

Infrastructure-as-code for building and deploying a **custom Caddy reverse proxy** in a homelab environment using **Ansible** and **xcaddy**.

This project:

- Builds a Caddy binary with your chosen plugins
- Deploys it to one or more reverse proxy servers
- Templates `Caddyfile`s from Ansible variables for multiple domains/groups
- Manages systemd unit files for Caddy

---

## 🚀 Quick Start

### 1. Clone the repo

```bash
git clone https://github.com/ergosteur/homelab-ansible-caddy.git
cd homelab-ansible-caddy
```

### 2. Prepare the build/Ansible host

Run the setup script on your Ubuntu 24.04+ VM or server:

```bash
chmod +x setup-caddy-ansible.sh
./setup-caddy-ansible.sh
```

This will:

- Update the system
- Install Python, Ansible (in a venv), Go, and `xcaddy`
- Set up PATH entries for Go/Ansible

---

## ⚙️ Configuration

### Inventory & Variables

Edit your Ansible inventory at:

```
ansible/inventory/hosts.yml
```

### Global Variables

| Variable | Description | Default |
| :--- | :--- | :--- |
| `caddy_admin_email` | Email used for Let's Encrypt/ACME registration. | `caddy_admin@1qaz.ca` |
| `cloudflare_api_token` | **Required.** Token for DNS challenges (Cloudflare plugin). | `None` |
| `caddy_admin_off` | If `true`, disables the admin API (`admin off`). | `false` |

### Site Configuration (`caddy_sites`)

Define your sites in the `caddy_sites` list variable. Each item is a dictionary supporting the following keys:

#### Basic Proxying
| Key | Type | Description |
| :--- | :--- | :--- |
| `domain` | String/List | **Required.** One or more domains for this site block (e.g., `example.com` or `["example.com", "www.example.com"]`). |
| `upstream` | String | Target backend address (e.g., `10.0.0.5:8080` or `https://10.0.0.5`). |
| `upstream_sni` | String | (Optional) Custom SNI (`tls_server_name`) to send when proxying to HTTPS upstreams. Defaults to the site's `domain`. |
| `skip_upstream_cert_verify` | Boolean | If `true`, adds `tls_insecure_skip_verify` to the proxy transport. |

#### TLS & Network
| Key | Type | Description |
| :--- | :--- | :--- |
| `tls_internal` | Boolean | If `true`, uses Caddy's internal CA instead of Let's Encrypt (good for `.local` domains). |
| `cache_static` | Boolean | Enables the `cache` directive (requires cache-handler plugin). |
| `cache_ttl` | String | TTL for the cache (e.g., `1h`, `5m`). Defaults to `5m`. |

#### Routing & Responses
| Key | Type | Description |
| :--- | :--- | :--- |
| `serve_static` | Boolean | If `true`, serves static files instead of proxying. |
| `root_path` | String | Web root for static files. Defaults to `/var/www/html`. |
| `redirect` | Dict | Perform a redirect. keys: `target` (url), `code` (default `permanent`). |
| `default_response` | String | Fixed text response if no other rules match. |
| `default_status` | Integer | Status code for `default_response`. Defaults to `200`. |

#### Advanced Routing
| Key | Type | Description |
| :--- | :--- | :--- |
| `subdomain_upstreams` | List | List of subdomains to proxy separately. Keys: `subdomain`, `upstream`. |
| `upstreams` | List | Path-based routing rules. Keys: `path`, `target`. |

### Example Inventory

```yaml
all:
  vars:
    ansible_user: ubuntu
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
  children:
    proxy_group1:
      vars:
        caddy_admin_email: "ergosteur@example.com"
        cloudflare_api_token: "cf_token_for_group1"
        caddy_sites:
          # Standard Reverse Proxy
          - domain: "blog.example.com"
            upstream: "blog-backend.homelab.arpa:8080"
            cache_static: true
            cache_ttl: "1h"

          # HTTPS Proxy with specific SNI and insecure skip
          - domain: "secure.example.com"
            upstream: "https://10.2.2.60"
            upstream_sni: "internal-app.local" 
            skip_upstream_cert_verify: true

          # Path-based routing
          - domain: "api.example.com"
            upstreams:
              - path: "/v1/*"
                target: "10.0.0.10:8000"
              - path: "/v2/*"
                target: "10.0.0.11:9000"
            default_response: "API Root"

          # Wildcard Subdomain Routing
          - domain: "*.apps.example.com"
            subdomain_upstreams:
              - subdomain: "grafana"
                upstream: "10.0.0.50:3000"
              - subdomain: "prometheus"
                upstream: "10.0.0.51:9090"
      hosts:
        vps-proxy.example.com:
    proxy_group2:
      vars:
        caddy_admin_email: "ergosteur@contoso.com"
        cloudflare_api_token: "cf_token_for_group2"
        caddy_sites:
          - domain: "dashboard.homelab.arpa"
            upstream: "dashboard-api.homelab.arpa:9000"
            cache_static: false
          - domain: "files.contoso.com"
            upstream: "files-backend.homelab.arpa:7000"
            cache_static: true
            cache_ttl: "6h"
      hosts:
        dmz-proxy.example.com:
```

💡 Real secrets/tokens should not be committed. Use sample/example values for public files.

---

## 🔨 Makefile Targets

| Target         | Description                                                                 |
| -------------- | --------------------------------------------------------------------------- |
| `make build`   | Build Caddy with plugins (skips if binary exists; use `FORCE=1` to rebuild) |
| `make install` | Copy binary to `/usr/bin/caddy` (no restart)                                |
| `make update`  | Stop Caddy, replace binary, restart service                                 |
| `make restart` | Restart Caddy service                                                       |
| `make test`    | Run smoke tests and generate `test_report.csv`                              |
| `make deploy`  | Build & run Ansible playbook (`LIMIT` optional)                             |
| `make ssh-bootstrap` | Copy local SSH key to all hosts in the inventory (requires `yq`)         |
| `make clean`   | Remove built binary                                                         |

### Examples

Build binary:

```bash
make build
```

Force rebuild:

```bash
make build FORCE=1
```

Deploy to all hosts:

```bash
make deploy
```


Deploy to one host:

```bash
make deploy LIMIT=vps-proxy.example.com
```

Deploy to a group:

```bash
make deploy LIMIT=proxy_group2
```

---

## 🧩 Notes

- The first time you run `xcaddy` without arguments, you may see:
  ```
  go: cannot match "all": go.mod file not found...
  ```
  This is **normal** — it just means you ran `xcaddy` directly without a build command.
- All service setup, configs, and TLS settings are handled by Ansible roles and templates.
- Built binaries are stored in `ansible/playbooks/roles/caddy/files/build/caddy.custom` and ignored by Git.

---

## 📜 License

MIT — do whatever you want, but no guarantees.

