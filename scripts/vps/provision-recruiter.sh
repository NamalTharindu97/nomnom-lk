#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=/etc/nomnom-recruiter
COMPOSE_DIR=$ROOT/compose
SECRET_DIR=$ROOT/secrets
STAGING_DIR=/etc/nomnom/compose
STAGING_SECRET_DIR=/etc/nomnom/secrets
CADDYFILE=$STAGING_DIR/Caddyfile
CADDY_CONTAINER=nomnom-staging-caddy-1
DOMAIN=${1:-}
BACKEND_IMAGE=${2:-}
ADMIN_IMAGE=${3:-}
BUNDLE_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
CADDY_BACKUP=
provision_succeeded=false
network_connected=false
import_database=nomnom_recruiter_import

rollback_caddy() {
  local status=$?
  set +e
  if [[ "$provision_succeeded" != true && -n "$CADDY_BACKUP" && -f "$CADDY_BACKUP" ]]; then
    cp "$CADDY_BACKUP" "$CADDYFILE"
    docker restart "$CADDY_CONTAINER" >/dev/null 2>&1 || true
  fi
  if [[ "$provision_succeeded" != true && "$network_connected" == true ]]; then
    docker network disconnect nomnom-recruiter-edge "$CADDY_CONTAINER" >/dev/null 2>&1 || true
  fi
  if [[ "$provision_succeeded" != true ]]; then
    docker exec nomnom-recruiter-postgres-1 dropdb --if-exists -U nomnom_recruiter "$import_database" >/dev/null 2>&1 || true
  fi
  return "$status"
}
trap rollback_caddy EXIT

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  printf 'provision-recruiter must run as root\n' >&2
  exit 1
fi
if [[ ! "$DOMAIN" =~ ^[a-z0-9.-]+$ ]]; then
  printf 'Invalid recruiter domain\n' >&2
  exit 1
fi
for image in "$BACKEND_IMAGE" "$ADMIN_IMAGE"; do
  if [[ ! "$image" =~ :[0-9a-f]{40}$ ]]; then
    printf 'Recruiter images must use full 40-character Git SHA tags\n' >&2
    exit 1
  fi
done

install -d -m 700 "$SECRET_DIR"
install -d -m 755 "$COMPOSE_DIR/config"
install -m 644 "$BUNDLE_ROOT/deploy/vps/compose.recruiter.yml" "$COMPOSE_DIR/compose.recruiter.yml"
install -m 644 "$BUNDLE_ROOT/deploy/vps/config/redis.conf" "$COMPOSE_DIR/config/redis.conf"
install -m 755 "$BUNDLE_ROOT/scripts/vps/deploy-recruiter.sh" /usr/local/sbin/nomnom-deploy-recruiter

if [[ -e "$ROOT/.provisioned" ]]; then
  /usr/local/sbin/nomnom-deploy-recruiter "$BACKEND_IMAGE" "$ADMIN_IMAGE"
  provision_succeeded=true
  exit 0
fi

create_secret() {
  local path=$1 bytes=$2
  if [[ ! -s "$path" ]]; then
    umask 077
    openssl rand -base64 "$bytes" | tr -d '\n' > "$path"
  fi
  chmod 444 "$path"
}
create_secret "$SECRET_DIR/database_password" 32
create_secret "$SECRET_DIR/redis_password" 32
create_secret "$SECRET_DIR/jwt_secret" 48
create_secret "$SECRET_DIR/admin_password" 32

for secret in r2_access_key r2_secret_key; do
  if [[ ! -s "$STAGING_SECRET_DIR/$secret" ]]; then
    printf 'Missing staging R2 credential: %s\n' "$secret" >&2
    exit 1
  fi
  install -m 444 "$STAGING_SECRET_DIR/$secret" "$SECRET_DIR/$secret"
done
printf 'user default on >%s ~* +@all\n' "$(<"$SECRET_DIR/redis_password")" > "$SECRET_DIR/redis_users_acl"
chmod 444 "$SECRET_DIR/redis_users_acl"

