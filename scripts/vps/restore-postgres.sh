#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  printf 'restore-postgres must run as root\n' >&2
  exit 1
fi

backup_id=${1:-}
confirmation=${2:-}
if [[ "$confirmation" != "VERIFY-RESTORE" || ! "$backup_id" =~ ^[A-Za-z0-9._/-]+\.dump\.age$ || "$backup_id" == /* || "$backup_id" == *".."* ]]; then
  printf 'Backup identifier or confirmation is invalid\n' >&2
  exit 1
fi

nomnom_root=${NOMNOM_ROOT:-/etc/nomnom}
compose_dir="$nomnom_root/compose"
env_file="$nomnom_root/config/compose.env"
secret_root="$nomnom_root/secrets"

journal_event() {
  if command -v logger >/dev/null 2>&1; then
    logger --tag nomnom-restore -- "$1" || true
  fi
}

set -a
# shellcheck disable=SC1090
source "$env_file"
set +a

: "${BACKUP_R2_ENDPOINT:?Set BACKUP_R2_ENDPOINT}"
: "${BACKUP_R2_BUCKET:?Set BACKUP_R2_BUCKET}"
: "${DATABASE_USER:?Set DATABASE_USER}"

for command in age docker rclone sha256sum; do
  command -v "$command" >/dev/null
done

workdir=$(mktemp -d)
identity="$workdir/age-identity.txt"
rclone_config="$workdir/rclone.conf"
verification_db="nomnom_restore_$(date -u +%Y%m%d%H%M%S)_$$"
database_created=false
restore_succeeded=false

cleanup() {
  local exit_status=$?
  local cleanup_failed=false
  set +e
  if [[ "$database_created" == true ]]; then
    if ! docker compose --env-file "$env_file" -f "$compose_dir/compose.yml" \
      exec -T postgres dropdb -U "$DATABASE_USER" --if-exists "$verification_db" >/dev/null 2>&1; then
      cleanup_failed=true
      journal_event "restore_database_cleanup_failed backup_id=$backup_id"
      printf 'Disposable restore database could not be removed\n' >&2
    fi
  fi
  if ! rm -rf "$workdir"; then
    cleanup_failed=true
    journal_event "restore_file_cleanup_failed backup_id=$backup_id"
    printf 'Restore temporary files could not be removed\n' >&2
  fi
  if [[ "$restore_succeeded" != true ]]; then
    journal_event "restore_failed backup_id=$backup_id exit_status=$exit_status"
  fi
  trap - EXIT
  if [[ "$cleanup_failed" == true && "$exit_status" -eq 0 ]]; then
    exit 1
  fi
  exit "$exit_status"
}
trap cleanup EXIT
journal_event "restore_started backup_id=$backup_id"

cat > "$identity"
identity_size=$(wc -c < "$identity")
if (( identity_size < 1 || identity_size > 131072 )); then
  printf 'Recovery identity is invalid\n' >&2
  exit 1
fi
chmod 0600 "$identity"

cat > "$rclone_config" <<EOF
[backup]
type = s3
provider = Cloudflare
access_key_id = $(<"$secret_root/backup/r2_access_key")
secret_access_key = $(<"$secret_root/backup/r2_secret_key")
endpoint = ${BACKUP_R2_ENDPOINT}
acl = private
no_check_bucket = true
EOF
chmod 0600 "$rclone_config"

encrypted="$workdir/$(basename "$backup_id")"
checksum="$encrypted.sha256"
rclone --config "$rclone_config" copyto \
  "backup:${BACKUP_R2_BUCKET}/${backup_id}" "$encrypted"
rclone --config "$rclone_config" copyto \
  "backup:${BACKUP_R2_BUCKET}/${backup_id}.sha256" "$checksum"

(
  cd "$workdir"
  sha256sum --check "$(basename "$checksum")" >/dev/null
)

docker compose --env-file "$env_file" -f "$compose_dir/compose.yml" \
  exec -T postgres createdb -U "$DATABASE_USER" "$verification_db"
database_created=true

age --decrypt --identity "$identity" "$encrypted" | \
  docker compose --env-file "$env_file" -f "$compose_dir/compose.yml" \
    exec -T postgres pg_restore -U "$DATABASE_USER" -d "$verification_db" \
      --exit-on-error --no-owner --no-privileges

table_count=$(docker compose --env-file "$env_file" -f "$compose_dir/compose.yml" \
  exec -T postgres psql -U "$DATABASE_USER" -d "$verification_db" -Atc \
    "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';")
if [[ ! "$table_count" =~ ^[1-9][0-9]*$ ]]; then
  printf 'Restore verification found no application tables\n' >&2
  exit 1
fi

restore_succeeded=true
journal_event "restore_succeeded backup_id=$backup_id table_count=$table_count"
printf 'Backup restored successfully into disposable verification database (%s tables)\n' "$table_count"
