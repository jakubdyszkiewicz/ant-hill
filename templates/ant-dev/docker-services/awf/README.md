# AWF

AWF runs with host networking in the `awf` service. It listens on
`0.0.0.0:8080`, so the host CLI reaches it on `127.0.0.1:8080` and Paseo agents
on the advertised Tailscale URL `http://100.115.153.105:8080`. It is also
reachable on the LAN and Docker bridge addresses; every request needs a token.
Paseo runs separately on the host at `100.115.153.105:6767`.

The server uses `/root/.config/awf/server.env` for its signing key and Paseo
settings (rendered by ant-hill from the vault key `ant_dev_awf_signing_key`; edits on the host are overwritten) and stores SQLite under `/root/.local/share/awf`. Preserve both for
backups. The GitHub App service rotates `/root/docker-services/github-app-token/output/token`;
AWF mounts the directory read-only and reads the file for each GitHub command.

After updating the AWF checkout, rebuild and restart the service, install the
host CLI, and reload the board:

```sh
cd /root/dev/awf
mise install
mise run local:install
PASEO_BIN_DIR="$HOME/.local/share/mise/installs/node/22.22.1/bin" mise run local:board:install
docker compose -f /root/docker-services/docker-compose.yaml up -d --build awf
```

Inspect with `docker compose -f /root/docker-services/docker-compose.yaml ps`
and `docker compose -f /root/docker-services/docker-compose.yaml logs awf`.
The old `awf.service`, `awf-tailscale.socket` and `awf-tailscale.service`
user units are disabled.

Isodev's current `on_create` copies AWF into each worker container. Existing
workers can therefore keep an older CLI after a host update; new containers copy
the current binary. Refresh existing workers deliberately without deleting their
private state, or recreate them only after preserving anything needed inside.
