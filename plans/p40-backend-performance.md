# P40 — Backend Performance

## Goal
Optimize the three biggest backend performance gaps: (1) Redis caching for offer lists to reduce PostgreSQL load, (2) MinIO presigned URLs to eliminate backend proxy overhead for image serving, and (3) LRU eviction in the Flutter cache interceptor to prevent memory leaks.

---

## Gap 1 — Redis Offer List Cache (30s TTL)

### Current State
Every `GET /api/v1/offers` and `GET /api/v1/dashboard/offers` directly queries PostgreSQL:

```go
// offer_service.go
func (s *OfferService) List(ctx context.Context, page, perPage int, status string) ([]models.Offer, int64, error) {
    return s.repo.FindAll(ctx, page, perPage, status) // Direct DB query every time
}
```

**Impact:** Under load, identical queries hit PostgreSQL repeatedly. The home screen fetches offers on every app launch and pull-to-refresh. Multiple users hitting the same endpoint multiply DB connections.

### Why 30 Seconds?
- Food offers change infrequently (hours/days, not seconds)
- 30s balances freshness with cache hit rate
- SSE events already invalidate cache on CRUD — 30s is a safety net, not the primary freshness mechanism

### Implementation

#### `backend/internal/services/offer_service.go`

**Inject Redis client** if not already available:
```go
type OfferService struct {
    repo  *repository.OfferRepo
    redis *redis.Client  // <-- add
    // ...
}
```

**Cache-aware `List()` method:**
```go
func (s *OfferService) List(ctx context.Context, page, perPage int, status string) ([]models.Offer, int64, error) {
    cacheKey := fmt.Sprintf("offers:list:%s:%d:%d", status, page, perPage)

    // Try Redis cache
    if cached, err := s.redis.Get(ctx, cacheKey).Result(); err == nil {
        var result struct {
            Offers []models.Offer `json:"offers"`
            Total  int64          `json:"total"`
        }
        if err := json.Unmarshal([]byte(cached), &result); err == nil {
            return result.Offers, result.Total, nil
        }
    }

    // Cache miss — query DB
    offers, total, err := s.repo.FindAll(ctx, page, perPage, status)
    if err != nil {
        return nil, 0, err
    }

    // Serialize and store in Redis with 30s TTL (best-effort, ignore errors)
    if data, err := json.Marshal(map[string]any{
        "offers": offers,
        "total":  total,
    }); err == nil {
        s.redis.Set(ctx, cacheKey, string(data), 30*time.Second)
    }

    return offers, total, nil
}
```

**Cache invalidation on mutations:**

In `Create()`, `Update()`, `Delete()`, `Expire()`, and any bulk operations:
```go
func (s *OfferService) invalidateListCache(ctx context.Context) {
    // Redis scan for keys matching offers:list:* pattern
    iter := s.redis.Scan(ctx, 0, "offers:list:*", 0).Iterator()
    for iter.Next(ctx) {
        s.redis.Del(ctx, iter.Val())
    }
}
```

Better approach — use a cache version key to avoid full scan:
```go
// On mutation, increment a global version counter
func (s *OfferService) bumpCacheVersion(ctx context.Context) {
    s.redis.Incr(ctx, "offers:cache_version")
}

// In List(), append version to cache key
func (s *OfferService) List(ctx context.Context, ...) {
    version := s.redis.Get(ctx, "offers:cache_version").Val()
    cacheKey := fmt.Sprintf("offers:list:%s:%d:%d:v%s", status, page, perPage, version)
    // ...
}
```

Use the version key approach — it's O(1) per mutation instead of O(n) for scan-and-delete.

#### `backend/internal/services/dashboard_service.go`

Same pattern for owner-scoped lists:
```go
func (s *DashboardService) ListOffers(ctx context.Context, ownerID uuid.UUID, page, perPage int, status string) ([]models.Offer, int64, error) {
    cacheKey := fmt.Sprintf("offers:dashboard:%s:%s:%d:%d", ownerID, status, page, perPage)

    // Try cache, fall back to DB, write cache on miss
    // ...
}
```

