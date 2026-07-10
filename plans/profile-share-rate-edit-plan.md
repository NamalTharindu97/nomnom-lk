# Profile Tab — Share, Rate & Edit Profile Plan

## Current State

| Feature | Status |
|---|---|
| **Edit Profile** | UI exists, calls `PUT /users/me/profile` (name + phone), but no avatar upload. `avatar_url` not in Flutter model. |
| **Share App** | Works via `share_plus`, uses placeholder URL `https://nomnom.lk` |
| **Rate the App** | Dead tile — no `onTap` |
| **About** | Static "Version 1.0.0" — OK, leave as-is |

**Backend already has:**
- `PUT /users/me/profile` (router.go:132) — accepts `name`, `phone`; returns `avatar_url` in response
- `POST /api/v1/upload?folder=avatars` (router.go:196) — returns URL like `/api/v1/uploads/dev/avatars/uuid.jpg`
- `GET /api/v1/uploads/*key` (router.go:200) — serves files via `ServeFile`
- User model has `AvatarURL *string` column (user.go:23)

## Files to Modify

| # | File | Change |
|---|---|---|
| 1 | `lib/models/app_user.dart` | Add `avatarUrl` field + parse `avatar_url` in `fromJson` |
| 2 | `pubspec.yaml` | Add `image_picker: ^1.1.0` and `url_launcher: ^6.3.0` |
| 3 | `backend/internal/handlers/user_handler.go` | Add `AvatarURL *string` to `UpdateProfile` request struct |
| 4 | `lib/screens/edit_profile_screen.dart` | Wire camera icon → `ImagePicker` → `POST /api/v1/upload?folder=avatars` → `PUT /users/me/profile` with `avatar_url` → update local user |
| 5 | `lib/screens/profile_screen.dart` | Replace initial-letter avatar with `Image.network` when `user.avatarUrl` is set (letter fallback); add `onTap` to Rate tile (Play Store / App Store); update Share URL |

## Phase 1 — Avatar field in AppUser

**`lib/models/app_user.dart`:**
- Add `final String? avatarUrl;` field
- Parse `json['avatar_url'] as String?` in `fromJson`
- Add to `copyWith`

## Phase 2 — Backend: accept avatar_url in UpdateProfile

**`backend/internal/handlers/user_handler.go`:**
- Add `AvatarURL *string `json:"avatar_url"`` to the request struct
- Apply it same as `Name`/`Phone`

## Phase 3 — Image picker + upload + save flow

**`pubspec.yaml`:**
```yaml
dependencies:
  image_picker: ^1.1.0
  url_launcher: ^6.3.0
```

**`lib/screens/edit_profile_screen.dart`:**
- Wire camera icon on avatar `onTap` → `ImagePicker().pickImage()`
- On image picked:
  1. Upload via `POST /api/v1/upload?folder=avatars` using `FormData` (`MultipartFile`)
  2. Get back `url` from response
  3. Call `PUT /users/me/profile` with `{ "avatar_url": url }`
  4. Update `AuthProvider` user from response
  5. Show success snackbar + pop
- Display uploaded avatar in the avatar circle using `Image.network`

## Phase 4 — Profile header display

**`lib/screens/profile_screen.dart` (`_ProfileHeader`):**
- If `user.avatarUrl` is non-null — show `Image.network` (capped circle 72×72)
- If null — show current initial-letter fallback

## Phase 5 — Rate the App

**`lib/screens/profile_screen.dart` (`_MenuSection`):**
- Add `onTap` to the Rate tile
- Android: try `market://details?id=com.nomnomlk.nomnom_lk`, fallback to `https://play.google.com/store/apps/details?id=com.nomnomlk.nomnom_lk`
- iOS: `https://apps.apple.com/app/id...` (needs App Store ID — use placeholder)
- Import `package:url_launcher/url_launcher.dart`
- Use `launchUrl(Uri.parse(...), mode: LaunchMode.externalApplication)`
- Wrap in try/catch for `PlatformException`

## Phase 6 — Share URL update

**`lib/screens/profile_screen.dart`:**
- Replace `https://nomnom.lk` with actual store URL (same as Rate fallback)

## Verification

- `flutter pub get` ✓
- `flutter analyze` — 0 errors
- `go build ./...` ✓
- Edit Profile: pick avatar → upload → save → avatar shows in profile header
- Edit Profile: change name + phone → saved → reflects in profile immediately
- Rate tile: opens Play Store on emulator
- Share tile: opens share sheet with correct message + store URL

## Not Changing
- **About** — leave as-is
- **My Favorites** — already works
- **Theme / Language** — already works
