# Ant Hill 🐜

Ansible tools to assemble my ~homelab~ ant hill!

## Run

```
$ ansible-galaxy install -r requirements.yaml
$  set -gx BECOME_PASSWORD sudo-password-to-ant-hill # remember about the space to not write this to history!
$  set -gx VAULT_PASSWORD vauilt-password
```

## TODO

### ant-services

- [X] Script Let's encrypt certs into ant-services (done via docker!)
- [X] Place docker services into a ant-services VM and passthrough data disk there
- [ ] Convert as many configs from data disk to static declarative configuration
- [ ] VPN to ant hill
- [X] Move time machine to ant-services?
- [X] Move SMB NAS to ant-services

### ant-hill

- [ ] Install cockpit via Ansible
- [ ] Configure vmbridge0