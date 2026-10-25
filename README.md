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

## Observability access for an AI agent

The dedicated `kong_observability_api_key` is expected in the encrypted
`vars/secrets.yaml`. Do not reuse or give the agent `kong_api_key`.
Deploy using `./services.sh` and ensure `grafana-obs-api.<ant_domain>` and
`prometheus-obs-api.<ant_domain>` resolve to Kong and are covered by its TLS certificate.

The dedicated key enables both observability endpoints without a client
certificate. Send it in the `apikey` header:

```bash
curl --fail-with-body "https://grafana-obs-api.${ANT_DOMAIN}/api/search" \
  -H "apikey: ${OBSERVABILITY_API_KEY}"
curl --fail-with-body "https://prometheus-obs-api.${ANT_DOMAIN}/api/v1/query?query=up" \
  -H "apikey: ${OBSERVABILITY_API_KEY}"
```

Kong ACLs allow the `observability-api` consumer and group only on `grafana-obs-api`
and `prometheus-obs-api`. All existing
key-auth services (`sonarr-api`, `radarr-api`, `paperless-api`, `ghostfolio-api`,
`kroczek-api`) require the `internal-api` group assigned to the existing
`jakub-apikey` consumer. The existing key cannot access either observability API;
the normal `grafana` and `prometheus` hostnames still require mTLS.

After deployment, verify that the AI key reaches `/api/search` on `grafana-obs-api`
and `/api/v1/query?query=up` on `prometheus-obs-api`, returns HTTP 403 on each internal
`*-api` hostname, and that a missing or invalid key returns HTTP 401 on both
observability APIs. Check the existing key still reaches the
other APIs (their own upstream authentication may also be required).

Grafana currently grants anonymous users the **Editor** role, including requests
through this route. This limits which service the agent can reach with the key;
it does not make Grafana read-only or isolate access to particular data sources.

## TODO

- [ ] Slack channel alarms
- [ ] Automate Sensors with https://hub.docker.com/r/amkay/sensor-exporter + Podman
- [ ] Try to get rid of additional network card?

## Updates

Last `ant-services` container updates: 08.02.2025
