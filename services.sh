#!/bin/bash
ANSIBLE_ALLOW_BROKEN_CONDITIONALS=true ansible-playbook --vault-password-file <(cat <<<"$VAULT_PASSWORD") -i "${INVENTORY:-inventory}" ant-services.yaml
