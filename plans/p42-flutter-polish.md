# P42 — Flutter Polish: Auth Errors, SSE Reconnect, Notifications, Share, Deep Linking

## Goal
Tie up remaining Flutter loose ends: graceful Firebase Auth error handling, SSE auto-reconnect with exponential backoff, notification images, offer sharing, and deep linking from notifications.

---

## Gap 1 — Firebase Auth Error Handling

### Current State
- `AuthService.signInWithGoogle()` catches `FirebaseAuthException` and rethrows
- `LoginScreen` shows generic "Sign in failed" regardless of error type
- Firebase Auth credentials file missing → `FirebaseAuthException` with `platform`: `null` crashes the app

**Impact:** Confusing error messages, crash on misconfigured emulators, no recovery path for common errors.

### Phase 1a: Add Error Mapping

#### `lib/services/auth_service.dart`

Map `FirebaseAuthException.code` to user-friendly messages:

| Code | Message (en) |
|------|-------------|
| `account-exists-with-different-credential` | An account already exists with the same email but different sign-in method. |
| `invalid-credential` | Invalid sign-in. Please try again. |
| `operation-not-allowed` | Google Sign-In is not enabled. Contact support. |
| `user-disabled` | This account has been disabled. |
| `user-not-found` | No account found with this email. |
| `wrong-password` | Wrong password. |
| `too-many-requests` | Too many attempts. Please wait a moment and try again. |
| `network-request-failed` | Network error. Check your connection. |
| default | Sign-in failed. Please try again. |

```dart
String _friendlyErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'account-exists-with-different-credential':
      return 'An account already exists with the same email but different sign-in method.';
    case 'invalid-credential':
      return 'Invalid sign-in. Please try again.';
    case 'operation-not-allowed':
      return 'Google Sign-In is not enabled. Contact support.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'user-not-found':
      return 'No account found with this email.';
    case 'wrong-password':
      return 'Wrong password.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'network-request-failed':
      return 'Network error. Check your connection.';
    default:
      return 'Sign-in failed. Please try again.';
  }
}
```

### Phase 1b: Handle Missing Credentials Gracefully

In `AuthService` init, wrap Firebase init in try/catch and set `_firebaseAvailable = false`:

```dart
class AuthService {
  bool _firebaseAvailable = true;

  AuthService() {
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        // Firebase is available
      }
    } catch (_) {
      _firebaseAvailable = false;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    if (!_firebaseAvailable) {
      throw Exception('Google sign-in is not configured.');
    }
    // ... existing code
  }
}
```

### Phase 1c: Update UI

#### `lib/screens/login_screen.dart`

Show `SnackBar` with the friendly error message instead of a generic AlertDialog:

```dart
final errorMessage = _friendlyErrorMessage(e);
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(errorMessage), backgroundColor: Colors.red.shade700),
);
```

### Files Changed
| File | Change |
|------|--------|
| `lib/services/auth_service.dart` | Add `_firebaseAvailable` flag, error mapping |
| `lib/screens/login_screen.dart` | Show SnackBar with friendly error |

---

## Gap 2 — SSE Auto-Reconnect with Exponential Backoff

### Current State
- `SseService` connects once and never reconnects if the connection drops
- After 10 minutes of inactivity (server-side timeout), the SSE stream silently dies
- No reconnect attempt, no user notification

**Impact:** Notifications stop arriving after 10 minutes of app inactivity. Users miss time-sensitive offer expirations.

### Phase 2a: Add Reconnect Logic

#### `lib/services/sse_service.dart`

```dart
class SseService {
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _initialDelay = Duration(seconds: 1);
  static const Duration _maxDelay = Duration(seconds: 30);
  bool _shouldReconnect = true;

  Duration _getReconnectDelay() {
    // Exponential backoff: 1s, 2s, 4s, 8s, 16s, 30s (cap)
    final delay = _initialDelay * (1 << _reconnectAttempts);
    return delay > _maxDelay ? _maxDelay : delay;
  }

  Future<void> _reconnect() async {
    if (!_shouldReconnect || _reconnectAttempts >= _maxReconnectAttempts) return;
    
    _reconnectAttempts++;
    final delay = _getReconnectDelay();
    await Future.delayed(delay);
    
    if (!_shouldReconnect) return;
    
    try {
      await connect(); // or _connect() depending on actual method
      _reconnectAttempts = 0; // Reset on success
    } catch (_) {
      await _reconnect(); // Retry
    }
  }

  void disconnect() {
    _shouldReconnect = false;
    _reconnectAttempts = 0;
    // ... existing close logic
  }

  // Override the stream error handler to call _reconnect():
  // In the existing _eventStream or connect() method:
  // .handleError((_) => _reconnect())
}
```