Invalidate both public and dashboard caches on any offer mutation:
```go
func (s *DashboardService) invalidateOfferCache(ctx context.Context) {
    s.redis.Incr(ctx, "offers:cache_version")
    s.redis.Incr(ctx, "offers:dashboard_cache_version")
}
```

### Files Changed
| File | Change |
|------|--------|
| `backend/internal/services/offer_service.go` | Add Redis client, caching logic, cache invalidation |
| `backend/internal/services/dashboard_service.go` | Same pattern for dashboard lists |

---

## Gap 2 — MinIO Presigned URLs

### Current State
`UploadService.PresignedURL()` at `upload_service.go:145` is fully implemented but has zero call sites. Images are served through a backend proxy:

```
Client → GET /api/v1/uploads/:key → uploadHandler.ServeFile() → GetFile() → streams through Go → Client
```

**Impact:** Every image download consumes backend CPU, memory, and double bandwidth (MinIO → Go → Client). For a food app with many images on the home screen, this is a significant bottleneck.

### Implementation

#### `backend/internal/handlers/upload_handler.go`

Replace the `ServeFile` handler to redirect instead of proxy:

```go
func (h *UploadHandler) ServeFile(c *gin.Context) {
    key := c.Param("key")
    if key == "" {
        c.JSON(400, gin.H{"error": "Missing key"})
        return
    }

    // Generate presigned URL valid for 1 hour
    presignedURL, err := h.uploadService.PresignedURL(key, 1*time.Hour)
    if err != nil {
        // Fallback to direct proxy if presigned URL fails
        file, err := h.uploadService.GetFile(key)
        if err != nil {
            c.JSON(404, gin.H{"error": "File not found"})
            return
        }
        c.DataFromReader(200, file.Size, file.ContentType, file.Reader, nil)
        return
    }

    // Redirect client to presigned URL (302 temporary redirect)
    c.Redirect(http.StatusFound, presignedURL)
}
```

**Benefits:**
- Zero backend CPU/memory for image serving
- Direct MinIO → Client (or Cloudflare R2 → Client in production)
- Lower latency (no hop through Go)
- 302 redirect is lightweight — browser follows the redirect and caches the result
- 1-hour expiry means URLs are refreshed periodically (on page reload / data refresh)

**Edge cases handled:**
- If presigned URL generation fails (e.g., MinIO is down), fallback to direct proxy
- Presigned URL includes `?X-Amz-...` query params — browsers handle these transparently
- Client-side caching still works (browsers cache the redirect target)

### Files Changed
| File | Change |
|------|--------|
| `backend/internal/handlers/upload_handler.go` | Replace `ServeFile` body with presigned redirect + fallback |

**No client-side changes needed.** The URL format (`/api/v1/uploads/dev/images/uuid.jpg`) stays the same.

---

## Gap 3 — LRU Cache Eviction (Flutter)

### Current State
`CacheInterceptor` at `lib/services/cache_interceptor.dart` uses a plain `Map<String, _CacheEntry>`:

```dart
final Map<String, _CacheEntry> _cache = {};
```

This map grows unbounded. Every unique API path visited during a session creates a permanent entry. With pagination (`/offers?page=1`, `/offers?page=2`, ...), this accumulates without limit.

**Impact:** Memory leak on long sessions. A user scrolling through 50 pages of offers creates 50+ cache entries. On low-end Android devices (1-2GB RAM), this can cause OOM crashes.

### Implementation

#### `lib/services/cache_interceptor.dart`

**Replace `Map` with LRU-aware `LinkedHashMap`:**

```dart
import 'dart:collection';

class CacheInterceptor extends Interceptor {
  final int maxEntries;
  final Duration ttl;
  
  // LinkedHashMap with accessOrder: true — most recently accessed at end
  final Map<String, _CacheEntry> _cache = LinkedHashMap(
    equals: (a, b) => a == b,
    hashCode: (key) => key.hashCode,
  );

  CacheInterceptor({
    this.ttl = const Duration(minutes: 2),
    this.maxEntries = 100,
  });
```

