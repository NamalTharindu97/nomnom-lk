#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  printf 'backup-postgres must run as root\n' >&2
  exit 1
fi

nomnom_root=${NOMNOM_ROOT:-/etc/nomnom}
compose_dir="$nomnom_root/compose"
env_file="$nomnom_root/config/compose.env"
secret_root="$nomnom_root/secrets"

set -a
# shellcheck disable=SC1090
source "$env_file"
set +a

: "${BACKUP_R2_ENDPOINT:?Set BACKUP_R2_ENDPOINT}"
: "${BACKUP_R2_BUCKET:?Set BACKUP_R2_BUCKET}"
: "${DATABASE_USER:?Set DATABASE_USER}"
: "${DATABASE_NAME:?Set DATABASE_NAME}"

for command in age docker rclone sha256sum; do
  command -v "$command" >/dev/null
done

workdir=$(mktemp -d)
rclone_config="$workdir/rclone.conf"
cleanup() {
  rm -rf "$workdir"
}
trap cleanup EXIT

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

timestamp=$(date -u +%Y%m%dT%H%M%SZ)
filename="nomnom-${timestamp}.dump.age"
partial="$workdir/$filename.partial"
encrypted="$workdir/$filename"
recipient=$(<"$secret_root/backup/age_recipient")

docker compose --env-file "$env_file" -f "$compose_dir/compose.yml" \
  exec -T postgres pg_dump -U "$DATABASE_USER" -d "$DATABASE_NAME" \
  --format=custom --no-owner --no-privileges | \
  age --recipient "$recipient" --output "$partial"

IFS= read -r header < "$partial"
if [[ "$header" != "age-encryption.org/v1" ]]; then
  printf 'Backup encryption verification failed\n' >&2
  exit 1
fi
mv "$partial" "$encrypted"

(
  cd "$workdir"
  sha256sum "$filename" > "$filename.sha256"
)

prefix=${BACKUP_R2_PREFIX:-postgres}
rclone --config "$rclone_config" copyto "$encrypted" \
  "backup:${BACKUP_R2_BUCKET}/${prefix}/${filename}"
rclone --config "$rclone_config" copyto "$workdir/$filename.sha256" \
  "backup:${BACKUP_R2_BUCKET}/${prefix}/${filename}.sha256"

printf 'Encrypted PostgreSQL backup uploaded: %s/%s\n' "$prefix" "$filename"
