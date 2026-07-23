# Production Git and CI/CD Plan

## Goal

Replace the current direct `master` to Render behavior with a controlled release
process that supports local development, isolated staging verification, manual
production approval, immutable Docker images, post-deployment checks, and
repeatable rollback.

The selected model is:

- `staging` and `master` as the two long-lived branches.
- A fully isolated hosted staging environment.
- Manual approval through a protected GitHub `production` environment.
- `master` remains the production/live branch.
- The exact Docker images tested in staging are promoted to production without
  rebuilding them.

---

## Current State

### Git and GitHub

- The default branch is `master`.
- Feature work currently uses `phase/**` branches.
- `master` does not have branch protection.
- There are no open pull requests.
- CI runs for pushes to `master` and `phase/**`, and for pull requests to
  `master`.
- Docker images are built and published after a successful push to `master`.
- There is no dedicated staging branch or hosted staging environment.
- The existing GitHub environment named `DOCKER_USERNAME` appears accidental
  and has no protection rules.

### Render

- Production backend: `https://nomnom-backend-7iq0.onrender.com`
- Production admin: `https://nomnom-admin-e41y.onrender.com`
- Both services use mutable `latest` Docker tags.
- Render auto-deploy is enabled for both services.
- Production deployment does not require GitHub approval.
- Production PostgreSQL is a free resource scheduled to expire on
  August 20, 2026.

### Current Pipeline Risks

1. `master` can be pushed directly.
2. A successful `master` pipeline can update `latest`, which Render may deploy
   automatically.
3. Production deployment is not manually approved.
4. Docker images are pushed before Trivy scanning finishes.
5. There is no isolated environment for hosted verification.
6. There is no deployment health gate or production smoke-test gate.
7. Rollback depends on manual Render changes rather than a tested workflow.
8. The deployed Git commit is not recorded consistently.

---

## Target Release Flow

```text
Local feature/fix/phase branch
              |
              v
       Pull request to staging
              |
              v
      CI, security, and E2E gates
              |
              v
       Merge into staging branch
              |
              v
 Build and scan immutable SHA images
              |
              v
 Automatically deploy isolated staging
              |
              v
 Hosted smoke tests and manual checks
              |
              v
       Pull request staging -> master
              |
              v
      Merge into production branch
              |
              v
  GitHub production environment approval
              |
              v
 Promote exact staging-tested SHA images
              |
              v
 Production health and smoke tests
```

Normal code entering production must pass through staging. Direct production
pushes and direct Render deployments are emergency-only operations.

---

## Branch Model

| Branch pattern | Purpose | Deployment |
|---|---|---|
| `feature/*` | Normal product work | None |
| `fix/*` | Non-emergency bug fixes | None |
| `phase/*` | Existing milestone convention | None |
| `hotfix/*` | Urgent production fixes | Staging before production |
| `staging` | Integrated release candidate | Automatic staging |
| `master` | Approved production code | Manual production approval |

### Normal Development

1. Update local `staging` from `origin/staging`.
2. Create `feature/*`, `fix/*`, or `phase/*` from `staging`.
3. Develop and test locally.
4. Push the branch.
5. Open a pull request targeting `staging`.
6. Merge only after required CI checks pass.
7. Wait for the automatic staging deployment and smoke tests.
8. Perform manual verification against the staging URLs.
9. Open a release pull request from `staging` to `master`.
10. Merge after the staging release is accepted.
11. Approve the paused GitHub production deployment.
12. Verify the production deployment summary and smoke-test result.

### Hotfixes

1. Create `hotfix/*` from `master`.
2. Run normal CI.
3. Build the hotfix SHA and deploy it to staging.
4. Verify the issue and regression-sensitive paths.
5. Merge the hotfix to `master` through a pull request.
6. Approve production deployment.
7. Merge or rebase the production hotfix back into `staging` immediately.

No source fix should exist only in Render, a container, or the production
branch.

---

## Branch Protection

### `staging`

Configure GitHub branch protection to:

- Require a pull request before merging.
- Require backend, admin, Flutter, security, and E2E status checks.
- Require all conversations to be resolved.
- Require the branch to be up to date before merging when practical.
- Block force pushes.
- Block branch deletion.
- Prevent direct pushes, including normal administrator pushes.
- Allow squash merges for feature branches to keep integration history concise.

