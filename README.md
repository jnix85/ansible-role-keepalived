# Ansible role: Keepalived

Installs distribution-packaged Keepalived and manages VRRP and native IPVS
`virtual_server` configuration on Debian 12/13 and Ubuntu Noble/Resolute.
The included inventory demonstrates a three-node unicast VRRP group fronting
five Technitium DNS instances (one on each Proxmox VE host) on TCP and UDP 53.

## Requirements

- Ansible Core 2.15 or later
- SSH key access as `osadmin`; the user must have sudo rights
- Debian 12 (Bookworm), Debian 13 (Trixie), Ubuntu Noble, or Ubuntu Resolute
- IP forwarding and a valid return path when using the example IPVS NAT mode

Review every inventory address and set the actual network interface before use.
The committed Technitium backends use RFC 5737 documentation addresses and
must be replaced before deployment.

## Quick start

1. Edit `inventory/hosts.yml` and
   `inventory/group_vars/keepalived/vars.yml`.
2. Create the encrypted secret file:

       make vault-init

   Replace `CHANGEME` in the editor with a random value of at most eight
   characters. Keepalived's VRRP `PASS` authentication field is limited to the
   first eight characters. Add `ansible_become_password` only if `osadmin`
   cannot use passwordless sudo. The generated `vault.yml` is ignored by Git;
   explicitly force-add it if encrypted secrets belong in your repository.
3. Inspect targets and run the playbook:

       ansible-inventory --graph
       ansible-playbook playbooks/site.yml --vault-id keepalived@prompt --check --diff
       ansible-playbook playbooks/site.yml --vault-id keepalived@prompt

Vault protects secrets only at rest. The configuration task uses `no_log` and
writes `/etc/keepalived/keepalived.conf` as mode `0600` because it contains the
VRRP password. See the [Ansible Vault guide](https://docs.ansible.com/projects/ansible/latest/vault_guide/vault.html).

## Role variables

`keepalived_vrrp_instances` is a list. Required keys are `name`, `interface`,
`virtual_router_id` (1-255), and `virtual_ipaddresses`. Common optional keys are
`state`, `priority`, `advert_int`, `version`, `preempt`, `unicast_src_ip`,
`unicast_peers`, `auth_type`, `auth_pass`, `track_scripts`, and notification
commands. Every node is deliberately configured as `BACKUP`; election priority
selects the initial owner and avoids a second source of truth.

`keepalived_virtual_servers` accepts `name`, `address`, `port`, `protocol`,
`lb_algo`, `lb_kind`, `delay_loop`, `persistence_timeout`, and `real_servers`.
Each real server requires `address`, with optional `port`, `weight`,
`inhibit_on_failure`, and a `check` mapping. `TCP_CHECK` is the default; a
`MISC_CHECK` may instead supply `misc_path` and `misc_timeout`. UDP services use
a TCP connect check by default because a successful UDP request has no generic,
reliable health-check semantics; point it at a suitable TCP service or provide
a DNS-aware `MISC_CHECK` in production.

Additional top-level variables are documented in `defaults/main.yml` and cover
package/service names, global definitions, tracked scripts, validation, and
service management.

## Technitium design notes

The two VRRP VIPs give clients stable DNS addresses and fail over together.
IPVS distributes TCP and UDP queries received by either VIP across the five
Technitium nodes. The sample assumes each
Proxmox VE host has a Technitium VM or container at a distinct service IP. Run
Keepalived on three dedicated guests or network nodes unless you have explicitly
chosen to install third-party routing services on the PVE hosts themselves.
Ensure the VIP is outside the
DHCP pool, every node shares the same VRID/password/peer list, and firewall rules
allow VRRP protocol 112 between peers plus DNS TCP/UDP 53 from clients.

The sample uses IPVS NAT. That is correct only when replies traverse the active
load balancer and kernel IP forwarding is enabled. Direct routing (`DR`) scales
better, but requires the VIP on a non-ARP-advertising loopback interface on every
Technitium backend. Do not switch `lb_kind` without implementing that network
design.

## Validation

The template is validated with `keepalived --config-test` before installation,
so an invalid render does not replace the active file. Run repository checks
with:

    make syntax
    make lint

The included GitHub Actions workflow runs both checks for pushes and pull
requests. Molecule is intentionally not included.
