# NomNom LK

NomNom LK is a dark-first Flutter mobile app for Sri Lankan food offers.

The current implementation is frontend-only and powered by mock data. It includes mock authentication, persistent favorites, offer search, offer details, and a bottom-navigation shell ready for a future REST API service layer.

## Features

- Dark-first Material 3 UI
- Mock Google login and guest mode
- Email login interface for future backend integration
- Home feed with Sri Lankan-style food offers
- Search by food or restaurant name
- Persistent favorites with `SharedPreferences`
- Offer details screen
- Clean separation of models, services, providers, screens, widgets, and theme utilities

## Run

This workspace does not currently include generated Android/iOS platform folders because the Flutter SDK is not available in the local environment.

Once Flutter is installed, generate the mobile platform folders and run the app:

```bash
flutter create . --project-name nomnom_lk --org com.nomnomlk --platforms android,ios
flutter pub get
flutter run
```
