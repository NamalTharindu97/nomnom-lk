#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  printf 'deploy must run as root\n' >&2
  exit 1
fi

nomnom_root=${NOMNOM_ROOT:-/etc/nomnom}
compose_dir="$nomnom_root/compose"
env_file="$nomnom_root/config/compose.env"
secret_root="$nomnom_root/secrets"
previous_root="$nomnom_root/secrets.previous"

journal_event() {
  if command -v logger >/dev/null 2>&1; then
    logger --tag nomnom-deploy -- "$1" || true
  fi
}

if [[ ! -r "$env_file" ]]; then
  printf 'Compose environment file is unavailable\n' >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$env_file"
set +a

if [[ $# -ne 0 && $# -ne 2 ]]; then
  printf 'Usage: nomnom-deploy [backend-image admin-image]\n' >&2
  exit 1
fi

images_supplied=false
if [[ $# -eq 2 ]]; then
  BACKEND_IMAGE=$1
  ADMIN_IMAGE=$2
  export BACKEND_IMAGE ADMIN_IMAGE
  images_supplied=true
fi

require_immutable_image() {
  local variable=$1
  local value=${!variable:-}
  if [[ ! "$value" =~ @sha256:[0-9a-f]{64}$ && ! "$value" =~ :[0-9a-f]{40}$ ]]; then
    printf '%s must use an immutable digest or full Git SHA tag\n' "$variable" >&2
    exit 1
  fi
  if [[ "$value" == *"sha256:0000000000000000000000000000000000000000000000000000000000000000"* || "$value" == *"git-sha-placeholder"* ]]; then
    printf '%s still contains a placeholder image reference\n' "$variable" >&2
    exit 1
  fi
}

for variable in CADDY_IMAGE POSTGRES_IMAGE REDIS_IMAGE BACKEND_IMAGE ADMIN_IMAGE; do
  require_immutable_image "$variable"
done
journal_event "deployment_started backend_image=$BACKEND_IMAGE admin_image=$ADMIN_IMAGE"

# Invoked indirectly by the EXIT trap.
# shellcheck disable=SC2317
rollback_secrets() {
  if [[ ! -d "$previous_root" ]]; then
    return 2
  fi

  local failed_root="$nomnom_root/secrets.failed.$(date +%s)"
  local current_secrets_moved=false
  if [[ -d "$secret_root" ]]; then
    if ! mv "$secret_root" "$failed_root"; then
      printf 'Deployment failed; current secrets could not be isolated\n' >&2
      return 1
    fi
    current_secrets_moved=true
  fi
  if ! mv "$previous_root" "$secret_root"; then
    if [[ "$current_secrets_moved" == true ]]; then
      mv "$failed_root" "$secret_root" || true
    fi
    printf 'Deployment failed; previous secrets could not be restored\n' >&2
    return 1
  fi
  if ! docker compose --env-file "$env_file" -f "$compose_dir/compose.yml" up -d; then
    printf 'Deployment failed; services did not restart with previous secrets\n' >&2
    return 1
  fi
  printf 'Deployment failed; previous secrets restored\n' >&2
}

deployment_succeeded=false
old_backend_id=$(docker inspect --format '{{.Image}}' nomnom-backend-1 2>/dev/null || true)
old_admin_id=$(docker inspect --format '{{.Image}}' nomnom-admin-1 2>/dev/null || true)
# Invoked indirectly by the EXIT trap.
# shellcheck disable=SC2317
finish() {
  local exit_status=$?
  set +e
  if [[ "$deployment_succeeded" != true ]]; then
    journal_event "deployment_failed exit_status=$exit_status"
    if [[ -n "$old_backend_id" && -n "$old_admin_id" ]]; then
      journal_event "application_rollback_started"
      BACKEND_IMAGE=$old_backend_id
      ADMIN_IMAGE=$old_admin_id
      export BACKEND_IMAGE ADMIN_IMAGE
      if docker compose --env-file "$env_file" -f "$compose_dir/compose.yml" up -d --no-deps backend admin; then
        journal_event "application_rollback_completed"
        printf 'Deployment failed; previous application images restored\n' >&2
      else
        journal_event "application_rollback_failed"
      fi
    fi
    rollback_secrets
    case $? in
      0) journal_event "secret_rollback_completed" ;;
      2) journal_event "secret_rollback_unavailable" ;;
      *) journal_event "secret_rollback_failed" ;;
    esac
  fi
  return "$exit_status"
}
trap finish EXIT

cd "$compose_dir"
docker compose --env-file "$env_file" -f compose.yml config --quiet
docker compose --env-file "$env_file" -f compose.yml pull
docker compose --env-file "$env_file" -f compose.yml up -d

health_url=${HEALTH_URL:?Set HEALTH_URL in the server compose environment}
for _ in $(seq 1 60); do
  if curl --fail --silent --show-error --output /dev/null "$health_url"; then
    if [[ "$images_supplied" == true ]]; then
      update_image_reference() {
        local key=$1
        local value=$2
        local temporary
        temporary=$(mktemp "$nomnom_root/config/.compose.env.XXXXXX")
        grep -v "^${key}=" "$env_file" > "$temporary"
        printf '%s=%s\n' "$key" "$value" >> "$temporary"
        chmod --reference="$env_file" "$temporary"
        chown --reference="$env_file" "$temporary"
        mv "$temporary" "$env_file"
      }
      update_image_reference BACKEND_IMAGE "$BACKEND_IMAGE"
      update_image_reference ADMIN_IMAGE "$ADMIN_IMAGE"
    fi
    rm -rf "$previous_root"
    deployment_succeeded=true
    journal_event "deployment_succeeded backend_image=$BACKEND_IMAGE admin_image=$ADMIN_IMAGE"
    printf 'Deployment health check passed\n'
    exit 0
  fi
  sleep 5
done

exit 1