### `master`

Configure GitHub branch protection to:

- Require a pull request before merging.
- Require all CI checks.
- Require all conversations to be resolved.
- Block force pushes.
- Block branch deletion.
- Prevent direct pushes.
- Add a CI check that rejects normal production pull requests unless the source
  branch is `staging`.
- Permit an explicitly documented administrator bypass only for repository
  recovery.

The project currently has one developer. A mandatory PR reviewer could prevent
self-managed releases, so the primary human gate will be the protected GitHub
`production` environment. Review requirements can be increased when another
maintainer joins.

---

## Hosted Environments

### Staging Resources

Provision these isolated Render resources in Singapore:

| Resource | Purpose |
|---|---|
| `nomnom-backend-staging` | Staging Go API |
| `nomnom-admin-staging` | Staging Next.js dashboard |
| `nomnom-db-staging` | Staging PostgreSQL 16 |
| `nomnom-redis-staging` | Staging Redis/KV |

Use additional isolation for external services:

- R2 prefix: `staging/`
- Production R2 prefix remains `production/`.
- Use separate staging R2 credentials when practical.
- Use a separate Firebase project and credentials for staging.
- Use a separate JWT secret.
- Use a staging-only admin and smoke-test user.
- Configure staging CORS with only the staging admin origin.
- Build the staging admin with its staging backend proxy target.

Staging must never connect to the production PostgreSQL or Redis resources.

### Production Resources

Continue using the existing resources:

| Resource | Current value |
|---|---|
| Backend | `nomnom-backend` |
| Admin | `nomnom-admin` |
| PostgreSQL | `nomnom-db` |
| Redis | `nomnom-redis` |
| R2 prefix | `production/` |

Before enabling the final pipeline:

1. Disable Render auto-deploy for the backend and admin.
2. Stop deploying mutable `latest` tags.
3. Pin both services to known immutable SHA tags.
4. Make GitHub Actions the normal deployment controller.
5. Confirm the production database replacement or paid-plan strategy before
   August 20, 2026.

---

## Image and Release Policy

Images will be tagged using the source commit tested in staging:

```text
namal97/nomnom-backend:sha-<full-commit-sha>
namal97/nomnom-admin:sha-<full-commit-sha>
```

Rules:

1. SHA tags are immutable and must never be overwritten.
2. Images are scanned before they are pushed.
3. Staging deploys the SHA tags, not `latest`.
4. Production promotes the same staging-tested tags without rebuilding.
5. `latest` may remain as a convenience tag but must not be used by Render.
6. Store image tags and digests in a release manifest and GitHub job summary.
7. Keep enough historical SHA images to support rollback.

Example release manifest:

```json
{
  "source_sha": "<staging-commit-sha>",
  "backend_image": "namal97/nomnom-backend:sha-<staging-commit-sha>",
  "backend_digest": "sha256:<digest>",
  "admin_image": "namal97/nomnom-admin:sha-<staging-commit-sha>",
  "admin_digest": "sha256:<digest>"
}
```

---

## GitHub Environments

### `staging`

- No manual approval.
- Deployment branch limited to `staging`.
- Environment URL points to the staging admin.
- Holds staging Render service IDs, URLs, and smoke-test credentials.

### `production`

- Manual approval required from the repository owner.
- Deployment branch limited to `master`.
- Do not enable prevention of self-review while there is only one maintainer.
- Environment URL points to the production admin.
- Holds production Render service IDs, URLs, and smoke-test credentials.
- Production deployment jobs must declare `environment: production`.

Review and remove the existing accidental GitHub environment named
`DOCKER_USERNAME` after confirming no workflow uses it. Keep the actual
`DOCKER_USERNAME` value as a repository secret.

---

## Secrets and Variables

### Repository Secrets

Keep shared CI credentials at repository level:

```text
DOCKER_USERNAME
DOCKER_PASSWORD
SONAR_TOKEN
CODECOV_TOKEN
```

### Staging Environment

```text
RENDER_API_KEY
RENDER_BACKEND_SERVICE_ID
RENDER_ADMIN_SERVICE_ID
BACKEND_URL
ADMIN_URL
SMOKE_EMAIL
SMOKE_PASSWORD
```

### Production Environment

