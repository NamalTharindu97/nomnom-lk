#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  printf 'install-secrets must run as root\n' >&2
  exit 1
fi

nomnom_root=${NOMNOM_ROOT:-/etc/nomnom}
secret_root="$nomnom_root/secrets"
previous_root="$nomnom_root/secrets.previous"
backend_uid=${BACKEND_UID:-65532}
backend_gid=${BACKEND_GID:-65532}
postgres_uid=${POSTGRES_UID:-70}
postgres_gid=${POSTGRES_GID:-70}
redis_uid=${REDIS_UID:-999}
redis_gid=${REDIS_GID:-999}
install -d -m 0700 -o root -g root "$nomnom_root"
archive=$(mktemp)
stage=$(mktemp -d "$nomnom_root/secrets.new.XXXXXX")
incoming="$stage/incoming"
mkdir "$incoming"

cleanup() {
  rm -f "$archive"
  if [[ -d "$stage" ]]; then
    rm -rf "$stage"
  fi
}
trap cleanup EXIT

cat > "$archive"
archive_size=$(wc -c < "$archive")
if (( archive_size < 1 || archive_size > 1048576 )); then
  printf 'Secret archive size is invalid\n' >&2
  exit 1
fi

required_files=(
  database_password
  redis_password
  jwt_secret
  firebase_credentials.json
  r2_access_key
  r2_secret_key
  admin_password
  smtp_password
  postgres_tls.crt
  postgres_tls.key
  backup_r2_access_key
  backup_r2_secret_key
  age_recipient
)

declare -A allowed=()
declare -A seen=()
for filename in "${required_files[@]}"; do
  allowed["$filename"]=1
done

while IFS= read -r filename; do
  if [[ -z "$filename" || -z "${allowed[$filename]:-}" || -n "${seen[$filename]:-}" ]]; then
    printf 'Secret archive contains an invalid entry\n' >&2
    exit 1
  fi
  seen["$filename"]=1
done < <(tar -tf "$archive")

for filename in "${required_files[@]}"; do
  if [[ -z "${seen[$filename]:-}" ]]; then
    printf 'Secret archive is missing required file: %s\n' "$filename" >&2
    exit 1
  fi
done

while IFS= read -r listing; do
  if [[ ${listing:0:1} != "-" ]]; then
    printf 'Secret archive entries must be regular files\n' >&2
    exit 1
  fi
done < <(tar -tvf "$archive")

tar --extract --file "$archive" --directory "$incoming" --no-same-owner --no-same-permissions

for filename in "${required_files[@]}"; do
  path="$incoming/$filename"
  if [[ ! -f "$path" || -L "$path" || ! -s "$path" ]]; then
    printf 'Installed secret file is invalid: %s\n' "$filename" >&2
    exit 1
  fi
  size=$(wc -c < "$path")
  if (( size > 131072 )); then
    printf 'Installed secret file is too large: %s\n' "$filename" >&2
    exit 1
  fi
  chown root:root "$path"
  chmod 0600 "$path"
done

install -d -m 0700 "$stage/backend" "$stage/postgres" "$stage/redis" "$stage/backup"

install -m 0400 -o "$backend_uid" -g "$backend_gid" "$incoming/database_password" "$stage/backend/database_password"
install -m 0400 -o "$backend_uid" -g "$backend_gid" "$incoming/redis_password" "$stage/backend/redis_password"
install -m 0400 -o "$backend_uid" -g "$backend_gid" "$incoming/jwt_secret" "$stage/backend/jwt_secret"
install -m 0400 -o "$backend_uid" -g "$backend_gid" "$incoming/firebase_credentials.json" "$stage/backend/firebase_credentials.json"
install -m 0400 -o "$backend_uid" -g "$backend_gid" "$incoming/r2_access_key" "$stage/backend/r2_access_key"
install -m 0400 -o "$backend_uid" -g "$backend_gid" "$incoming/r2_secret_key" "$stage/backend/r2_secret_key"
install -m 0400 -o "$backend_uid" -g "$backend_gid" "$incoming/admin_password" "$stage/backend/admin_password"
install -m 0400 -o "$backend_uid" -g "$backend_gid" "$incoming/smtp_password" "$stage/backend/smtp_password"

install -m 0400 -o "$postgres_uid" -g "$postgres_gid" "$incoming/database_password" "$stage/postgres/database_password"
install -m 0400 -o "$postgres_uid" -g "$postgres_gid" "$incoming/postgres_tls.crt" "$stage/postgres/postgres_tls.crt"
install -m 0400 -o "$postgres_uid" -g "$postgres_gid" "$incoming/postgres_tls.key" "$stage/postgres/postgres_tls.key"

install -m 0400 -o "$redis_uid" -g "$redis_gid" "$incoming/redis_password" "$stage/redis/redis_password"
redis_hash=$(sha256sum "$incoming/redis_password" | cut -d ' ' -f 1)
printf 'user default on #%s ~* +@all\n' "$redis_hash" > "$stage/redis/redis_users.acl"
chown "$redis_uid:$redis_gid" "$stage/redis/redis_users.acl"
chmod 0400 "$stage/redis/redis_users.acl"

install -m 0400 -o root -g root "$incoming/backup_r2_access_key" "$stage/backup/r2_access_key"
install -m 0400 -o root -g root "$incoming/backup_r2_secret_key" "$stage/backup/r2_secret_key"
install -m 0444 -o root -g root "$incoming/age_recipient" "$stage/backup/age_recipient"

rm -rf "$incoming"
chmod 0700 "$stage"

rm -rf "$previous_root"
if [[ -d "$secret_root" ]]; then
  mv "$secret_root" "$previous_root"
fi
mv "$stage" "$secret_root"
stage=""

printf 'Installed service-scoped secrets atomically\n'
