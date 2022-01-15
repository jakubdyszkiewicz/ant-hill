# Ant Hill 🐜

Ansible tools to assemble my ~homelab~ ant hill!

## Run

```bash
$ ansible-galaxy install -r requirements.yaml
$  set -gx BECOME_PASSWORD sudo-password-to-ant-hill # remember about the space to not write this to history!
$  set -gx VAULT_PASSWORD vauilt-password
$ ./hill.sh # configure hill that provisions ant-dev and ant-services
$ ./dev.sh # configure ant-dev
$ ./services.sh # configure ant-services
```

## TODO

### ant-services

- [X] Script Let's encrypt certs into ant-services (done via docker!)
- [X] Place docker services into a ant-services VM and passthrough data disk there
- [X] Move time machine to ant-services?
- [X] Move SMB NAS to ant-services
- [ ] Convert as many configs from data disk to static declarative configuration
    - [X] samba
    - [ ] ddclient
    - [ ] gickup
    - [ ] rclone
    - [ ] swag
    - [ ] kong
    - [ ] prometheus
    - [ ] grafana
- [ ] Do not expose port from docker containers, hide everything behind Kong

#### Observability

- [ ] Node exporter does not report proper network stats :(

### ant-hill

- [ ] VPN to ant hill
- [ ] Install cockpit via Ansible
- [ ] Configure vmbridge0