### Phase 2b: Detect Connection Drop

Wrap the existing SSE subscription in a heartbeat listener (not really needed — `http.Client` returning `null` or `SocketException` handles it).

Add an `onReconnecting` callback to notify the UI:

```dart
class SseService {
  final VoidCallback? onReconnecting;
  // ...
}
```

### Phase 2c: Show Reconnecting Indicator

#### `lib/screens/main_shell.dart` (or a mini-banner)

```dart
// Listen to SSE service reconnection state
if (sseService.isReconnecting) {
  return Padding(
    padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
    child: Container(
      color: Colors.orange.shade100,
      padding: EdgeInsets.symmetric(vertical: 2, horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 12, height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Reconnecting...', style: TextStyle(fontSize: 12)),
        ],
      ),
    ),
  );
}
```

### Files Changed
| File | Change |
|------|--------|
| `lib/services/sse_service.dart` | Add reconnect loop, backoff, state callbacks |
| `lib/screens/main_shell.dart` | Show reconnecting banner |

---

## Gap 3 — Notification Images

### Current State
- `FcmMessagingService` extracts `title`, `body`, `data` from FCM payload
- `data` map includes `offer_id`, `restaurant_id` but no image URL
- Notifications appear in system tray without an image
- Notification detail screen shows text only

**Impact:** Plain text notifications blend into noise. Images increase tap-through rate by 2-3x according to FCM best practices.

### Phase 3a: Send Image URL in FCM Payload

#### `backend/internal/services/notification_service.go`

In `SendToUser()` and `SendToTopic()`, add `offer_image_url` to the FCM `data` payload:

```go
if offer != nil && offer.ImageURL != nil {
    data["offer_image_url"] = *offer.ImageURL
}
// Also add restaurant logo:
if restaurant != nil && restaurant.LogoURL != nil {
    data["restaurant_logo_url"] = *restaurant.LogoURL
}
```

Need to look up the offer/restaurant from the notification payload. If `data["offer_id"]` is present, fetch the offer to get its image URL.

### Phase 3b: Display Image in Flutter Notification

#### `lib/services/fcm_messaging_service.dart`

Parse `offer_image_url` and `restaurant_logo_url` from the data payload:

```dart
class FcmNotification {
  final String? title;
  final String? body;
  final String? offerImageUrl;
  final String? restaurantLogoUrl;
  final String? offerId;
  final String? restaurantId;
  // ...
}
```

#### Notification widget (e.g., `lib/widgets/notification_tile.dart`)

```dart
ListTile(
  leading: notification.offerImageUrl != null
    ? ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: notification.offerImageUrl!,
          width: 48, height: 48, fit: BoxFit.cover,
        ),
      )
    : Icon(Icons.notifications, color: Colors.orange),
  title: Text(notification.title ?? ''),
  subtitle: Text(notification.body ?? ''),
)
```

### Phase 3c: Big Picture Style Notification (Android)

```dart
// In _showLocalNotification:
final bigPictureStyle = AndroidBigPictureStyle(
  largeIcon: largeIcon,
  contentTitle: notification.title ?? '',
  summaryText: notification.body ?? '',
  bigLargeIcon: largeIcon,
);
```

### Files Changed
| File | Change |
|------|--------|
| `backend/internal/services/notification_service.go` | Add `offer_image_url` + `restaurant_logo_url` to FCM data payload |
| `lib/services/fcm_messaging_service.dart` | Parse image URLs, add to notification model |
| `lib/widgets/notification_tile.dart` | Display image in notification list |

---

## Gap 4 — Offer Share

### Current State
- No share functionality for offers
- Users cannot share a deal with friends via WhatsApp, Messenger, etc.

**Impact:** Zero viral growth potential. Word-of-mouth is the #1 marketing channel for food deals.

### Phase 4a: Add Share Service

#### `lib/services/share_service.dart` (NEW)

