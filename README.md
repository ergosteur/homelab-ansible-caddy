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

vps-proxy ansible_host=1.2.3.4
dmz-proxy ansible_host=192.168.1.10
caddy_sites:

### Inventory & Variables

Edit your Ansible inventory at:

```
ansible/inventory/hosts.yml
```

Example:

```yaml
all:
  vars:
    ansible_user: ubuntu
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
    ansible_ssh_private_key_file: "{{ lookup('env', 'HOME') + '/.ssh/id_ed25519' }}"
  children:
    proxy_group1:
      vars:
        caddy_admin_email: "ergosteur@example.com"
        cloudflare_api_token: "cf_token_for_group1"
        caddy_sites:
          - domain: "blog.example.com"
            upstream: "blog-backend.homelab.arpa:8080"
            cache_static: true
            cache_ttl: "1h"
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
| `make deploy`  | Build & run Ansible playbook (`LIMIT` optional)                             |
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

