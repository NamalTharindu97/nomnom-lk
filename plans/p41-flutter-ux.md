# P41 — Flutter UX: Localization + Offline Support

## Goal
Deliver two major Flutter features: (1) full localization support for Sinhala and Tamil alongside English, and (2) offline support so the app works without a network connection. These are the last two "Not yet" items from AGENTS.md.

---

## Gap 1 — Localization (Sinhala + Tamil)

### Current State
- `intl: ^0.19.0` is in `pubspec.yaml` but completely unused
- No ARB files exist
- No `localizationsDelegates` in `MaterialApp`
- `flutter_localizations` package not added
- All ~100 UI strings across 20+ screens are hardcoded in English
- API sends `Accept-Language: en` header unconditionally

**Impact:** Sri Lanka has three official languages (Sinhala, Tamil, English). Without Sinhala or Tamil support, the app misses a huge portion of the target market.

### Phase 1a: Setup Flutter Localization Infrastructure

#### `pubspec.yaml`

```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0
  # ... existing deps

flutter:
  generate: true  # Enable gen-l10n
```

#### `lib/l10n/l10n.yaml` (new — Flutter l10n config)

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
preferred-supported-locales:
  - en
  - si
  - ta
use-deferred-loading: false
```

### Phase 1b: Create ARB Files

#### `lib/l10n/app_en.arb` (English — baseline, full coverage)

```json
{
  "@@locale": "en",
  "appName": "NomNom LK",
  "@appName": {"description": "The application name"},

  "@@Splash Screen": "",
  "splashTagline": "Discover Sri Lanka's Best Food Deals",

  "@@Login Screen": "",
  "loginTitle": "Sign In",
  "loginEmailLabel": "Email",
  "loginPasswordLabel": "Password",
  "loginSignInButton": "Sign In",
  "loginContinueWithGoogle": "Continue with Google",
  "loginNoAccount": "Don't have an account?",
  "loginRegisterLink": "Register",
  "loginErrorGeneric": "Sign in failed. Please try again.",
  "loginErrorInvalidCredentials": "Invalid email or password",

  "@@Home Screen": "",
  "homeHotOffers": "Hot Offers",
  "homeBestDeals": "Best deals near you",
  "homeNoDeals": "No deals yet",
  "homeNoDealsSubtitle": "Check back for new offers from your favorite eateries.",
  "homeRestaurants": "Restaurants",

  "@@Search Screen": "",
  "searchHint": "Search for dishes, restaurants, or cuisines...",
  "searchEmptyTitle": "What are you craving?",
  "searchEmptySubtitle": "Search for dishes, restaurants, or cuisines.",
  "searchNoResults": "No deals found",
  "searchNoResultsSubtitle": "Try another dish or restaurant name.",
  "searchRestaurantsTab": "Restaurants",
  "searchOffersTab": "Offers",

  "@@Favorites Screen": "",
  "favoritesTitle": "Your Favorites",
  "favoritesEmpty": "Tap the heart on any deal to save it here.",

  "@@Restaurants Screen": "",
  "restaurantsTitle": "All Restaurants",
  "restaurantsEmpty": "No restaurants found.",

  "@@Notifications Screen": "",
  "notificationsTitle": "Notifications",
  "notificationsEmpty": "No notifications yet.",
  "notificationsMarkAllRead": "Mark all as read",

  "@@Navigation": "",
  "navHome": "Home",
  "navSearch": "Search",
  "navFavorites": "Favorites",
  "navRestaurants": "Restaurants",
  "navNotifications": "Notifications",

  "@@Offer Card": "",
  "offerDiscount": "{percent}% OFF",
  "@offerDiscount": {"placeholders": {"percent": {"type": "int"}}},
  "offerExpires": "Expires {date}",
  "@offerExpires": {"placeholders": {"date": {"type": "String"}}},
  "offerViewDetails": "View Details",

  "@@Offer Details": "",
  "offerDetailsTitle": "Offer Details",
  "offerOriginalPrice": "Was",
  "offerOfferPrice": "Now",
  "offerLocation": "Location",
  "offerValidUntil": "Valid until {date}",
  "@offerValidUntil": {"placeholders": {"date": {"type": "String"}}},
  "offerShare": "Share",

  "@@General": "",
  "generalLoading": "Loading...",
  "generalError": "Something went wrong",
  "generalRetry": "Try Again",
  "generalNoInternet": "No internet connection",
  "generalGuest": "Guest",
  "generalLogout": "Log Out",
  "generalCancel": "Cancel",
  "generalSave": "Save",
  "generalDelete": "Delete",
  "generalConfirm": "Confirm",

  "@@Favorites Button": "",
  "favoriteAdd": "Add to favorites",
  "favoriteRemove": "Remove from favorites"
}
```

#### `lib/l10n/app_si.arb` (Sinhala)

```json
{
  "@@locale": "si",
  "appName": "NomNom LK",
  "splashTagline": "ශ්‍රී ලංකාවේ හොඳම ආහාර දීමනා සොයා ගන්න",
  "loginTitle": "පුරන්න",
  "loginEmailLabel": "ඊමේල්",
  "loginPasswordLabel": "මුරපදය",
  "loginSignInButton": "පුරන්න",
  "loginContinueWithGoogle": "Google සමඟ ඉදිරියට යන්න",
  "loginNoAccount": "ගිණුමක් නැද්ද?",
  "loginRegisterLink": "ලියාපදිංචි වන්න",
  "loginErrorGeneric": "ප්‍රවේශය අසාර්ථකයි. කරුණාකර නැවත උත්සාහ කරන්න.",
  "loginErrorInvalidCredentials": "වලංගු නොවන ඊමේල් හෝ මුරපදය",
  "homeHotOffers": "උණුසුම් දීමනා",
  "homeBestDeals": "ඔබ අසල හොඳම දීමනා",
  "homeNoDeals": "තව දීමනා නැත",
  "homeNoDealsSubtitle": "ඔබේ ප්‍රියතම අවන්හල්වලින් නව දීමනා සඳහා නැවත පරීක්ෂා කරන්න.",
  "homeRestaurants": "අවන්හල්",
  "searchHint": "කෑම වර්ග, අවන්හල් හෝ ආහාර වර්ග සොයන්න...",
  "searchEmptyTitle": "ඔබට අවශ්‍ය කුමක්ද?",
  "searchEmptySubtitle": "කෑම වර්ග, අවන්හල් හෝ ආහාර වර්ග සොයන්න.",
  "searchNoResults": "දීමනා හමු නොවීය",
  "searchNoResultsSubtitle": "වෙනත් කෑම වර්ගයක් හෝ අවන්හල් නමක් උත්සාහ කරන්න.",
  "favoritesTitle": "ඔබේ ප්‍රියතම",
  "favoritesEmpty": "ඕනෑම දීමනාවක හදවත තබා එය මෙහි සුරකින්න.",
  "restaurantsTitle": "සියලුම අවන්හල්",
  "restaurantsEmpty": "අවන්හල් හමු නොවීය.",
  "notificationsTitle": "දැනුම්දීම්",
  "notificationsEmpty": "තව දැනුම්දීම් නැත.",
  "notificationsMarkAllRead": "සියල්ල කියවූ ලෙස සලකුණු කරන්න",
  "navHome": "මුල් පිටුව",
  "navSearch": "සොයන්න",
  "navFavorites": "ප්‍රියතම",
  "navRestaurants": "අවන්හල්",
  "navNotifications": "දැනුම්දීම්",
  "offerDiscount": "{percent}% ක් වට්ටම්",
  "offerExpires": "කල් ඉකුත්වන්නේ {date}",
  "offerViewDetails": "තොරතුරු බලන්න",
  "offerDetailsTitle": "දීමනා විස්තර",
  "offerOriginalPrice": "පැරණි මිල",
  "offerOfferPrice": "දැන් මිල",
  "offerLocation": "ස්ථානය",
  "offerValidUntil": "{date} දක්වා වලංගුයි",
  "offerShare": "බෙදාගන්න",
  "generalLoading": "පූරණය වේ...",
  "generalError": "යම් දෝෂයක් සිදු විය",
  "generalRetry": "නැවත උත්සාහ කරන්න",
  "generalNoInternet": "අන්තර්ජාල සම්බන්ධතාවයක් නැත",
  "generalGuest": "ආගන්තුක",
  "generalLogout": "පිටවන්න",
  "generalCancel": "අවලංගු කරන්න",
  "generalSave": "සුරකින්න",
  "generalDelete": "මකන්න",
  "generalConfirm": "තහවුරු කරන්න",
  "favoriteAdd": "ප්‍රියතමයට එක් කරන්න",
  "favoriteRemove": "ප්‍රියතමයෙන් ඉවත් කරන්න"
}
```

#### `lib/l10n/app_ta.arb` (Tamil)

```json
{
  "@@locale": "ta",
  "appName": "NomNom LK",
  "splashTagline": "இலங்கையின் சிறந்த உணவு சலுகைகளைக் கண்டறியவும்",
  "loginTitle": "உள்நுழைக",
  "loginEmailLabel": "மின்னஞ்சல்",
  "loginPasswordLabel": "கடவுச்சொல்",
  "loginSignInButton": "உள்நுழைக",
  "loginContinueWithGoogle": "Google மூலம் தொடர்க",
  "loginNoAccount": "கணக்கு இல்லையா?",
  "loginRegisterLink": "பதிவு செய்க",
  "loginErrorGeneric": "உள்நுழைவு தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.",
  "loginErrorInvalidCredentials": "தவறான மின்னஞ்சல் அல்லது கடவுச்சொல்",
  "homeHotOffers": "சூடான சலுகைகள்",
  "homeBestDeals": "உங்கள் அருகில் உள்ள சிறந்த சலுகைகள்",
  "homeNoDeals": "இன்னும் சலுகைகள் இல்லை",
  "homeNoDealsSubtitle": "உங்கள் பிடித்த உணவகங்களில் இருந்து புதிய சலுகைகளுக்காக மீண்டும் சரிபார்க்கவும்.",
  "homeRestaurants": "உணவகங்கள்",
  "searchHint": "உணவுகள், உணவகங்கள் அல்லது சமையல் வகைகளைத் தேடுக...",
  "searchEmptyTitle": "உங்களுக்கு என்ன வேண்டும்?",
  "searchEmptySubtitle": "உணவுகள், உணவகங்கள் அல்லது சமையல் வகைகளைத் தேடுக.",
  "searchNoResults": "சலுகைகள் எதுவும் கிடைக்கவில்லை",
  "searchNoResultsSubtitle": "வேறு உணவு அல்லது உணவகத்தின் பெயரை முயற்சிக்கவும்.",
  "favoritesTitle": "உங்கள் பிடித்தவை",
  "favoritesEmpty": "எந்த சலுகையிலும் இதயத்தைத் தொட்டு இங்கே சேமிக்கவும்.",
  "restaurantsTitle": "அனைத்து உணவகங்கள்",
  "restaurantsEmpty": "உணவகங்கள் எதுவும் இல்லை.",
  "notificationsTitle": "அறிவிப்புகள்",
  "notificationsEmpty": "இன்னும் அறிவிப்புகள் இல்லை.",
  "notificationsMarkAllRead": "அனைத்தையும் வாசித்ததாகக் குறிக்கவும்",
  "navHome": "முகப்பு",
  "navSearch": "தேடுக",
  "navFavorites": "பிடித்தவை",
  "navRestaurants": "உணவகங்கள்",
  "navNotifications": "அறிவிப்புகள்",
  "offerDiscount": "{percent}% தள்ளுபடி",
  "offerExpires": "{date} அன்று காலாவதியாகிறது",
  "offerViewDetails": "விவரங்களைப் பார்க்க",
  "offerDetailsTitle": "சலுகை விவரங்கள்",
  "offerOriginalPrice": "பழைய விலை",
  "offerOfferPrice": "இப்போதைய விலை",
  "offerLocation": "இருப்பிடம்",
  "offerValidUntil": "{date} வரை செல்லுபடியாகும்",
  "offerShare": "பகிர்க",
  "generalLoading": "ஏற்றுகிறது...",
  "generalError": "ஏதோ தவறு ஏற்பட்டது",
  "generalRetry": "மீண்டும் முயற்சிக்கவும்",
  "generalNoInternet": "இணைய இணைப்பு இல்லை",
  "generalGuest": "விருந்தினர்",
  "generalLogout": "வெளியேறுக",
  "generalCancel": "ரத்துசெய்",
  "generalSave": "சேமிக்க",
  "generalDelete": "நீக்குக",
  "generalConfirm": "உறுதிப்படுத்துக",
  "favoriteAdd": "பிடித்தவையில் சேர்க்க",
  "favoriteRemove": "பிடித்தவையிலிருந்து அகற்ற"
}
```

### Phase 1c: Wire Into MaterialApp

#### `lib/main.dart`

```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'l10n/app_localizations.dart';