```text
RENDER_API_KEY
RENDER_BACKEND_SERVICE_ID
RENDER_ADMIN_SERVICE_ID
BACKEND_URL
ADMIN_URL
SMOKE_EMAIL
SMOKE_PASSWORD
```

Database, Redis, JWT, R2, Firebase, SMTP, Sentry, and bootstrap credentials
remain in Render. They should not be copied into GitHub unless a specific CI job
requires them.

Security Phase 2 created empty protected GitHub environments named `staging` and
`production` plus an inactive VPS secret-delivery workflow. While Render remains
the host, the rule above is unchanged: application secrets stay in Render. The
GitHub application-secret set is populated only during an explicitly approved
VPS cutover, using different staging and production values. P50 must integrate
with that workflow rather than creating a competing secret-delivery path.

The current admin image resolves `API_PROXY_TARGET` during the Next.js build.
Exact staging-to-production image promotion therefore remains blocked until the
proxy destination is made stable across environments or resolved at runtime.

---

## Workflow Design

### 1. `.github/workflows/ci.yml`

Replace or rename the current `test.yml` workflow.

Triggers:

```yaml
on:
  pull_request:
    branches: [staging, master]
  push:
    branches: [staging, master]
  workflow_dispatch:
```

Responsibilities:

- Gitleaks secret scanning.
- Go linting.
- Go vulnerability scanning.
- Backend unit tests with race detection and coverage.
- Backend integration tests.
- Admin linting and TypeScript checks.
- Admin dependency audit.
- Admin unit tests and coverage.
- Next.js production build.
- Playwright E2E tests.
- Flutter analysis.
- Flutter unit and widget tests.
- SonarCloud analysis.
- Optional Dockerfile build validation on relevant changes.

Improvements to make while refactoring:

- Use `npm ci` instead of `npm install`.
- Replace the deprecated SonarCloud action with its supported replacement.
- Add workflow concurrency and cancel superseded PR checks.
- Keep required job names stable for branch protection.
- Avoid duplicate `push` and `pull_request` runs for feature branches.
- Use path filters only after the complete pipeline is stable.
- Verify `go mod tidy` leaves the worktree unchanged instead of silently
  accepting dependency-file modifications.

### 2. `.github/workflows/deploy-staging.yml`

Trigger after successful CI on `staging`.

Use:

```yaml
concurrency:
  group: staging-deployment
  cancel-in-progress: true
```

Steps:

1. Verify the triggering CI run succeeded for the expected staging SHA.
2. Check out that exact SHA.
3. Build backend and admin images locally.
4. Build the admin with the staging backend proxy URL.
5. Scan both local images with Trivy.
6. Stop immediately on HIGH or CRITICAL findings according to the agreed
   vulnerability policy.
7. Push immutable SHA tags only after scans pass.
8. Write and upload the release manifest.
9. Update the staging backend Render service to the backend SHA image.
10. Start the backend deploy and poll Render until it is live or failed.
11. Poll the staging `/health` endpoint.
12. Update and deploy the staging admin SHA image.
13. Verify the admin login page and API rewrite.
14. Run staging smoke tests.
15. Publish URLs, SHA, image digests, and test results in the GitHub deployment
    summary.

Deploy backend before admin because the admin proxies API traffic to the
backend.

### 3. `.github/workflows/promote-production.yml`

Trigger when a pull request from `staging` to `master` is merged. The production
job must use the GitHub `production` environment so it pauses for approval.

Use:

```yaml
concurrency:
  group: production-deployment
  cancel-in-progress: false
```

Steps:

1. Confirm the merged pull request source was `staging`.
2. Identify the staging source SHA.
3. Confirm that staging deployment and smoke tests passed for that SHA.
4. Download or reconstruct the release manifest.
5. Confirm both SHA image tags and expected digests exist.
6. Pause for manual production approval.
7. Record the currently deployed production image tags for rollback.
8. Point the production backend service to the tested backend SHA image.
9. Deploy and wait for backend health.
10. Point the production admin service to the tested admin SHA image.
11. Deploy and verify the admin and API proxy.
12. Run read-only production smoke tests.
13. Record the deployment in the GitHub environment and job summary.
14. Create a release tag after successful verification.

The workflow must not rebuild images after production approval.