read_staging_value() {
  local key=$1 fallback=$2 value
  value=$(grep -m1 "^${key}=" "$STAGING_DIR/compose.staging.env" | cut -d= -f2- || true)
  printf '%s' "${value:-$fallback}"
}
R2_BUCKET=$(read_staging_value R2_BUCKET nomnom-images)
R2_ENDPOINT=$(read_staging_value R2_ENDPOINT '')
if [[ -z "$R2_ENDPOINT" ]]; then
  printf 'R2_ENDPOINT is missing from staging configuration\n' >&2
  exit 1
fi

cat > "$COMPOSE_DIR/compose.recruiter.env" <<EOF
COMPOSE_PROJECT_NAME=nomnom-recruiter
NOMNOM_SECRET_ROOT=$SECRET_DIR
BACKEND_IMAGE=$BACKEND_IMAGE
ADMIN_IMAGE=$ADMIN_IMAGE
RECRUITER_DOMAIN=$DOMAIN
DATABASE_USER=nomnom_recruiter
DATABASE_NAME=nomnom_recruiter
R2_BUCKET=$R2_BUCKET
R2_ENDPOINT=$R2_ENDPOINT
EOF
chmod 600 "$COMPOSE_DIR/compose.recruiter.env"

cd "$COMPOSE_DIR"
docker compose -f compose.recruiter.yml --env-file compose.recruiter.env config --quiet
docker compose -f compose.recruiter.yml --env-file compose.recruiter.env up -d postgres redis
for service in postgres redis; do
  container="nomnom-recruiter-${service}-1"
  for _ in $(seq 1 60); do
    if [[ $(docker inspect --format '{{.State.Health.Status}}' "$container" 2>/dev/null || true) == healthy ]]; then
      break
    fi
    sleep 2
  done
  if [[ $(docker inspect --format '{{.State.Health.Status}}' "$container" 2>/dev/null || true) != healthy ]]; then
    docker inspect --format '{{json .State.Health}}' "$container" >&2 || true
    docker logs --tail 100 "$container" >&2 || true
    printf 'Recruiter %s did not become healthy\n' "$service" >&2
    exit 1
  fi
done

if [[ ! -e "$ROOT/.database-initialized" ]]; then
  staging_user=$(read_staging_value DATABASE_USER nomnom)
  staging_database=$(read_staging_value DATABASE_NAME nomnom)
  docker exec nomnom-recruiter-postgres-1 dropdb --if-exists -U nomnom_recruiter "$import_database"
  docker exec nomnom-recruiter-postgres-1 createdb -U nomnom_recruiter "$import_database"
  docker exec nomnom-staging-postgres-1 pg_dump --no-owner --no-privileges -U "$staging_user" -d "$staging_database" | \
    docker exec -i nomnom-recruiter-postgres-1 psql -v ON_ERROR_STOP=1 -U nomnom_recruiter -d "$import_database"
  docker exec -i nomnom-recruiter-postgres-1 psql -v ON_ERROR_STOP=1 -U nomnom_recruiter -d "$import_database" <<'SQL'
BEGIN;
DO $$
DECLARE table_name text;
BEGIN
  FOREACH table_name IN ARRAY ARRAY['refresh_tokens', 'device_tokens', 'notifications', 'scheduled_notifications', 'audit_logs', 'favorites']
  LOOP
    IF to_regclass('public.' || table_name) IS NOT NULL THEN
      EXECUTE format('TRUNCATE TABLE %I CASCADE', table_name);
    END IF;
  END LOOP;
