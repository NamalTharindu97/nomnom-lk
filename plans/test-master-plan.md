# Master Test Coverage Plan — NomNom LK

**Current:** Backend 3.0%, Admin ~50 pages covered, Flutter ~5.6% (effectively 0%)
**Target:** Backend >50%, Admin 14/14 pages covered, Flutter >40%

## Three Phase Plan

### Phase A — Backend (~100 new test cases)
File: `plans/test-backend-plan.md`

| Priority | Layer | Coverage Gain | Difficulty |
|----------|-------|---------------|------------|
| P0 | Auth service + middleware | ~8% | Medium |
| P0 | Dashboard service (RBAC) | ~5% | Medium |
| P0 | RequireActive + RequireRole middleware | ~3% | Easy |
| P1 | Notification service (FCM mock) | ~3% | Hard |
| P1 | Restaurant service | ~4% | Easy |
| P1 | Repo integration tests (14 repos) | ~15% | Hard |
| P2 | Handler integration tests (15 handlers) | ~10% | Hard |
| P2 | Remaining middleware (audit, rate limit, etc.) | ~4% | Medium |

**Risk:** Integration tests require `nomnom_test` PostgreSQL DB — may need testcontainers or CI-only setup.

### Phase B — Admin E2E (~30 new test cases)
File: `plans/test-admin-plan.md`

| Priority | Page | New Tests | Difficulty |
|----------|------|-----------|------------|
| P0 | Banners (new) | 8 | Medium |
| P0 | Owners + Impersonation (new) | 6 | Hard |
| P0 | User CRUD (extend) | 6 | Easy |
| P1 | Offer approve/reject workflow (new) | 5 | Medium |
| P1 | Bulk action execution (extend) | 3 | Medium |
| P1 | Audit log search/filter (extend) | 4 | Easy |
| P2 | Analytics data assertions (extend) | 2 | Easy |
| P2 | Settings password change (extend) | 2 | Medium |
| P2 | Notification send (extend) | 2 | Hard |

**Risk:** Impersonation test requires two logged-in sessions (admin + owner) — use Playwright storageState.

### Phase C — Flutter (~79 new test cases)
File: `plans/test-flutter-plan.md`

| Priority | Area | New Tests | Difficulty |
|----------|------|-----------|------------|
| P0 | Models (offer, restaurant, user) | 11 | Easy |
| P0 | Utils (currency, order link parser) | 10 | Easy |
| P1 | Auth provider + login screen | 8 | Medium |
| P1 | Offer provider | 3 | Medium |
| P1 | Key widgets (offer_card, banner carousel) | 8 | Medium |
| P2 | Remaining screens (favorites, details, profile) | 13 | Medium |
| P2 | Remaining widgets | 9 | Easy |
| P2 | Services (api_client, SSE) | 7 | Hard |
| P3 | Remaining providers + screens | 10 | Medium |

**Risk:** Provider tests need robust mocking — existing `test/helpers/mocks.dart` is a good starting point but may need expansion for provider-specific methods.

## Execution Order Recommendation

```
Week 1:  Backend P0  (auth service, dashboard service, middleware)
         Admin P0     (banners, owners page objects + tests)

Week 2:  Backend P1  (notification service, restaurant service, repo integration)
         Admin P1     (user CRUD, offer workflow, bulk actions)

Week 3:  Flutter P0   (models, utils, auth provider, login screen)
         Admin P2     (audit log, analytics, settings extensions)

Week 4:  Flutter P1   (key widgets, offer provider)
         Backend P2   (handler integration, remaining middleware)

Week 5:  Flutter P2-3 (remaining screens, widgets, services)
```

## Target Coverage After Execution

| Area | Before | After |
|------|--------|-------|
| Backend services | ~8.7% | >70% |
| Backend middleware | ~9.8% | >60% |
| Backend handlers | ~0% | >30% (via integration) |
| Backend repos | ~0% | >40% (via integration) |
| **Backend overall** | **3.0%** | **>50%** |
| Admin E2E pages | 12/14 | 14/14 |
| Admin E2E tests | 50 | ~80 |
| Flutter models | 0% | 100% |
| Flutter utils | 0% | 100% |
| Flutter widgets | 29% | >60% |
| Flutter screens | 14% | >50% |
| Flutter providers | 0% | >40% |
| **Flutter overall** | **~5.6%** | **>40%** |