**LRU eviction on insert:**

```dart
void _set(String key, _CacheEntry entry) {
  if (_cache.length >= maxEntries) {
    // Evict least-recently-accessed entry (first entry in access-order iteration)
    final eldestKey = _cache.keys.first;
    _cache.remove(eldestKey);
  }
  _cache[key] = entry;
}
```

**Update `onRequest` to mark access:**

```dart
@override
void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
  final key = options.path;
  final cached = _cache[key];
  
  if (cached != null && !cached.isExpired) {
    // Access-order movement happens automatically in LinkedHashMap
    // when we do _cache[key] = _cache.remove(key) — OR just re-insert
    _cache[key] = cached; // Moves to end in access-order mode
    return handler.resolve(cached.toResponse(options));
  }
  
  _cache.remove(key); // Clean up expired
  handler.next(options);
}
```

Wait — `LinkedHashMap` in Dart does NOT automatically move entries on access. We need to manually re-insert on access. Let me correct:

```dart
@override
void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
  final key = options.path;
  final cached = _cache[key];
  
  if (cached != null && !cached.isExpired) {
    // Re-insert to move to end (LRU: most recently used)
    _cache.remove(key);
    _cache[key] = cached;
    return handler.resolve(cached.toResponse(options));
  }
  
  _cache.remove(key);
  handler.next(options);
}
```

**Update `onResponse` to use `_set()`:**

```dart
@override
void onResponse(Response response, ResponseInterceptorHandler handler) {
  if (response.requestOptions.method == 'GET') {
    _set(response.requestOptions.path, _CacheEntry(response));
  }
  handler.next(response);
}
```

**Keep existing methods unchanged:**
- `invalidate(String path)` — removes prefix-matching entries
- `clear()` — removes all entries

**Add a diagnostic getter:**
```dart
int get cachedEntryCount => _cache.length;
```

### Files Changed
| File | Change |
|------|--------|
| `lib/services/cache_interceptor.dart` | Add `maxEntries`, `_set()` with eviction, re-insert on access |

---

## Summary

| Gap | Effort | Files | Key Technique |
|-----|--------|-------|---------------|
| Redis offer cache | ~2 hr | 2 | Cache-aside with version-based invalidation |
| Presigned URLs | ~1 hr | 1 | 302 redirect + fallback |
| LRU eviction | ~1 hr | 1 | `LinkedHashMap` capped at 100 entries |
| **Total** | **~4 hr** | **4** | |

### Implementation Order
1. Presigned URLs (simplest, single file change, high impact)
2. LRU eviction (self-contained, no backend)
3. Redis offer cache (largest change, needs careful testing)

### Verification

**Presigned URLs:**
```bash
# Get an image URL from an offer
curl -s http://localhost:8080/api/v1/offers | python3 -c "import sys,json; print(json.load(sys.stdin)['offers'][0].get('image_url',''))"

# Request the image — should get a 302 redirect (check with -v)
curl -v http://localhost:8080/api/v1/uploads/dev/images/uuid.jpg 2>&1 | grep -E "< HTTP|< Location"
# Expected: HTTP/1.1 302 Found + Location: http://minio:9000/...
```

**Redis cache:**
```bash
# First request — cache miss
curl -s http://localhost:8080/api/v1/offers > /dev/null

# Second request — cache hit (check backend logs for no DB query)
curl -s http://localhost:8080/api/v1/offers > /dev/null

# Redis should have the key
redis-cli KEYS "offers:list:*"
```

**LRU eviction:**
```dart
// In Flutter tests or debug console
final cache = CacheInterceptor(maxEntries: 3, ttl: Duration(minutes: 5));
// Fill cache
cache._set('/a', entry1); // [a]
cache._set('/b', entry2); // [a, b]
cache._set('/c', entry3); // [a, b, c]
cache._set('/d', entry4); // [b, c, d] — 'a' evicted (oldest)
// Access '/b' moves it to end
cache.get('/b');
// Now: [c, d, b]
```
