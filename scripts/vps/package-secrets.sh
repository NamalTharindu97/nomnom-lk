#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

required_variables=(
  DATABASE_PASSWORD
  REDIS_PASSWORD
  JWT_SECRET
  FIREBASE_CREDENTIALS_JSON
  R2_ACCESS_KEY
  R2_SECRET_KEY
  ADMIN_BOOTSTRAP_PASSWORD
  SMTP_PASSWORD
  POSTGRES_TLS_CERT
  POSTGRES_TLS_KEY
  BACKUP_R2_ACCESS_KEY
  BACKUP_R2_SECRET_KEY
  AGE_RECIPIENT
)

for variable in "${required_variables[@]}"; do
  if [[ -z "${!variable:-}" ]]; then
    printf 'Required secret variable is missing: %s\n' "$variable" >&2
    exit 1
  fi
done

workdir=$(mktemp -d)
cleanup() {
  rm -rf "$workdir"
}
trap cleanup EXIT

write_secret() {
  local filename=$1
  local variable=$2
  printf '%s' "${!variable}" > "$workdir/$filename"
  chmod 0600 "$workdir/$filename"
}

write_secret database_password DATABASE_PASSWORD
write_secret redis_password REDIS_PASSWORD
write_secret jwt_secret JWT_SECRET
write_secret firebase_credentials.json FIREBASE_CREDENTIALS_JSON
write_secret r2_access_key R2_ACCESS_KEY
write_secret r2_secret_key R2_SECRET_KEY
write_secret admin_password ADMIN_BOOTSTRAP_PASSWORD
write_secret smtp_password SMTP_PASSWORD
write_secret postgres_tls.crt POSTGRES_TLS_CERT
write_secret postgres_tls.key POSTGRES_TLS_KEY
write_secret backup_r2_access_key BACKUP_R2_ACCESS_KEY
write_secret backup_r2_secret_key BACKUP_R2_SECRET_KEY
write_secret age_recipient AGE_RECIPIENT

files=(
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

COPYFILE_DISABLE=1 tar --no-xattrs -C "$workdir" -cf - "${files[@]}"
