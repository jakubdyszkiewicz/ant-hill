#!/bin/bash
ansible-playbook --vault-password-file <(cat <<<"$VAULT_PASSWORD") -i inventory main.yaml --limit=ant-services
