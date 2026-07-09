# Profile Screen Refinement Plan

## Bugs
1. **"Browse Restaurants" has no back button**: `RestaurantsScreen` has no AppBar; pushed via `pushNamed` leaves user stuck
2. **"My Favorites" creates duplicate nav stack**: `pushNamed(AppRoutes.home, arguments: 2)` stacks a new MainShell on top of current
3. **"All Restaurants" stat card is dead**: shows `-` value, not tappable
4. **Edit icon on avatar does nothing**: sets false expectation

## Restaurants — Merged into Stats Card
- **Remove** "Browse Restaurants" menu tile from `_MenuSection`
- **Make** "All Restaurants" stat card in `_StatsRow` tappable with actual count from `RestaurantProvider`
- **Tapping** the stat card pushes `RestaurantsScreen` (same as before)
- **Add** AppBar with back button + title to `RestaurantsScreen` (it's a pushed route, not a tab)

## My Favorites — Nav Fix
- Instead of `pushNamed`, use callback to switch `MainShell` to tab index 2
- Pass callback from `MainShell` → `ProfileScreen`

## Profile Layout (final)

```
┌─ HEADER ──────────────────────────────────┐
│  [Avatar] ✏️ (tappable → Edit Profile)    │
│  Name                                      │
│  email@email.com                           │
│  [Foodie]                                  │
└────────────────────────────────────────────┘
┌─ STATS ───────────────────────────────────┐
│  ♥ Saved      │  🏪 All Restaurants       │  🕐 Member Since
│    5 deals    │      11 (tappable)        │  January 2026
└────────────────────────────────────────────┘
┌─ MENU ────────────────────────────────────┐
│  ♥  My Favorites                        ›  │→ tab 2
│  🔔  Notification Preferences           ›  │→ sub-screen (Hive toggles)
│  🌓  Theme                     [switch]    │
│  🌐  Language                   [popup]    │
│  ✏️  Edit Profile                       ›  │→ sub-screen
│  📤  Share NomNom LK                      │→ share_plus
│  ⭐  Rate the App                         │→ Play Store
│  ℹ️  About / Version 1.0.0                │
└────────────────────────────────────────────┘
┌─ SIGN OUT ────────────────────────────────┐
│  [  Sign Out / Sign In  ]                 │
└───────────────────────────────────────────┘
```

## Files to Modify

| File | Changes |
|---|---|
| `lib/screens/profile_screen.dart` | Remove Browse Restaurants tile; make All Restaurants stat tappable (fetch count from RestaurantProvider); wire My Favorites to tab switch callback; add Edit Profile, Notification Preferences, Share, Rate tiles; accept `onNavigateToTab` callback |
| `lib/screens/restaurants_screen.dart` | Add AppBar with `leading: BackButton()` + title |
| `lib/screens/main_shell.dart` | Expose `switchToTab(int)` via callback; pass to ProfileScreen |
| `lib/screens/edit_profile_screen.dart` | **New** — avatar picker, name field, phone field, email (read-only), Save button |
| `lib/screens/notification_prefs_screen.dart` | **New** — toggle list stored in Hive |
| `lib/core/app_routes.dart` | Add `editProfile`, `notificationPrefs` routes |
| `lib/main.dart` | Register new routes; pass tab callback |

## New Translation Keys to Add to ARB

```
editProfileTitle, editProfileNameLabel, editProfilePhoneLabel,
editProfileEmailLabel, editProfileSave, editProfileSaved,
notifPrefsTitle, notifPrefsNewOffers, notifPrefsPriceDrops, notifPrefsOpenings,
profileShareApp, profileRateApp
```

## Backend Check
- Check for `PUT /users/:id` endpoint
- If missing, build minimal one: update `name` + `phone` on `users` table

## Verification
- `flutter analyze` — 0 errors
- `flutter test` — all passing
- RestaurantsScreen: AppBar back button visible + functional
- All Restaurants stat: shows real count, tappable → pushes screen
- My Favorites: switches to tab 2, no duplicate nav stack
- Edit Profile: opens sub-screen, save flow works
- Notification Prefs: toggles persist across restarts

## Order of Work
1. Backend check + build `PUT /users/:id` if missing
2. RestaurantsScreen: add AppBar
3. profile_screen.dart: restructure menu, wire stats, remove Browse tile
4. main_shell.dart: expose tab switching
5. edit_profile_screen.dart: new screen
6. notification_prefs_screen.dart: new screen
7. ARB updates + regenerate l10n
8. Flutter analyze + test