MaterialApp(
  localizationsDelegates: [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: [
    const Locale('en'),
    const Locale('si'),
    const Locale('ta'),
  ],
  locale: Locale('en'), // Default — user preference TBD
  // ...
)
```

### Phase 1d: Replace All Hardcoded Strings

**Pattern:** `'Some string'` → `AppLocalizations.of(context)!.someString`

Example transformations:

| File | Old | New |
|------|-----|-----|
| `splash_screen.dart:15` | `'NomNom LK'` | `AppLocalizations.of(context)!.appName` |
| `login_screen.dart:42` | `'Sign In'` | `AppLocalizations.of(context)!.loginTitle` |
| `home_screen.dart:85` | `'Hot Offers'` | `AppLocalizations.of(context)!.homeHotOffers` |
| `search_screen.dart:30` | `'What are you craving?'` | `AppLocalizations.of(context)!.searchEmptyTitle` |
| `favorites_screen.dart:20` | `'Your Favorites'` | `AppLocalizations.of(context)!.favoritesTitle` |
| `notifications_screen.dart:25` | `'No notifications yet.'` | `AppLocalizations.of(context)!.notificationsEmpty` |
| `main_shell.dart:60` | `'Home'` | `AppLocalizations.of(context)!.navHome` |
| `offer_card.dart:35` | `'50% OFF'` | `AppLocalizations.of(context)!.offerDiscount(percent: offer.discountPercent)` |
| `general widgets` | `'Loading...'` | `AppLocalizations.of(context)!.generalLoading` |

Files to modify (full list):

| File | Strings |
|------|---------|
| `lib/screens/splash_screen.dart` | 2 |
| `lib/screens/login_screen.dart` | 10 |
| `lib/screens/home_screen.dart` | 8 |
| `lib/screens/search_screen.dart` | 6 |
| `lib/screens/favorites_screen.dart` | 4 |
| `lib/screens/restaurants_screen.dart` | 3 |
| `lib/screens/notifications_screen.dart` | 5 |
| `lib/screens/offer_details_screen.dart` | 8 |
| `lib/screens/main_shell.dart` | 5 |
| `lib/widgets/offer_card.dart` | 4 |
| `lib/widgets/favorite_button.dart` | 2 |
| `lib/widgets/discount_badge.dart` | 1 |
| `lib/widgets/shimmer_loading.dart` | 1 |
| `lib/widgets/empty_state.dart` | 2 |
| **Total ~20 files** | **~100 strings** |

### Phase 1e: Update API Locale Header

#### `lib/services/api_client.dart`

Replace hardcoded `Accept-Language: en` with the app's current locale:

```dart
import 'package:intl/intl.dart';

// In request interceptor:
options.headers['Accept-Language'] = Intl.defaultLocale?.split('_').first ?? 'en';
```

### Files Changed (Localization)
| File | Change |
|------|--------|
| `pubspec.yaml` | Add `flutter_localizations`, `generate: true` |
| `lib/l10n/l10n.yaml` | NEW — Flutter gen-l10n config |
| `lib/l10n/app_en.arb` | NEW — English strings |
| `lib/l10n/app_si.arb` | NEW — Sinhala strings |
| `lib/l10n/app_ta.arb` | NEW — Tamil strings |
| `lib/main.dart` | Add localizations delegates + supported locales |
| `lib/services/api_client.dart` | Dynamic `Accept-Language` header |
| 20 screen/widget files | Replace hardcoded strings |

---

## Gap 2 — Offline Support

### Current State
- In-memory cache with 2-minute TTL (lost on app restart)
- No local database (sqflite/hive/drift)
- No `connectivity_plus` package
- No offline queue for writes (favorites, notifications read status)
- Image caching via `CachedNetworkImage` only

**Impact:** App is completely unusable without network. In Sri Lanka's mobile network conditions, this means frequent blank screens.

### Architecture

```
┌─────────────────────────────────────────────────────┐
│  UI Layer (Screens / Widgets)                       │
├─────────────────────────────────────────────────────┤
│  Provider Layer (OfferProvider, etc.)               │
├───────────────────┬─────────────────────────────────┤
│  Repository Layer │  ConnectivityService            │
│  (local store)    │  (online/offline stream)         │
├─────────┬─────────┴─────────────────────────────────┤
│  Local  │             Network                        │
│  (hive) │             (Dio + CacheInterceptor)       │
└─────────┴───────────────────────────────────────────┘
```

### Phase 2a: Add Dependencies

#### `pubspec.yaml`

```yaml
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  connectivity_plus: ^5.0.2
  # ... existing deps

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.0
```

### Phase 2b: Connectivity Service

#### `lib/services/connectivity_service.dart` (NEW)

```dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  
  bool _isOnline = true;
  bool get isOnline => _isOnline;
  Stream<bool> get onConnectivityChanged => _controller.stream;

  ConnectivityService() {
    _connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(online);
      }
    });
  }

  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = results.any((r) => r != ConnectivityResult.none);
    return _isOnline;
  }

  void dispose() {
    _controller.close();
  }
}
```

### Phase 2c: Local Data Stores

#### `lib/services/local/offer_store.dart` (NEW)

```dart
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/offer.dart';

