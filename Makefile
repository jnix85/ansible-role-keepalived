.PHONY: lint syntax inventory-check vault-init

lint:
	ansible-lint

syntax:
	ansible-playbook -i tests/inventory.yml tests/test.yml --syntax-check

inventory-check:
	ansible-inventory -i inventory/hosts.yml --graph

vault-init:
	test ! -e inventory/group_vars/keepalived/vault.yml
	cp inventory/group_vars/keepalived/vault.yml.example inventory/group_vars/keepalived/vault.yml
	ansible-vault encrypt --vault-id keepalived@prompt inventory/group_vars/keepalived/vault.yml