### 4. `.github/workflows/rollback-production.yml`

Manual `workflow_dispatch` inputs:

```text
backend_image_sha
admin_image_sha
rollback_reason
```

The workflow must:

1. Use the protected `production` environment.
2. Validate that both image tags exist.
3. Record the current deployment before changing it.
4. Deploy the requested backend image.
5. Run backend health checks.
6. Deploy the requested admin image.
7. Run production smoke tests.
8. Record the rollback reason, operator, old SHA, and restored SHA.
9. Require an incident note for application-level production failures.

A deploy-hook call using `latest` is not a rollback.

---

## Deployment Integration with Render

Use the Render API or Render CLI rather than a basic deploy hook because the
pipeline must select an exact image tag.

The deployment helper should:

1. Update the service image to the immutable SHA tag.
2. Create a Render deploy.
3. Poll the deploy ID until `live` or a terminal failure state.
4. Apply an explicit timeout.
5. Print the Render deploy URL and ID in the GitHub summary.

Do not expose the Render API key in logs. Service IDs and public URLs can be
GitHub environment variables rather than secrets.

`render.yaml` remains the infrastructure definition, but CI owns the active
runtime image after provisioning. Set `autoDeploy: false` for image services and
document that Blueprint synchronization must not restore mutable `latest`
deployment behavior.

---

## Smoke Tests

### Staging Tests

Staging may use controlled temporary data and cleanup:

- Backend health, PostgreSQL, and Redis status.
- Public restaurants, offers, categories, and active banners.
- Admin login through the staging admin proxy.
- Access-token refresh.
- Invalid-token rejection.
- Admin and owner RBAC.
- Owner-scoped restaurant and offer access.
- Image delivery.
- Upload and cleanup using a temporary object.
- SSE connection.
- Device-token registration using staging Firebase configuration.
- Safe create/update/delete tests for records marked as CI test data.

### Production Tests

Production tests must be read-only except for authentication session creation:

- Backend `/health`.
- Public restaurants, offers, categories, and active banners.
- Production admin login page.
- Admin API rewrite.
- Login and access-token refresh using a dedicated smoke account.
- Invalid-token rejection.
- Image retrieval.
- SSE connection establishment.

Do not run destructive Playwright CRUD suites against production data.

Store smoke-test credentials in GitHub environment secrets and avoid printing
tokens or passwords.

---

## Database and Migration Safety

The application currently performs GORM migrations during startup. Before
fully automated production releases:

1. Require schema changes to be backward-compatible with both the old and new
   application versions.
2. Do not remove or rename columns in the same release that stops using them.
3. Move toward versioned production migrations instead of relying only on
   `AutoMigrate`.
4. Back up production before risky migrations.
5. Never automatically reverse a database migration during image rollback.
6. Document when a release cannot safely roll back to an older application
   image.
7. Keep staging data disposable and separate from production.
8. Replace or upgrade the expiring production PostgreSQL resource before
   August 20, 2026.

Production startup must never execute sample-data cleanup or automatic demo
seeding. Staging may use an explicit idempotent seed operation.

---

## Mobile Development and Release

Backend/admin promotion and mobile store release are separate processes.

Run the Flutter app against staging during release verification:

```bash
flutter run \
  --dart-define=API_BASE_URL=https://<staging-backend>/api/v1
```

Build production releases only with the production API:

```bash
flutter build appbundle \
  --dart-define=API_BASE_URL=https://nomnom-backend-7iq0.onrender.com/api/v1
```

A later mobile workflow can trigger on tags such as `mobile-v1.0.0` and:

- Run Flutter tests.
- Build a signed AAB.
- Store build artifacts securely.
- Upload to Google Play Internal Testing.
- Require approval before promoting between Play tracks.

Do not automatically publish a mobile production release from every backend or
admin deployment.

---

## Observability and Release Records

Each deployment summary should include:

- Environment.
- Source SHA.
- Production merge SHA where applicable.
- Backend image tag and digest.
- Admin image tag and digest.
- Render deploy IDs.
- Backend and admin URLs.
- Smoke-test result.
- Approver.
- Previous production image tags.
- Rollback workflow link.

After successful production deployment:

- Create a release tag such as `release-2026.07.22.1`.
- Optionally create a GitHub Release with the deployment summary.
- Add Sentry release annotation when Sentry production monitoring is enabled.
- Retain failed deployment logs and smoke-test output as short-lived artifacts.

---

## Implementation Phases

### Phase 0: Safeguard Current Work

- [ ] Move the uncommitted `backend/scripts/seed.go` change to an appropriate
      feature branch.
- [ ] Remove the generated `backend/seed` binary from intended source changes
      and confirm whether it should be ignored.
- [ ] Confirm local and remote `master` are synchronized.
- [ ] Record the currently deployed backend and admin SHA images.
- [ ] Confirm current production health before changing deployment controls.

### Phase 1: Create the Branch and Environments

- [ ] Create `staging` from the current production `master`.
- [ ] Push `staging` to GitHub.
- [ ] Create GitHub `staging` environment.
- [ ] Create GitHub `production` environment.
- [ ] Configure production manual approval.
- [ ] Add environment branch restrictions.
- [ ] Review and remove the accidental `DOCKER_USERNAME` environment.

### Phase 2: Provision Isolated Staging

- [ ] Create staging PostgreSQL.
- [ ] Create staging Redis/KV.
- [ ] Create staging backend service.
- [ ] Create staging admin service.
- [ ] Configure staging R2 prefix and credentials.
- [ ] Configure staging Firebase project and secret file.
- [ ] Configure staging CORS and admin proxy.
- [ ] Add staging environment secrets and variables to GitHub.
- [ ] Perform the first manual staging deployment.
- [ ] Confirm staging data cannot access production resources.

### Phase 3: Refactor CI

- [ ] Rename or replace `.github/workflows/test.yml` with `ci.yml`.
- [ ] Change branch triggers to `staging` and `master` pull requests/pushes.
- [ ] Add PR concurrency cancellation.
- [ ] Change admin dependency installation to `npm ci`.
- [ ] Update the SonarCloud action.
- [ ] Add the production PR source-branch guard.
- [ ] Stabilize required check names.
- [ ] Verify all existing backend, admin, E2E, and Flutter checks remain green.

### Phase 4: Immutable Staging Delivery

- [ ] Add `.github/workflows/deploy-staging.yml`.
- [ ] Build images locally before publishing.
- [ ] Scan before push.
- [ ] Publish immutable SHA tags.
- [ ] Generate the release manifest.
- [ ] Deploy backend then admin through Render API/CLI.
- [ ] Add deployment polling and timeouts.
- [ ] Add staging smoke tests.
- [ ] Verify a second deployment replaces the first without using `latest`.

### Phase 5: Protect Branches

- [ ] Protect `staging`.
- [ ] Protect `master`.
- [ ] Verify direct pushes are rejected.
- [ ] Verify failed CI blocks staging merge.
- [ ] Verify only `staging` can enter the normal production release path.

Apply branch protection only after workflow job names are final, otherwise the
repository may require status checks that no longer exist.

### Phase 6: Production Promotion

- [ ] Add `.github/workflows/promote-production.yml`.
- [ ] Confirm it selects the staging source SHA.
- [ ] Confirm it does not rebuild images.
- [ ] Add the GitHub production approval gate.
- [ ] Add production deployment polling.
- [ ] Add read-only production smoke tests.
- [ ] Add deployment summaries and release tagging.

### Phase 7: Cut Over Production

- [ ] Confirm the current production image tags are available for rollback.
- [ ] Disable backend Render auto-deploy.
- [ ] Disable admin Render auto-deploy.
- [ ] Pin production to immutable current images.
- [ ] Update `render.yaml` with `autoDeploy: false`.
- [ ] Run a release candidate through staging.
- [ ] Merge `staging` to `master`.
- [ ] Approve the first controlled production deployment.
- [ ] Verify backend, admin, mobile, Firebase, R2, banners, SSE, and
      notifications.

### Phase 8: Rollback and Operations

- [ ] Add `.github/workflows/rollback-production.yml`.
- [ ] Test rollback using staging first.
- [ ] Perform a controlled production rollback drill when safe.
- [ ] Document release and incident procedures.
- [ ] Add deployment status badges or links.
- [ ] Add Sentry release annotation when available.

### Phase 9: Documentation

