# P52 Recruiter Hosting Split

## Baseline

- Product staging currently runs recruiter-enabled SHA `fb3d7040ba207a023a89b8666880a47b48c820b2`.
- The required pre-recruiter staging runtime is SHA `76e30e4de5b79c3220c59c9e52b80bdfd0e74a39`.
- Existing staging behavior, data, routes, admin/owner login, API URLs, and Flutter connectivity must remain intact.
- The recruiter demo has passed local, CI, and hosted read-only security journeys and must retain those protections.
- `admin.nomnomlk.com` and `api.nomnomlk.com` remain product staging endpoints.
- `demo.nomnomlk.com` is the dedicated recruiter endpoint.

## Architecture

- Keep the existing staging Caddy as the only host listener on ports 80/443.
- Add an isolated `nomnom-recruiter` Compose project with separate backend, admin, PostgreSQL, Redis, network, volumes, and generated secrets.
- Give recruiter application services unique Compose names so Docker DNS cannot shadow staging's `admin` or `backend` service aliases when Caddy joins both edge networks.
- Attach Caddy only to the recruiter edge network and route `demo.nomnomlk.com` to `recruiter-admin:3000`.
- Keep recruiter PostgreSQL and Redis on an internal network with no host ports.
- Clone staging data once, clear session/device/notification/audit/favorite data, anonymize all non-viewer accounts, and disable their login.
- Reuse approved R2 reads so existing restaurant/offer images continue to render. New object keys use the `recruiter` prefix; viewer upload routes remain denied.
- Pin recruiter images to a full staging-tested P52 SHA.
- Run recruiter deployment tooling from the current protected `staging` branch independently of the pinned recruiter application image SHA.

## Deployment Order

1. Add the proxied Cloudflare A record for `demo.nomnomlk.com`.
2. Merge and run `Deploy Recruiter Demo` with the recruiter SHA.
3. Verify recruiter login, allowlisted reads, sanitization, mutation denial, mobile navigation, logout, and rate limits.
4. Allow all staging recruiter JWTs to expire before rollback.
5. Dispatch `Deploy Staging` with pre-P52 SHA `76e30e4de5b79c3220c59c9e52b80bdfd0e74a39`.
   Set the protected staging variable `STAGING_DEPLOY_SHA` to that SHA so later
   staging pushes do not silently replace the intentional runtime pin.
6. Verify staging admin/owner login, API health, public data, Flutter endpoints, absence of the recruiter entry point, and a `404` from the staging demo-session route.
7. Confirm the dedicated recruiter URL remains on the pinned P52 images.

## Rollback

- Recruiter application deployment restores previous recruiter image references if public verification fails.
- Initial provisioning validates Compose, database health, certificate coverage, and Caddy syntax before restarting ingress.
- Staging image rollback uses the existing immutable deployment helper and does not rewrite protected Git history.
- Recruiter can be removed independently by disconnecting Caddy, removing its marked Caddy block, and running `docker compose down` in `/etc/nomnom-recruiter/compose`.