END $$;
UPDATE users
SET email = CASE
      WHEN role = 'portfolio_viewer' AND id = (
        SELECT id FROM users WHERE role = 'portfolio_viewer' ORDER BY created_at, id LIMIT 1
      ) THEN 'recruiter-demo@nomnomlk.com'
      ELSE 'account-' || replace(id::text, '-', '') || '@demo.invalid'
    END,
    name = CASE
      WHEN role = 'portfolio_viewer' AND id = (
        SELECT id FROM users WHERE role = 'portfolio_viewer' ORDER BY created_at, id LIMIT 1
      ) THEN 'Recruiter Demo'
      WHEN role = 'restaurant_owner' THEN 'Demo Restaurant Owner'
      WHEN role = 'admin' THEN 'Demo Administrator'
      ELSE 'Demo User'
    END,
    password_hash = '', firebase_uid = NULL, phone = NULL, avatar_url = NULL,
    is_active = role = 'portfolio_viewer' AND id = (
      SELECT id FROM users WHERE role = 'portfolio_viewer' ORDER BY created_at, id LIMIT 1
    ), deletion_requested_at = NULL,
    deletion_scheduled_at = NULL, failed_login_attempts = 0, locked_until = NULL;
COMMIT;
SQL
  docker exec nomnom-recruiter-postgres-1 psql -v ON_ERROR_STOP=1 -U nomnom_recruiter -d postgres \
    -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'nomnom_recruiter' AND pid <> pg_backend_pid();" \
    -c "DROP DATABASE nomnom_recruiter;" \
    -c "ALTER DATABASE $import_database RENAME TO nomnom_recruiter;"
  touch "$ROOT/.database-initialized"
fi

docker compose -f compose.recruiter.yml --env-file compose.recruiter.env up -d backend admin
docker network inspect nomnom-recruiter-edge >/dev/null
if ! docker inspect --format '{{json .NetworkSettings.Networks}}' "$CADDY_CONTAINER" | grep -q 'nomnom-recruiter-edge'; then
  docker network connect nomnom-recruiter-edge "$CADDY_CONTAINER"
  network_connected=true
fi

if ! openssl x509 -in "$STAGING_SECRET_DIR/origin_cert.pem" -noout -checkhost "$DOMAIN" >/dev/null; then
  printf 'Cloudflare origin certificate does not cover %s\n' "$DOMAIN" >&2
  exit 1
fi

if ! grep -q '# BEGIN NOMNOM RECRUITER' "$CADDYFILE"; then
  CADDY_BACKUP="$CADDYFILE.pre-recruiter"
  cp "$CADDYFILE" "$CADDY_BACKUP"
  cat >> "$CADDYFILE" <<EOF

# BEGIN NOMNOM RECRUITER
$DOMAIN {
	tls /etc/caddy/origin_cert.pem /etc/caddy/origin_key.pem
	encode zstd gzip
	header {
		Strict-Transport-Security "max-age=31536000; includeSubDomains"
		X-Content-Type-Options "nosniff"
		X-Frame-Options "DENY"
		Referrer-Policy "strict-origin-when-cross-origin"
	}
	reverse_proxy recruiter-admin:3000
}
# END NOMNOM RECRUITER
EOF
fi

if ! docker exec "$CADDY_CONTAINER" caddy validate --config /etc/caddy/Caddyfile; then
  printf 'Caddy validation failed; original configuration restored\n' >&2
  exit 1
fi
docker restart "$CADDY_CONTAINER" >/dev/null

for url in https://api.nomnomlk.com/health https://admin.nomnomlk.com/login; do
  if ! curl --fail --silent --show-error --output /dev/null "$url"; then
    printf 'Existing staging endpoint failed after Caddy restart: %s\n' "$url" >&2
    exit 1
  fi
done

for _ in $(seq 1 60); do
  if curl --fail --silent --show-error --output /dev/null "https://$DOMAIN/login" && \
    curl --fail --silent --show-error --output /dev/null --request POST "https://$DOMAIN/api/v1/auth/browser/demo"; then
    provision_succeeded=true
    touch "$ROOT/.provisioned"
    logger --tag nomnom-provision-recruiter -- "provisioning_succeeded domain=$DOMAIN" || true
    printf '[provision-recruiter] Recruiter stack is ready\n'
    exit 0
  fi
  sleep 5
done
printf 'Recruiter public verification failed\n' >&2
exit 1
