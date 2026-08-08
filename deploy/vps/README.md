# VPS Runtime

The staging runtime is active on the Contabo VPS and serves
`api.nomnomlk.com` and `admin.nomnomlk.com`. `compose.staging.yml` is the active
staging contract. `compose.yml` remains the isolated production contract and
must not be enabled until its separate configuration and secret layout are
installed and verified.

Application deployments use immutable full Git SHA tags. A successful CI run
for a push to `staging` triggers `.github/workflows/deploy-staging.yml`, which
builds and scans both application images, publishes them to Docker Hub, invokes
the fixed VPS deployment helper, and verifies the public endpoints.

## Security Model

- Only Caddy publishes host ports.
- Backend, admin, PostgreSQL, and Redis use internal Docker networks.
- Runtime secrets live under `/etc/nomnom/secrets`, outside Git and images.
- Each service receives only its declared secret files.
- PostgreSQL uses TLS inside the data network.
- Redis uses an ACL file derived from the password without storing the plaintext
  password in its configuration.
- Application images must use immutable Git SHA tags; infrastructure images must
  use reviewed digests.
- Containers drop Linux capabilities and use read-only filesystems where their
  runtime permits it.

## Server Layout

```text
/etc/nomnom/
  compose/
  config/
  secrets/
  secrets.previous/
```

The committed `compose.env.example` contains only non-secret placeholders.
Production values come from the protected GitHub environment and are installed
by `scripts/vps/install-secrets.sh`.

## Logs

All hosted services write to standard output and standard error. Docker retains
five 10 MB JSON log files per service, so logs remain available across process
restarts without growing without limit. Container recreation changes the raw
file path; use `docker logs` or the allowlisted `scripts/vps/logs.sh` helper
instead of reading `/var/lib/docker/containers` directly.

Install the reviewed helpers on staging as root-owned commands:

```bash
install -m 0755 scripts/vps/logs.sh /usr/local/sbin/nomnom-logs
install -m 0755 scripts/vps/refresh-log-links.sh /usr/local/sbin/nomnom-refresh-log-links
nomnom-refresh-log-links
```

The refresh helper creates stable root-owned aliases under `/var/log/nomnom`.
It canonicalizes every target and refuses paths outside Docker's container-log
directory. Successful deployments refresh the aliases after container
recreation.

Common commands:

```bash
nomnom-logs status
nomnom-logs paths
nomnom-logs backend --since 30m
nomnom-logs backend --since 2h --follow
journalctl -t nomnom-deploy-staging --since today
```

See [VPS logging and debugging](../../docs/deployment/vps-logging.md) for the
complete runbook, request-ID correlation, retention, and safe diagnostic rules.

## Production Cutover

Production promotion remains disabled until the exact service UIDs, PostgreSQL
TLS key permissions, infrastructure image digests, firewall, backup tooling,
and rollback behavior are verified for the isolated production runtime. Set the
protected GitHub environment variable `PRODUCTION_DEPLOY_ENABLED=true` only
after those checks pass.

Do not use the zero digests or placeholder application tags from
`compose.env.example` for deployment.
