#!/usr/bin/env bash
set -Eeuo pipefail

# Deploy immutable staging application images to the VPS.
# Usage: deploy-staging.sh <backend-image> <admin-image>

COMPOSE_FILE=${COMPOSE_FILE:-compose.staging.yml}
ENV_FILE=${ENV_FILE:-compose.staging.env}
COMPOSE_DIR=${COMPOSE_DIR:-/etc/nomnom/compose}
HEALTH_URL=${HEALTH_URL:-https://api.nomnomlk.com/health}
ADMIN_HEALTH_URL=${ADMIN_HEALTH_URL:-https://admin.nomnomlk.com/login}
BACKEND_IMAGE=${1:-}
ADMIN_IMAGE=${2:-}

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  printf 'deploy-staging must run as root\n' >&2
  exit 1
fi

validate_image() {
  local image=$1
  if [[ ! "$image" =~ :[0-9a-f]{40}$ ]]; then
    printf 'Application images must use a full 40-character Git SHA tag: %s\n' "$image" >&2
    exit 1
  fi
}

validate_image "$BACKEND_IMAGE"
validate_image "$ADMIN_IMAGE"

cd "$COMPOSE_DIR"
BACKEND_IMAGE="$BACKEND_IMAGE" ADMIN_IMAGE="$ADMIN_IMAGE" \
  docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" config --quiet

old_backend_id=$(docker inspect --format '{{.Image}}' nomnom-staging-backend-1 2>/dev/null || true)
old_admin_id=$(docker inspect --format '{{.Image}}' nomnom-staging-admin-1 2>/dev/null || true)
deployment_succeeded=false

rollback() {
  if [[ "$deployment_succeeded" == true ]]; then
    return
  fi

  printf '[deploy-staging] Health verification failed; restoring previous images\n' >&2
  if [[ -n "$old_backend_id" && -n "$old_admin_id" ]]; then
    BACKEND_IMAGE="$old_backend_id" ADMIN_IMAGE="$old_admin_id" \
      docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d --no-deps backend admin
  fi
}
trap rollback EXIT

printf '[deploy-staging] Pulling immutable application images\n'
BACKEND_IMAGE="$BACKEND_IMAGE" ADMIN_IMAGE="$ADMIN_IMAGE" \
  docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" pull backend admin

printf '[deploy-staging] Recreating application containers\n'
BACKEND_IMAGE="$BACKEND_IMAGE" ADMIN_IMAGE="$ADMIN_IMAGE" \
  docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d --no-deps backend admin

wait_for_url() {
  local name=$1
  local url=$2
  for _ in $(seq 1 60); do
    if curl --fail --silent --show-error --output /dev/null "$url"; then
      printf '[deploy-staging] %s health check passed\n' "$name"
      return 0
    fi
    sleep 5
  done
  return 1
}

wait_for_url backend "$HEALTH_URL"
wait_for_url admin "$ADMIN_HEALTH_URL"

update_image_reference() {
  local key=$1
  local value=$2
  local temporary
  temporary=$(mktemp "$COMPOSE_DIR/.compose.staging.env.XXXXXX")
  grep -v "^${key}=" "$ENV_FILE" > "$temporary"
  printf '%s=%s\n' "$key" "$value" >> "$temporary"
  chmod --reference="$ENV_FILE" "$temporary"
  chown --reference="$ENV_FILE" "$temporary"
  mv "$temporary" "$ENV_FILE"
}

update_image_reference BACKEND_IMAGE "$BACKEND_IMAGE"
update_image_reference ADMIN_IMAGE "$ADMIN_IMAGE"
deployment_succeeded=true
printf '[deploy-staging] Deployment completed successfully\n'
