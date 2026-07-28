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

## Production Cutover

Production promotion remains disabled until the exact service UIDs, PostgreSQL
TLS key permissions, infrastructure image digests, firewall, backup tooling,
and rollback behavior are verified for the isolated production runtime. Set the
protected GitHub environment variable `PRODUCTION_DEPLOY_ENABLED=true` only
after those checks pass.

Do not use the zero digests or placeholder application tags from
`compose.env.example` for deployment.
