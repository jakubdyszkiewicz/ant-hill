# GitHub App installation token service

Deployed by ant-hill (`ant-dev.yaml`). The PEM private key (`secrets/private-key.pem`) and the numeric
`GITHUB_APP_ID` and `GITHUB_INSTALLATION_ID` (`config.env`) are rendered from the vault
(`ant_dev_github_app_private_key`, `ant_dev_github_app_id`, `ant_dev_github_installation_id`).
Install the app on the target repositories with the permissions you need. The deploy rebuilds
the image when `Dockerfile` or `refresh.py` changes; check `docker compose logs github-app-token`.

The service requests a fresh installation token at startup and five minutes before expiry. It retries failures every minute, leaving the last token in place. `output/token` is written with mode 0600 and replaced atomically. Mount the **output directory** read-only into consumers, not the individual token file: atomic replacement changes the file inode. Consumers must read the token again when they run, not cache it indefinitely. The output token grants the installation's default repository access and permissions; the service does not narrow them.

The PEM is only mounted into this service. Any process able to read the output can use the token; this service provides no isolation against privileged containers or host administrators. Stop with `docker compose stop github-app-token`. Stopping does not erase the last token; it remains usable until expiration or revocation.
