# Ant Hill 🐜

Ansible tools to assemble my ~homelab~ ant hill!

## Run

```bash
$ ansible-galaxy install -r requirements.yaml
$  export BECOME_PASSWORD=sudo-password-to-ant-hill # remember about the space to not write this to history!
$  export VAULT_PASSWORD=vauilt-password
$ ./hill.sh # configure hill that provisions ant-dev and ant-services
$ ./dev.sh # configure ant-dev
$ ./services.sh # configure ant-services
```

## TODO

- [ ] Put zigbee2mqtt on ant-services instead of ant-hill (can't mount USB zigbee adapter)
- [ ] Configure log retention
- [ ] Slack channel alarms
- [ ] VPN to ant hill (Tailscale is broken)
- [ ] Automate Sensors with https://hub.docker.com/r/amkay/sensor-exporter + Podman
- [ ] Try to get rid of additional network card?

## Updates

Last `ant-services` container updates: 08.02.2025