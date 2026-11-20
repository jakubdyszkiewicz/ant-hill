#!/usr/bin/env bash
# Nightly consistent dumps of the service databases into /mnt/data/backups/db-dumps.
# Duplicacy (02:00) uploads them to B2: copying live Postgres/MariaDB data dirs file by
# file is not a consistent backup, a dump is. Credentials come from each container's env.
# Writes Prometheus metrics for node-exporter's textfile collector (alerting in Grafana).
set -uo pipefail

OUT=/mnt/data/backups/db-dumps
KEEP_DAYS=7
PROM_DIR=/var/lib/node_exporter/textfile
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
NOW=$(date +%s)

POSTGRES=(sure-db bubblewrap-postgres terminus-database)
MARIADB=(romm-db)

umask 077
mkdir -p "$OUT" "$PROM_DIR"
metrics=$(mktemp)
failed=0

record() { # db success size
  echo "ant_db_dump_success{db=\"$1\"} $2" >> "$metrics"
  echo "ant_db_dump_size_bytes{db=\"$1\"} $3" >> "$metrics"
  echo "ant_db_dump_last_run_timestamp_seconds{db=\"$1\"} $NOW" >> "$metrics"
}

for c in "${POSTGRES[@]}"; do
  f="$OUT/$c-$STAMP.dump"
  # Custom format (-Fc): compressed, restore with pg_restore.
  if docker exec "$c" sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc' > "$f.tmp" && [ -s "$f.tmp" ]; then
    mv "$f.tmp" "$f"; record "$c" 1 "$(stat -c %s "$f")"; echo "ok: $f"
  else
    rm -f "$f.tmp"; record "$c" 0 0; failed=1; echo "FAILED: $c" >&2
  fi
done

for c in "${MARIADB[@]}"; do
  f="$OUT/$c-$STAMP.sql.gz"
  # --single-transaction: consistent InnoDB snapshot without locking the tables.
  if docker exec "$c" sh -c 'mariadb-dump -uroot -p"$MARIADB_ROOT_PASSWORD" --single-transaction --routines --events --databases "$MARIADB_DATABASE"' \
      | gzip > "$f.tmp" && [ -s "$f.tmp" ]; then
    mv "$f.tmp" "$f"; record "$c" 1 "$(stat -c %s "$f")"; echo "ok: $f"
  else
    rm -f "$f.tmp"; record "$c" 0 0; failed=1; echo "FAILED: $c" >&2
  fi
done

# Retention: keep a week of dumps (B2 keeps history beyond that).
find "$OUT" -type f \( -name '*.dump' -o -name '*.sql.gz' \) -mtime +"$KEEP_DAYS" -delete
find "$OUT" -type f -name '*.tmp' -delete

# Atomic replace so node-exporter never reads a half-written file.
chmod 644 "$metrics"
mv "$metrics" "$PROM_DIR/db_dumps.prom"
exit "$failed"
