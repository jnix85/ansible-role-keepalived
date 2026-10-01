# Project Context: ansible-role-keepalived

**Type:** Ansible Role / Infrastructure Automation  
**Target:** Debian 12 (Bookworm), Debian 13 (Trixie), Ubuntu Noble/Resolute  
**Purpose:** Installs distribution-packaged Keepalived and manages unicast VRRP instances and native IPVS `virtual_server` load balancing (e.g. fronting clustered Technitium DNS instances).

---

## Overview

- Manages Keepalived daemon installation, systemd service management, and `/etc/keepalived/keepalived.conf`.
- Configures unicast VRRP instances (VIP failover) and IPVS virtual servers (TCP/UDP load balancing with health checks).
- Writes `/etc/keepalived/keepalived.conf` with mode `0600` and `no_log: true` because it carries VRRP authentication passwords.

---

## Repository Layout

```
.
├── AGENTS.md                         # This file (AI source of truth)
├── CLAUDE.md -> AGENTS.md            # Symlink for Claude Code
├── README.md                         # Detailed documentation
├── ansible.cfg                       # Inventory and execution configuration
├── defaults/main.yml                 # Default variables
├── tasks/main.yml                    # Installation and configuration tasks
├── handlers/main.yml                 # Service reload / restart handlers
├── templates/keepalived.conf.j2      # Main keepalived configuration template
├── inventory/
│   ├── hosts.yml                     # keepalived group
│   └── group_vars/keepalived/        # Vars and encrypted vault.yml
└── playbooks/
    └── site.yml                      # Main playbook
```

---

## Key Role Variables

| Variable | Default | Description |
|---|---|---|
| `keepalived_package_name` | `keepalived` | Package name to install |
| `keepalived_service_name` | `keepalived` | Systemd service name |
| `keepalived_vrrp_instances` | `[]` | List of VRRP instance definitions (VIPs, interfaces, priorities, unicast peers) |
| `keepalived_virtual_servers` | `[]` | List of IPVS virtual server definitions (real servers, health checks, lb algorithms) |
| `keepalived_track_scripts` | `[]` | Optional health-check tracking scripts |

---

## Common Commands

```bash
# Syntax check
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --syntax-check

# Dry run with vault password prompt
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --vault-id keepalived@prompt --check --diff

# Execute playbook
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --vault-id keepalived@prompt
```