class OfferStore {
  static const String _boxName = 'offers';
  late Box<String> _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  Future<void> saveOffers(List<Offer> offers) async {
    final data = offers.map((o) => o.toJson()).toList();
    await _box.put('all', data.toString());
  }

  Future<void> saveOffersByPage(int page, List<Offer> offers) async {
    final data = offers.map((o) => o.toJson()).toList();
    await _box.put('offers_page_$page', data.toString());
  }

  List<Offer>? getOffersByPage(int page) {
    final raw = _box.get('offers_page_$page');
    if (raw == null) return null;
    final list = raw.split('},{').map((s) => /* parse */).toList();
    // Use proper JSON parsing
    return Offer.listFromJson(raw);
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
```

#### `lib/services/local/restaurant_store.dart` (NEW)

Same pattern as OfferStore — stores restaurant lists by page.

#### `lib/services/local/favorite_store.dart` (NEW)

```dart
class FavoriteStore {
  static const String _boxName = 'favorites';
  late Box<Set<String>> _box;

  Future<void> init() async {
    _box = await Hive.openBox<Set<String>>(_boxName);
  }

  Set<String> getFavorites() => _box.get('favorite_ids') ?? {};

  Future<void> addFavorite(String offerId) async {
    final favorites = getFavorites()..add(offerId);
    await _box.put('favorite_ids', favorites);
  }

  Future<void> removeFavorite(String offerId) async {
    final favorites = getFavorites()..remove(offerId);
    await _box.put('favorite_ids', favorites);
  }

  Future<void> syncFromRemote(Set<String> remoteIds) async {
    await _box.put('favorite_ids', remoteIds);
  }
}
```

#### `lib/services/local/notification_store.dart` (NEW)

Stores notifications for offline reading. Same pattern.

### Phase 2d: Update Providers

#### `lib/providers/offer_provider.dart`

```dart
class OfferProvider extends ChangeNotifier {
  final ApiOfferService _api;
  final OfferStore _offerStore;
  final ConnectivityService _connectivityService;
  
  bool _isOnline = true;

  OfferProvider({
    required ApiOfferService api,
    required OfferStore offerStore,
    required ConnectivityService connectivityService,
  }) : _api = api,
       _offerStore = offerStore,
       _connectivityService = connectivityService {
    _connectivityService.onConnectivityChanged.listen((online) {
      _isOnline = online;
      if (online) _syncQueuedActions();
    });
  }

  Future<void> loadOffers({bool forceRefresh = false}) async {
    if (_isOnline) {
      try {
        final response = await _api.fetchOffers();
        _offers = response.data;
        _totalPages = response.totalPages;
        // Cache locally
        await _offerStore.saveOffersByPage(_currentPage, _offers);
        return;
      } catch (e) {
        // Network error — fall through to local
      }
    }

    // Offline or network error — read from local store
    final cached = await _offerStore.getOffersByPage(_currentPage);
    if (cached != null) {
      _offers = cached;
    }
  }

  Future<void> _syncQueuedActions() async {
    // Sync any pending favorite toggles
    // ...
  }
}
```

#### `lib/providers/restaurant_provider.dart` — same pattern

#### `lib/providers/notification_provider.dart` — same pattern

#### `lib/providers/auth_provider.dart`

Wire `FcmMessagingService.registerCurrentToken()` to be called after connectivity restored (not just on login).

### Phase 2e: Wire Everything in `main.dart`

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final connectivityService = ConnectivityService();
  final offerStore = OfferStore();
  await offerStore.init();
  // ... init other stores

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: connectivityService),
        Provider.value(value: offerStore),
        // ... other stores
        ChangeNotifierProvider(create: (_) => OfferProvider(
          api: ApiOfferService(dio),
          offerStore: offerStore,
          connectivityService: connectivityService,
        )),
        // ...
      ],
      child: NomNomApp(),
    ),
  );
}
```

### Files Changed (Offline Support)

| File | Change |
|------|--------|
| `pubspec.yaml` | Add `hive`, `hive_flutter`, `connectivity_plus` |
| `lib/services/connectivity_service.dart` | NEW — online/offline stream |
| `lib/services/local/offer_store.dart` | NEW — Hive-based offer storage |
| `lib/services/local/restaurant_store.dart` | NEW — Hive-based restaurant storage |
| `lib/services/local/favorite_store.dart` | NEW — Hive-based favorites storage |
| `lib/services/local/notification_store.dart` | NEW — Hive-based notification storage |
| `lib/providers/offer_provider.dart` | Modify — offline fallback, sync queue |
| `lib/providers/restaurant_provider.dart` | Modify — offline fallback |
| `lib/providers/notification_provider.dart` | Modify — offline fallback |
| `lib/main.dart` | Initialize Hive, wire stores + connectivity |
| `lib/models/offer.dart` | Add `toJson()` / `listFromJson()` (if not already present) |

---

## Summary

| Gap | Effort | New Files | Modified Files | Dependencies Added |
|-----|--------|-----------|----------------|-------------------|
| Localization | ~4 hr | 5 | ~22 | `flutter_localizations` |
| Offline support | ~6 hr | 4 | ~6 | `hive`, `hive_flutter`, `connectivity_plus` |
| **Total** | **~10 hr** | **9** | **~28** | **4** |

### Implementation Order
1. Setup: add dependencies, run `flutter pub get`
2. Localization: create ARB files, run `flutter gen-l10n`
3. Localization: wire into MaterialApp
4. Localization: replace strings screen by screen (Splash → Login → Home → Search → ...)
5. Offline: create ConnectivityService
6. Offline: create Hive stores
7. Offline: update providers with offline fallback
8. Offline: wire in main.dart

### Verification
- [ ] `flutter gen-l10n` generates `app_localizations.dart` with all 3 locales
- [ ] App launches in English by default
- [ ] Change system locale to Sinhala → app strings render in Sinhala
- [ ] Change system locale to Tamil → app strings render in Tamil
- [ ] Force-close app, reopen with airplane mode → offers/restaurants load from local cache
- [ ] Toggle favorites offline → queued, sync when back online
- [ ] No crash on first launch (empty cache gracefully handled)
