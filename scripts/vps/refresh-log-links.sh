#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  printf 'refresh-log-links must run as root\n' >&2
  exit 1
fi

log_root=${NOMNOM_LOG_ROOT:-/var/log/nomnom}
base_log_root=/var/log/nomnom
compose_project=${NOMNOM_COMPOSE_PROJECT:-nomnom-staging}
log_group=${NOMNOM_LOG_GROUP:-adm}
services=(backend admin caddy postgres redis)
declare -A resolved_paths=()
declare -A staged_paths=()
declare -A previous_targets=()
declare -A had_previous=()
published=()

cleanup() {
  local exit_status=$?
  local service alias_path restore_path
  set +e

  for service in "${services[@]}"; do
    if [[ -n "${staged_paths[$service]:-}" ]]; then
      rm -f -- "${staged_paths[$service]}"
    fi
  done

  if [[ "$exit_status" -ne 0 ]]; then
    for service in "${published[@]}"; do
      alias_path="$log_root/${service}.json.log"
      if [[ "${had_previous[$service]:-false}" == true ]]; then
        restore_path="$log_root/.${service}.json.log.restore.$$"
        rm -f -- "$restore_path"
        if ln -s -- "${previous_targets[$service]}" "$restore_path" &&
          chown -h root:"$log_group" "$restore_path" &&
          mv -Tf -- "$restore_path" "$alias_path"; then
          :
        else
          printf 'Failed to restore previous log alias: %s\n' "$alias_path" >&2
        fi
      else
        rm -f -- "$alias_path"
      fi
    done
  fi

  trap - EXIT
  exit "$exit_status"
}
trap cleanup EXIT

if [[ ! "$compose_project" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  printf 'Invalid Compose project name\n' >&2
  exit 1
fi
if [[ ! "$log_root" =~ ^/var/log/nomnom(/[a-zA-Z0-9_-]+)?$ ]]; then
  printf 'Log root must be /var/log/nomnom or a direct environment directory beneath it\n' >&2
  exit 1
fi
if ! getent group "$log_group" >/dev/null; then
  printf 'Log group does not exist: %s\n' "$log_group" >&2
  exit 1
fi

if [[ -L "$base_log_root" || ( -e "$base_log_root" && ! -d "$base_log_root" ) ]]; then
  printf 'Base log path must be a real directory: %s\n' "$base_log_root" >&2
  exit 1
fi
install -d -m 0750 -o root -g "$log_group" "$base_log_root"
if [[ "$(realpath -e -- "$base_log_root")" != "$base_log_root" ]]; then
  printf 'Base log directory resolved to an unexpected path\n' >&2
  exit 1
fi
if [[ "$log_root" != "$base_log_root" ]]; then
  if [[ -L "$log_root" || ( -e "$log_root" && ! -d "$log_root" ) ]]; then
    printf 'Environment log path must be a real directory: %s\n' "$log_root" >&2
    exit 1
  fi
  install -d -m 0750 -o root -g "$log_group" "$log_root"
  if [[ "$(realpath -e -- "$log_root")" != "$log_root" ]]; then
    printf 'Environment log directory resolved to an unexpected path\n' >&2
    exit 1
  fi
fi

# Validate every source and destination before publishing any alias.
for service in "${services[@]}"; do
  container="${compose_project}-${service}-1"
  log_path=$(docker inspect --format '{{.LogPath}}' "$container")
  resolved=$(realpath -e -- "$log_path")

  if [[ ! "$resolved" =~ ^/var/lib/docker/containers/([0-9a-f]{64})/([0-9a-f]{64})-json\.log$ || "${BASH_REMATCH[1]}" != "${BASH_REMATCH[2]}" ]]; then
    printf 'Refusing unexpected Docker log path for %s: %s\n' "$service" "$resolved" >&2
    exit 1
  fi

  alias_path="$log_root/${service}.json.log"
  if [[ -e "$alias_path" && ! -L "$alias_path" ]]; then
    printf 'Refusing to replace non-symlink log alias: %s\n' "$alias_path" >&2
    exit 1
  fi
  resolved_paths[$service]=$resolved
  if [[ -L "$alias_path" ]]; then
    had_previous[$service]=true
    previous_targets[$service]=$(readlink -- "$alias_path")
  else
    had_previous[$service]=false
  fi
done

for service in "${services[@]}"; do
  staged_paths[$service]="$log_root/.${service}.json.log.$$"
  ln -s -- "${resolved_paths[$service]}" "${staged_paths[$service]}"
  chown -h root:"$log_group" "${staged_paths[$service]}"
done

for service in "${services[@]}"; do
  alias_path="$log_root/${service}.json.log"
  mv -Tf -- "${staged_paths[$service]}" "$alias_path"
  staged_paths[$service]=""
  published+=("$service")
  printf '%s -> %s\n' "$alias_path" "${resolved_paths[$service]}"
done
