#!/bin/bash
ansible-playbook --extra-vars "ansible_sudo_pass=$BECOME_PASSWORD" --vault-password-file <(cat <<<"$VAULT_PASSWORD") -i inventory ant-hill.yaml