```dart
import 'package:share_plus/share_plus.dart';
import '../models/offer.dart';

class ShareService {
  Future<void> shareOffer(Offer offer) async {
    final text = _formatShareText(offer);
    await Share.share(text, subject: offer.title);
  }

  String _formatShareText(Offer offer) {
    final dealText = offer.discountPercent != null
        ? '${offer.discountPercent}% OFF'
        : offer.offerPrice != null
            ? 'LKR ${offer.offerPrice}'
            : 'Great deal';
    return 'Check out this deal at ${offer.restaurantName ?? "NomNom LK"}!\n'
        '$dealText on ${offer.title}\n\n'
        '${offer.description ?? ""}\n\n'
        'Download NomNom LK to discover Sri Lanka\'s best food deals!';
  }
}
```

### Phase 4b: Add Dependency

#### `pubspec.yaml`

```yaml
dependencies:
  share_plus: ^7.2.2
```

### Phase 4c: Add Share Button to Offer Details

#### `lib/screens/offer_details_screen.dart`

```dart
AppBar(
  actions: [
    IconButton(
      icon: Icon(Icons.share),
      onPressed: () => ShareService().shareOffer(offer),
    ),
  ],
)
```

### Files Changed
| File | Change |
|------|--------|
| `pubspec.yaml` | Add `share_plus` |
| `lib/services/share_service.dart` | NEW |
| `lib/screens/offer_details_screen.dart` | Add share action button |

---

## Gap 5 — Deep Linking from Notifications

### Current State
- `FcmMessagingService._handleNotificationTap()` calls `onNavigate('/')`
- All three tap scenarios (foreground, background, terminated) route to home
- No deep-link to specific offer, restaurant, or deal details

**Impact:** Tapping a notification about a 50% off pizza deal should take the user directly to that offer, not to the home screen.

### Phase 5a: Implement Deep-Link Routing

#### `lib/services/fcm_messaging_service.dart`

```dart
String _resolveDeepLink(Map<String, dynamic>? data) {
  if (data == null) return '/';
  
  final offerId = data['offer_id'];
  if (offerId != null) return '/offer/$offerId';
  
  final restaurantId = data['restaurant_id'];
  if (restaurantId != null) return '/restaurant/$restaurantId';

  return '/';
}
```

#### `lib/main.dart` — Update `onNavigate` handler

```dart
void _handleNotificationNavigation(String route) {
  Navigator.pushReplacementNamed(context, route);
}
```

### Phase 5b: Add Named Routes

#### `lib/core/app_routes.dart`

```dart
static const String offerDetail = '/offer';
static const String restaurantDetail = '/restaurant';

static String offerDetailPath(String id) => '$offerDetail/$id';
static String restaurantDetailPath(String id) => '$restaurantDetail/$id';
```

### Phase 5c: Wire Generator /NavigatorObserver

Not needed — just use named routes with `Navigator.pushReplacementNamed()`.

### Files Changed
| File | Change |
|------|--------|
| `lib/services/fcm_messaging_service.dart` | `_resolveDeepLink()` based on `data` payload |
| `lib/core/app_routes.dart` | Add `offerDetail`, `restaurantDetail` routes |
| `lib/screens/offer_details_screen.dart` | Ensure route name matches `/offer/:id` |
| `lib/screens/restaurant_details_screen.dart` | Ensure route name matches `/restaurant/:id` |
| `lib/main.dart` | Use resolved deep link in navigation handler |

---

## Summary

| Gap | Effort | New Files | Modified Files | Dependencies Added |
|-----|--------|-----------|----------------|-------------------|
| Firebase Auth errors | ~1 hr | 0 | 2 | 0 |
| SSE reconnect | ~1.5 hr | 0 | 2 | 0 |
| Notification images | ~2 hr | 0 | 3 | 0 |
| Offer share | ~1 hr | 1 | 2 | `share_plus` |
| Deep linking | ~1 hr | 0 | 4 | 0 |
| **Total** | **~6.5 hr** | **1** | **13** | **1** |

### Implementation Order
1. SSE reconnect (most impactful — notifications stop after 10 min)
2. Notification images (next most impactful — 2-3x notification engagement)
3. Deep linking (complements notification images)
4. Firebase Auth error handling (small, easy win)
5. Offer share (lowest effort, enables viral growth)

### Verification
- [ ] SSE auto-reconnects after killing backend container (within 30s)
- [ ] Reconnecting banner shows during reconnect
- [ ] FCM notification shows offer image in notification tray
- [ ] Tapping notification → deep links to offer/restaurant detail page
- [ ] Share button → system share sheet with formatted text
- [ ] Firebase Auth errors show friendly SnackBar messages
- [ ] Missing Firebase creds → graceful "not configured" message, no crash
