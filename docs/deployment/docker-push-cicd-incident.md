# Docker Push Incident and VPS CI/CD Remediation

## Incident

On 2026-07-28 the live admin container was recreated from an image built on
2026-07-26. The live page therefore still contained the removed email
placeholder and did not contain the password visibility control committed on
2026-07-28.

The local replacement image was 925 MB because the runtime stage copied the
complete build-time `node_modules` tree, including development dependencies.
Uploading that image over the developer workstation's connection repeatedly
timed out. A compressed Docker archive was transferred to the VPS as a one-time
recovery method. That archive transfer was not an intended deployment process.

## Root Causes

- The admin runtime image copied all dependencies instead of Next.js output
  tracing's minimal standalone runtime.
- `deploy-staging.yml` built images with `push: false` and then discarded them.
- `ci.yml` used unsupported `command` keys for GitHub Actions service
  containers, making the workflow invalid against the Actions schema.
- The CI Docker job published images only after pushes to `master`, rebuilt a
  different merge SHA, and did not deploy them to the VPS.
- `promote-production.yml` was a placeholder and still referenced Render.
- Staging Compose defaulted to mutable `latest` tags, so recreating a container
  did not prove which source commit was running.
- There was no automated public health verification and rollback around an
  application image deployment.

## Remediation

- The admin image uses Next.js `output: "standalone"` and runs the generated
  minimal server as a non-root user.
- Application images are tagged with the full 40-character Git commit SHA.
- A successful CI run for a push to `staging` triggers `deploy-staging.yml`.
- MinIO is started explicitly during CI because GitHub Actions service
  containers do not support a Compose-style `command` key.
- GitHub Actions builds and pushes `linux/amd64` backend and admin images using
  BuildKit's GitHub Actions cache.
- Trivy must pass before the VPS deployment step.
- The VPS deploy helper pulls only the backend and admin images, recreates only
  those services, verifies both public endpoints, persists the immutable image
  references, and restores the previous image IDs if verification fails.
- Production promotion deploys the exact staging PR head SHA after the protected
  GitHub `production` environment approval. It does not rebuild the images. The
  promotion also requires `PRODUCTION_DEPLOY_ENABLED=true`, which must remain
  unset until the isolated production Compose runtime is installed.

## Minor Change Flow

1. Open a feature/fix PR targeting `staging`.
2. Required CI checks pass and the PR is merged.
3. The staging branch CI run passes.
4. `Deploy Staging` builds changed layers, pushes immutable images, and deploys
   them to the VPS.
5. Public API and admin health checks pass before the deployment is reported as
   successful.

No Docker archive or workstation upload is needed. Docker Hub transfers only
layers not already present on the VPS.

## Required GitHub Environment Configuration

The `staging` environment requires:

- Secrets: `VPS_SSH_PRIVATE_KEY`, `VPS_SSH_KNOWN_HOSTS`
- Variables: `VPS_HOST`, `VPS_PORT`, `VPS_DEPLOY_USER`

Docker Hub credentials remain repository secrets:

- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`

The production environment retains its required reviewer and equivalent VPS
connection settings.