- [ ] Update `AGENTS.md` with the new current workflow.
- [ ] Update `docs/deployment/README.md`.
- [ ] Add `docs/deployment/git-workflow.md`.
- [ ] Add `docs/deployment/staging-setup.md`.
- [ ] Add `docs/deployment/release-process.md`.
- [ ] Add `docs/deployment/rollback.md`.
- [ ] Add `docs/deployment/incident-response.md`.
- [ ] Update credential references without adding secret values.

---

## Files to Add or Modify

| File | Action | Purpose |
|---|---|---|
| `.github/workflows/test.yml` | Replace or rename | Separate CI from deployment |
| `.github/workflows/ci.yml` | Add | Required validation checks |
| `.github/workflows/deploy-staging.yml` | Add | Build and deploy staging SHA images |
| `.github/workflows/promote-production.yml` | Add | Approved promotion to production |
| `.github/workflows/rollback-production.yml` | Add | Restore known image SHAs |
| `scripts/smoke-test.sh` | Add | Environment-aware smoke tests |
| `render.yaml` | Modify | Add staging resources and disable image auto-deploy |
| `docs/deployment/README.md` | Modify | New release quick reference |
| `docs/deployment/git-workflow.md` | Add | Developer branch workflow |
| `docs/deployment/staging-setup.md` | Add | Staging provisioning guide |
| `docs/deployment/release-process.md` | Add | Production release runbook |
| `docs/deployment/rollback.md` | Add | Rollback runbook |
| `docs/deployment/incident-response.md` | Add | Failed-release procedure |
| `AGENTS.md` | Modify | Current phase and branch policy |

The exact number of workflow files may be reduced if reusable workflows provide
a clearer implementation without weakening environment separation.

---

## Validation Scenarios

The implementation is not complete until all scenarios pass.

### Pull Request Controls

- [ ] Direct push to `staging` is rejected.
- [ ] Direct push to `master` is rejected.
- [ ] A failing backend check blocks merge.
- [ ] A failing admin or E2E check blocks merge.
- [ ] A failing Flutter check blocks merge.
- [ ] A feature PR targeting `master` is rejected by policy.

### Staging

- [ ] Merge to `staging` publishes immutable images.
- [ ] Trivy failure prevents image publication and deployment.
- [ ] Staging deploys backend before admin.
- [ ] Staging health and smoke tests pass.
- [ ] Staging uses only staging PostgreSQL, Redis, R2, and Firebase.
- [ ] The Flutter app can run against the staging backend.

### Production

- [ ] Merge to `master` pauses for manual approval.
- [ ] Rejecting approval leaves production unchanged.
- [ ] Approval deploys the exact staging-tested images.
- [ ] Production health checks pass.
- [ ] Production smoke tests do not modify business data.
- [ ] The deployed SHA and previous SHA are recorded.

### Rollback

- [ ] A previous image can be selected manually.
- [ ] Rollback requires production approval.
- [ ] Backend and admin rollback statuses are visible.
- [ ] Post-rollback health and smoke tests pass.
- [ ] Database compatibility limitations are documented.

---

## Completion Criteria

- [ ] Local development continues on feature, fix, phase, and hotfix branches.
- [ ] `staging` is the only normal integration target.
- [ ] `master` is the protected production/live branch.
- [ ] Production cannot deploy without manual GitHub approval.
- [ ] Render does not auto-deploy mutable `latest` images.
- [ ] Images are scanned before publication.
- [ ] Staging and production deploy immutable SHA images.
- [ ] Production promotes the exact images verified in staging.
- [ ] Staging never shares production data stores.
- [ ] Every deployment records its source SHA and image digests.
- [ ] Automated health and smoke tests run after every hosted deployment.
- [ ] A known previous release can be restored using a documented workflow.
- [ ] The production database expiration risk is resolved.
- [ ] Deployment documentation contains no credentials.

---

## Recommended First Implementation Slice

Implement the migration without changing production behavior initially:

1. Safeguard the current uncommitted seed changes.
2. Create `staging` from `master`.
3. Create GitHub environments.
4. Provision isolated staging resources.
5. Refactor CI and add immutable staging deployment.
6. Run at least one complete staging deployment and verification cycle.
7. Only then disable production auto-deploy and enable approved production
   promotion.

This order prevents a CI/CD migration from interrupting the currently working
production services.
