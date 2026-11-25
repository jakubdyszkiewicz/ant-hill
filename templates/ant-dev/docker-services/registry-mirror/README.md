# Docker Hub pull-through cache

`registry-mirror` runs `registry:3` in proxy mode for Docker Hub only
(`registry-1.docker.io`). It uses host networking and listens on
`0.0.0.0:5000` over plain HTTP, so it is also reachable on the LAN, Tailscale and
Docker bridge addresses. It pulls anonymously and stores no credentials, so it
serves only public images. Cached data lives in `/root/.cache/registry-mirror`.
Entries expire after `proxy.ttl` (168h) in `config.yml`.

Inner dockerd in isodev workers gets `--registry-mirror=http://<gateway>:5000`
from `~/.config/isodev/on-start.sh`. The gateway is the worker network's
default gateway, which is the host. `172.17.0.1` cannot be used because the
inner dockerd creates its own `docker0` with that address. If the mirror is
unreachable, Docker falls back to Docker Hub. Other registries such as ghcr.io
are not mirrored.

The flag applies when on-start starts dockerd: in new workers, and in stopped
workers when isodev starts them. Running workers keep their current dockerd
until it is restarted. Check a worker with
`docker info --format '{{.RegistryConfig.Mirrors}}'`.

```sh
docker compose -f /root/docker-services/docker-compose.yaml up -d registry-mirror
curl -s http://127.0.0.1:5000/v2/_catalog
docker compose -f /root/docker-services/docker-compose.yaml logs registry-mirror
```

To pull with a Docker Hub account for higher rate limits, add
`proxy.username` and `proxy.password` to `config.yml`. Anyone who can reach port
5000 can then pull through that account, including its private repositories.
