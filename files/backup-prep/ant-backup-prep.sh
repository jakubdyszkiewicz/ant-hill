#!/usr/bin/env bash
# Nightly backup preparation, run before the 02:00 Duplicacy backup to B2. Produces
# consistent, plain copies of data that can't be safely copied file by file while running:
#  - database dumps (live Postgres/MariaDB data dirs aren't a consistent backup)
#  - bubblewrap's media bucket from SeaweedFS (objects live inside SeaweedFS volume files)
# Credentials come from each container's own env. Writes Prometheus metrics for
# node-exporter's textfile collector (alerting in Grafana).
set -uo pipefail

BACKUPS=/mnt/data/backups
DUMPS=$BACKUPS/db-dumps
MEDIA=$BACKUPS/bubblewrap-media
KEEP_DAYS=7
PROM_DIR=/var/lib/node_exporter/textfile
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
NOW=$(date +%s)
# Same image as the rclone service in docker-compose.yaml.j2 (Renovate tracks that one).
RCLONE_IMAGE=rclone/rclone:1.76.0@sha256:7cbeec24a44f206067597c0368be4de90ae19a64d5113c7d1938bd737a81e466

POSTGRES=(sure-db bubblewrap-postgres terminus-database)
MARIADB=(romm-db)

umask 077
mkdir -p "$DUMPS" "$MEDIA" "$PROM_DIR"
metrics=$(mktemp)
failed=0

record() { # job success size
  echo "ant_backup_success{job=\"$1\"} $2" >> "$metrics"
  echo "ant_backup_size_bytes{job=\"$1\"} $3" >> "$metrics"
  echo "ant_backup_last_run_timestamp_seconds{job=\"$1\"} $NOW" >> "$metrics"
}

# --- Database dumps ---
for c in "${POSTGRES[@]}"; do
  f="$DUMPS/$c-$STAMP.dump"
  # Custom format (-Fc): compressed, restore with pg_restore.
  if docker exec "$c" sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc' > "$f.tmp" && [ -s "$f.tmp" ]; then
    mv "$f.tmp" "$f"; record "$c" 1 "$(stat -c %s "$f")"; echo "ok: $f"
  else
    rm -f "$f.tmp"; record "$c" 0 0; failed=1; echo "FAILED: $c" >&2
  fi
done

for c in "${MARIADB[@]}"; do
  f="$DUMPS/$c-$STAMP.sql.gz"
  # --single-transaction: consistent InnoDB snapshot without locking the tables.
  if docker exec "$c" sh -c 'mariadb-dump -uroot -p"$MARIADB_ROOT_PASSWORD" --single-transaction --routines --events --databases "$MARIADB_DATABASE"' \
      | gzip > "$f.tmp" && [ -s "$f.tmp" ]; then
    mv "$f.tmp" "$f"; record "$c" 1 "$(stat -c %s "$f")"; echo "ok: $f"
  else
    rm -f "$f.tmp"; record "$c" 0 0; failed=1; echo "FAILED: $c" >&2
  fi
done

# Keep a week of dumps (B2 keeps history beyond that).
find "$DUMPS" -type f \( -name '*.dump' -o -name '*.sql.gz' \) -mtime +"$KEEP_DAYS" -delete
find "$DUMPS" -type f -name '*.tmp' -delete

# --- bubblewrap media: SeaweedFS bucket -> plain files ---
# A mirror (sync, not copy): objects deleted in the app disappear here too; B2 keeps history.
envf=$(mktemp)
{
  echo "RCLONE_CONFIG_SW_TYPE=s3"
  echo "RCLONE_CONFIG_SW_PROVIDER=SeaweedFS"
  echo "RCLONE_CONFIG_SW_ENDPOINT=http://bubblewrap-seaweedfs:8333"
  docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' bubblewrap-seaweedfs \
    | sed -n 's/^AWS_ACCESS_KEY_ID=/RCLONE_CONFIG_SW_ACCESS_KEY_ID=/p; s/^AWS_SECRET_ACCESS_KEY=/RCLONE_CONFIG_SW_SECRET_ACCESS_KEY=/p'
} > "$envf"
if docker run --rm --network docker-services_default --env-file "$envf" -v "$MEDIA:/backup" "$RCLONE_IMAGE" \
     sync sw:family-media /backup/family-media --stats 0 --log-level NOTICE; then
  record bubblewrap-media 1 "$(du -sb "$MEDIA" | cut -f1)"; echo "ok: $MEDIA"
else
  record bubblewrap-media 0 0; failed=1; echo "FAILED: bubblewrap-media" >&2
fi
rm -f "$envf"

# Atomic replace so node-exporter never reads a half-written file.
chmod 644 "$metrics"
mv "$metrics" "$PROM_DIR/backup_prep.prom"
exit "$failed"
