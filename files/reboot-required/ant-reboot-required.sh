#!/usr/bin/env bash
# Reports whether Ubuntu wants a reboot (kernel, libc, ... updates installed by unattended-upgrades)
# to node-exporter's textfile collector. Grafana alerts when one has been pending for a week.
set -euo pipefail
PROM_DIR=${PROM_DIR:-/var/lib/node_exporter/textfile}
FLAG=/var/run/reboot-required
tmp=$(mktemp)
if [ -f "$FLAG" ]; then
  # Unique package names, comma-separated, for the alert message.
  pkgs=$(sort -u /var/run/reboot-required.pkgs 2>/dev/null | paste -sd, - || true)
  echo "ant_reboot_required 1" >> "$tmp"
  echo "ant_reboot_required_since_timestamp_seconds{packages=\"$pkgs\"} $(stat -c %Y "$FLAG")" >> "$tmp"
else
  echo "ant_reboot_required 0" >> "$tmp"
fi
chmod 644 "$tmp"
mv "$tmp" "$PROM_DIR/reboot_required.prom"
