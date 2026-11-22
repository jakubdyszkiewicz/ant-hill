#!/usr/bin/env bash
# Nightly database dumps, run before the 02:00 Duplicacy backup to B2: live Postgres/MariaDB
# data dirs copied file by file aren't a consistent backup. (SeaweedFS needs nothing here: its
# volume files are append-only, and a file-by-file copy restored byte-for-byte in testing.)
# Dumps are uncompressed on purpose: Duplicacy compresses chunks itself and deduplicates
# unchanged parts between nights, which compressed dumps would defeat.
# Credentials come from each container's own env. Writes Prometheus metrics for
# node-exporter's textfile collector (alerting in Grafana).
set -uo pipefail

BACKUPS=/mnt/data/backups
DUMPS=$BACKUPS/db-dumps
KEEP_DAYS=7
PROM_DIR=/var/lib/node_exporter/textfile
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
NOW=$(date +%s)

POSTGRES=(sure-db bubblewrap-postgres terminus-database)
MARIADB=(romm-db)

umask 077
mkdir -p "$DUMPS" "$PROM_DIR"
metrics=$(mktemp)
failed=0

record() { # database success size
  echo "ant_backup_success{database=\"$1\"} $2" >> "$metrics"
  echo "ant_backup_size_bytes{database=\"$1\"} $3" >> "$metrics"
  echo "ant_backup_last_run_timestamp_seconds{database=\"$1\"} $NOW" >> "$metrics"
}

# --- Database dumps ---
for c in "${POSTGRES[@]}"; do
  f="$DUMPS/$c-$STAMP.sql"
  # Plain SQL: restore with psql into an empty database.
  if docker exec "$c" sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB"' > "$f.tmp" && [ -s "$f.tmp" ]; then
    mv "$f.tmp" "$f"; record "$c" 1 "$(stat -c %s "$f")"; echo "ok: $f"
  else
    rm -f "$f.tmp"; record "$c" 0 0; failed=1; echo "FAILED: $c" >&2
  fi
done

for c in "${MARIADB[@]}"; do
  f="$DUMPS/$c-$STAMP.sql"
  # --single-transaction: consistent InnoDB snapshot without locking the tables.
  if docker exec "$c" sh -c 'mariadb-dump -uroot -p"$MARIADB_ROOT_PASSWORD" --single-transaction --routines --events --databases "$MARIADB_DATABASE"' \
      > "$f.tmp" && [ -s "$f.tmp" ]; then
    mv "$f.tmp" "$f"; record "$c" 1 "$(stat -c %s "$f")"; echo "ok: $f"
  else
    rm -f "$f.tmp"; record "$c" 0 0; failed=1; echo "FAILED: $c" >&2
  fi
done

# Keep a week of dumps (B2 keeps history beyond that).
find "$DUMPS" -type f -name '*.sql' -mtime +"$KEEP_DAYS" -delete
find "$DUMPS" -type f -name '*.tmp' -delete

# Atomic replace so node-exporter never reads a half-written file.
chmod 644 "$metrics"
mv "$metrics" "$PROM_DIR/backup_prep.prom"
exit "$failed"
