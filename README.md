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
- [X] Convert as many configs from data disk to static declarative configuration
    - [X] samba
    - [X] ddclient
    - [X] gickup
    - [X] rclone
    - [X] swag
    - [X] kong
    - [X] prometheus
    - [X] grafana
- [X] Do not expose port from docker containers, hide everything behind Kong
- [X] Try to remove root user from Kong

#### Observability

- [X] Node exporter does not report proper network stats :(
- [X] Report Public IP # it is reported by speedtest exporter
- [ ] Move metrics to location that can survive VM removal, but do not backup them
- [ ] Log retention
- [ ] Slack channel alarms

### ant-hill

- [ ] VPN to ant hill
- [ ] Install cockpit via Ansible
- [ ] Configure vmbridge0