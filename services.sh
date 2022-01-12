#!/bin/bash
ansible-playbook --vault-password-file <(cat <<<"$VAULT_PASSWORD") -i inventory ant-services.yaml
