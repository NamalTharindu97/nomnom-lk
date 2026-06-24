## Goal
- Build a Go backend + admin dashboard + Flutter app for NomNom LK, a Sri Lanka-focused food offers discovery app.

## Constraints & Preferences
- **Stack:** Go + Gin + GORM + PostgreSQL 16 + Redis 7 + Firebase Auth + JWT + Sentry + Docker/Railway + Next.js 16 + Tailwind v4 + shadcn/ui + Flutter + Dio.
- **Build order & sign-off:** Phase-by-phase via feature branches (`phase/N-name`), merge to master after completion, branches preserved on remote.
- **Session context:** AGENTS.md updated and committed at end of every phase; read at session start to restore full context.
- **Architecture:** Standard struct-based DI; roles (user, restaurant_owner, admin); approval workflow (owner submits → admin approves); localization via JSONB translations; PostgreSQL full-text search; upload originals only; rate limiting (20 auth, 60 general, 10 upload).

## Progress
### Done
- **P1–P6:** See prior phases (Foundation, Auth, Core CRUD, Search, Upload, Notifications).
- **P7: Admin Dashboard** — Next.js 16 + Tailwind v4 + shadcn/ui. Pages: login, dashboard, restaurants (approve/reject), offers, users, push notifications. Auth context with localStorage JWT. Built on `phase/7-admin-dashboard`, merged to master.
- **P8: Flutter Integration** — Replaced mock services with API-backed services. New: `ApiClient` (Dio + JWT interceptor), `ApiAuthService` (Firebase + backend), `ApiOfferService`, `ApiFavoritesService`. Updated `Offer` model with `fromJson` (title, imageUrls, endDate, distanceKm), `AppUser` with `fromJson`. Updated providers, login screen (Firebase Google Sign-In), wired everything in `main.dart`. Firebase init graceful-fallback. `phase/8-flutter-integration` branch, merged to master.

### Blocked
- (none)

## Key Decisions
- All phase branches (`phase/3-core-crud` through `phase/8-flutter-integration`) created and merged to master, preserved on remote.
- Firebase token verification still mocked on backend (real Firebase Admin SDK init deferred).
- Flutter uses `dio` + `flutter_secure_storage` for API calls; Firebase Auth for Google Sign-In only (email/password goes directly to backend).
- Firebase init is wrapped in try-catch so app works without config files.
- `API_BASE_URL` env var configures backend URL (defaults to `http://localhost:8080/api/v1`).

## Next Steps
- **End-to-end testing:** Run backend + Flutter app + admin dashboard against the same API.
- **Firebase setup:** Add `GoogleService-Info.plist` (iOS) and `google-services.json` (Android) from Firebase Console, then run `flutterfire configure`.
- **Push notifications:** Connect Flutter device token registration to backend `/devices` endpoint.
- **Pagination & infinite scroll** in Flutter offer lists.
- **Localization** using the backend's JSONB translations.
