# DevOps Plan

## P16 — Dev Environment: Background Processes + Hot Reload
- Backend auto-restart via `air` (Go hot reload, configured in `backend/.air.toml`)
- Admin dashboard runs with `next dev` (HMR built-in)
- Flutter runs on simulator in debug mode
- All three run as background `nohup` processes with logs routed to `*/logs/*.log`
- `.gitignore` updated to exclude log dirs

## Docker Infrastructure
- Postgres 16, Redis 7, MinIO via `docker compose up -d` in `backend/`
- Backend runs natively with `make run` (not in Docker)
- MinIO bucket `nomnom-images`

## Air Hot Reload
- `air` installed via `go install github.com/air-verse/air@latest`
- Config at `backend/.air.toml` watches `.go`/`.html`/`.tpl`/`.tmpl` changes
- Binary built to `backend/tmp/nomnom-api`

## MinIO Configuration
- Endpoint format: bare `host:port` only (e.g. `localhost:9000`) — minio-go v7.2.0 `New()` rejects fully qualified endpoints
- No `http://` scheme or path components
- Bucket: `nomnom-images`

## Environment Variables
- `.env` is gitignored
- Viper v1.19.0 does not strip inline `# comments` from `.env` values — parsed as part of the value string
- `AWS_S3_ENDPOINT=localhost:9000` (no scheme, no trailing comment)

## iOS Physical Device Testing
- Flutter 3.29.3 debug mode crashes on iOS 26.5+ physical devices (known JIT issue)
- Profile/release mode install issues via `devicectl`
- Workaround: Build release `.app` and install via `ios-deploy` (Homebrew tool)
- `DEVELOPMENT_TEAM = GBBV66G8DH` persisted in `project.pbxproj` for future iOS builds
- iOS push notifications require paid Apple Developer Account ($99/yr) for APNs entitlement
- `Runner.entitlements` with `aps-environment = development` required for APNs token

## Google Sign-In (Android)
- Not yet working — missing SHA-1 fingerprint in Firebase Console
- Steps to fix:
  1. Run `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1`
  2. Add to Firebase Console → Project Settings → General → Android app → Add fingerprint
  3. Verify Google Sign-In enabled in Authentication → Sign-in methods
  4. Rebuild and test on Android emulator

## Scripts & Build
- Build tags: `//go:build seed` and `//go:build migration` on script files to avoid `main()` conflict in `go build ./...`
- `air` config watches `.go`/`.html`/`.tpl`/`.tmpl`
