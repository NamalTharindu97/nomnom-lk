# VPS Logging And Debugging

NomNom LK keeps application logs on standard output and standard error. Docker
collects them with the `json-file` driver and rotates each service at 10 MB,
retaining five files. This gives backend, admin, Caddy, PostgreSQL, and Redis a
maximum combined application-log footprint of approximately 250 MB.

## Server Access

```bash
ssh nomnom-live
```

The active staging runtime is defined by:

```text
/etc/nomnom/compose/compose.staging.yml
/etc/nomnom/compose/compose.staging.env
```

The reviewed helpers are installed as:

```text
/usr/local/sbin/nomnom-logs
/usr/local/sbin/nomnom-refresh-log-links
```

Install or update it from a reviewed checkout with:

```bash
install -m 0755 scripts/vps/logs.sh /usr/local/sbin/nomnom-logs
install -m 0755 scripts/vps/refresh-log-links.sh /usr/local/sbin/nomnom-refresh-log-links
nomnom-refresh-log-links
```

## Application Logs

```bash
nomnom-logs status
nomnom-logs paths
nomnom-logs backend --since 30m
nomnom-logs backend --since 2h --follow
nomnom-logs admin --since 1h
nomnom-logs caddy --since 1h
nomnom-logs postgres --since 1h
nomnom-logs redis --since 1h
```

The helper accepts only the five known staging services. `--since` accepts a
positive duration ending in `s`, `m`, `h`, or `d`. It does not read the Compose
environment or secret files.

## Stable Host Paths

The active staging logs have stable, descriptive host aliases:

```text
/var/log/nomnom/backend.json.log
/var/log/nomnom/admin.json.log
/var/log/nomnom/caddy.json.log
/var/log/nomnom/postgres.json.log
/var/log/nomnom/redis.json.log
```

These are root-owned symbolic links to Docker's current JSON log files. They
live outside the containers and can be inspected directly by a root operator.
The `.json.log` suffix is intentional because direct reads include Docker's JSON
envelope. Use `nomnom-logs` for clean application output.

`nomnom-refresh-log-links` obtains each target from `docker inspect`, resolves
it to a canonical path, and refuses any target that is not a matching 64-character
container ID beneath `/var/lib/docker/containers`. All five targets are
validated before publication, each replacement is atomic, and previous aliases
are restored if publication fails. The staging deployment helper refreshes them after successful
container recreation and after rollback. Production aliases will use
`/var/log/nomnom/production` when the isolated production runtime is enabled.

Do not configure logrotate for these aliases. Docker owns and rotates the target
files. Container recreation changes the internal target, while the descriptive
alias remains stable.

Docker's raw files are stored under:

```text
/var/lib/docker/containers/<container-id>/<container-id>-json.log
```

Container IDs and raw paths change after recreation. Use the stable aliases or
`nomnom-logs` for normal operations. Find an internal path only when diagnosing
Docker itself:

```bash
docker inspect --format '{{.LogPath}}' nomnom-staging-backend-1
```

## Request Correlation

Every API response includes `X-Request-ID`. Backend request logs include the
same value with method, sanitized query, status, latency, and client IP. Flutter
records a safe request ID from failed API responses in debug output and as a
Sentry breadcrumb.

A Flutter diagnostic line looks like:

```text
API error: GET /api/v1/offers status=500 request_id=<request-id>
```

Use the identifier to locate the corresponding structured backend record. Do
not paste access tokens, cookies, passwords, response bodies, or complete user
records into shell commands or issue reports.

Caller-provided request IDs are limited to 128 safe characters. Invalid values
are replaced with server-generated UUIDs to prevent control-character and log
injection attacks.

Flutter breadcrumbs replace UUID and numeric path segments with `:id`. Backend
panic telemetry uses the Gin route template and reports unmatched routes without
including the raw URL path.

## Error And Panic Diagnostics

Backend `4xx` responses use warning level and `5xx` responses use error level.
Recovered panics include:

- Request ID
- HTTP method
- Gin route template rather than a raw resource identifier
- Stack trace

The client still receives only the generic `INTERNAL_ERROR` response and the
request ID. When `SENTRY_DSN` is configured, the panic is also sent to Sentry
with safe request context. Query values, headers, cookies, authorization values,
and request bodies are excluded.

## Operational Journal

Deployment, backup, and restore scripts write safe lifecycle events to the
persistent system journal:

```bash
journalctl -t nomnom-deploy-staging --since today
journalctl -t nomnom-deploy --since today
journalctl -t nomnom-backup --since today
journalctl -t nomnom-restore --since today
```

Follow staging deployment events:

```bash
journalctl -t nomnom-deploy-staging --follow
```

Journal events include status, immutable image references, validated backup
object identifiers, exit status, and restore table count. They never include
environment values, secret contents, encryption identities, or database data.

The production backup script is available, but a backup timer must not be
reported as active until the protected production runtime and timer have been
installed and verified.

## Rotation Verification

After recreating a container, verify its active policy:

```bash
docker inspect --format '{{json .HostConfig.LogConfig}}' nomnom-staging-backend-1
```

Expected values:

```json
{"Type":"json-file","Config":{"max-file":"5","max-size":"10m"}}
```

Logging options apply only when Docker creates a container. The normal staging
deployment recreates backend and admin, so those services receive the policy
automatically after the updated Compose file is installed. During the logging
rollout, recreate Caddy, PostgreSQL, and Redis once in an approved maintenance
window, then verify each service with `docker inspect`. Do not restart the data
services merely to refresh logging during an unrelated application deployment.

Backend Sentry remains disabled when `SENTRY_DSN` is empty. Configure the value
in the root-owned staging Compose environment, recreate only the backend, and
confirm the startup log contains `Sentry initialized` before relying on remote
panic delivery.

Inspect storage without reading log contents:

```bash
docker system df
df -h /var/lib/docker /var/log
```

## Mobile Logs

Flutter process and Android logs remain on the development device, not the VPS:

```bash
flutter logs -d emulator-5554
adb -s emulator-5554 logcat
```

Release crashes and API failure breadcrumbs are sent to Sentry only when the
app was built with a valid `SENTRY_DSN`. The VPS stores backend diagnostics, not
raw device logs.
