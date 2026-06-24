# NomNom LK — Flutter Integration Guide

## Overview

This guide covers the changes needed to connect the existing Flutter app
to the new Go backend API.

## New Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  dio: ^5.4.0
  flutter_secure_storage: ^9.2.2
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
```

Run `flutter pub get`.

## New Files to Create

### 1. `lib/services/api_client.dart`

Dio HTTP client with JWT interceptor:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8080/api/v1',
      ),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept-Language': 'en'},
    ));

    _dio.interceptors.add(AuthInterceptor(_storage, _dio));
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.get(path, queryParameters: queryParameters);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> post(String path, dynamic data) async {
    final response = await _dio.post(path, data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> put(String path, dynamic data) async {
    final response = await _dio.put(path, data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> delete(String path) async {
    await _dio.delete(path);
  }
}
```

### 2. `lib/services/auth_interceptor.dart`

Handles 401 -> refresh -> retry:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final Dio _dio;

  AuthInterceptor(this._storage, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken != null) {
        try {
          final response = await _dio.post('/auth/refresh', data: {
            'refresh_token': refreshToken,
          });
          final data = response.data as Map<String, dynamic>;
          await _storage.write(key: 'access_token', value: data['access_token']);
          await _storage.write(key: 'refresh_token', value: data['refresh_token']);

          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer ${data['access_token']}';
          final retryResponse = await _dio.fetch(retryOptions);
          handler.resolve(retryResponse);
          return;
        } catch (e) {
          await _storage.deleteAll();
        }
      }
    }
    handler.next(err);
  }
}
```

### 3. `lib/services/api_auth_service.dart`

Replaces `AuthService`:

```dart
import '../models/app_user.dart';
import 'api_client.dart';

class ApiAuthService {
  final ApiClient _client;

  ApiAuthService(this._client);

  Future<AppUser> signInWithFirebase(String firebaseToken) async {
    final response = await _client.post('/auth/firebase', {
      'firebase_token': firebaseToken,
    });
    return _handleAuthResponse(response);
  }

  Future<AppUser> register(String email, String password, String name) async {
    final response = await _client.post('/auth/register', {
      'email': email,
      'password': password,
      'name': name,
    });
    return _handleAuthResponse(response);
  }

  Future<AppUser> login(String email, String password) async {
    final response = await _client.post('/auth/login', {
      'email': email,
      'password': password,
    });
    return _handleAuthResponse(response);
  }

  Future<void> logout() async {
    try {
      await _client.post('/auth/logout', {});
    } catch (_) {}
    const FlutterSecureStorage().deleteAll();
  }

  Future<AppUser?> restoreUser() async {
    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    if (token == null) return null;

    try {
      final response = await _client.get('/users/me');
      return AppUser.fromJson(response['data'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  AppUser _handleAuthResponse(Map<String, dynamic> response) async {
    final storage = const FlutterSecureStorage();
    await storage.write(key: 'access_token', value: response['access_token'] as String);
    await storage.write(key: 'refresh_token', value: response['refresh_token'] as String);
    return AppUser.fromJson(response['user'] as Map<String, dynamic>);
  }
}
```

### 4. `lib/services/api_offer_service.dart`

Replaces `MockOfferService`:

```dart
import '../models/offer.dart';
import 'api_client.dart';

class ApiOfferService {
  final ApiClient _client;

  ApiOfferService(this._client);

  Future<List<Offer>> fetchOffers({String? query, int page = 1}) async {
    final params = <String, dynamic>{
      'page': page,
      'per_page': 20,
    };
    if (query != null && query.isNotEmpty) params['q'] = query;

    final response = await _client.get('/offers', queryParameters: params);
    final data = response['data'] as List;
    return data.map((json) => Offer.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Offer> getOffer(String id) async {
    final response = await _client.get('/offers/$id');
    return Offer.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Offer> createOffer(Map<String, dynamic> data) async {
    final response = await _client.post('/offers', data);
    return Offer.fromJson(response['data'] as Map<String, dynamic>);
  }
}
```

### 5. `lib/services/api_favorites_service.dart`

Replaces `FavoritesService`:

```dart
import '../models/offer.dart';
import 'api_client.dart';

class ApiFavoritesService {
  final ApiClient _client;

  ApiFavoritesService(this._client);

  Future<List<Offer>> fetchFavorites({int page = 1}) async {
    final response = await _client.get('/favorites', queryParameters: {
      'page': page,
      'per_page': 20,
    });
    final data = response['data'] as List;
    return data.map((json) => Offer.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<void> addFavorite(String offerId) async {
    await _client.post('/favorites', {'offer_id': offerId});
  }

  Future<void> removeFavorite(String offerId) async {
    await _client.delete('/favorites/$offerId');
  }
}
```

## Updated Models

### `lib/models/offer.dart`

Add new fields and `fromJson` factory:

```dart
@immutable
class Offer {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String restaurantSlug;
  final String title;
  final String? titleSi;
  final String? titleTa;
  final String description;
  final String? descriptionSi;
  final String? descriptionTa;
  final double originalPrice;
  final double offerPrice;
  final List<String> imageUrls;
  final String location;
  final DateTime endDate;
  final bool isFavorite;
  final double? distanceKm;

  double get saving => originalPrice - offerPrice;
  double get discountPercent => originalPrice > 0
      ? ((saving / originalPrice) * 100).clamp(0, 100)
      : 0;
  String get primaryImage => imageUrls.isNotEmpty ? imageUrls.first : '';

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] as String,
      restaurantId: json['restaurant']['id'] as String,
      restaurantName: json['restaurant']['name'] as String,
      restaurantSlug: json['restaurant']['slug'] as String,
      title: json['title'] as String,
      titleSi: json['title_si'] as String?,
      titleTa: json['title_ta'] as String?,
      description: json['description'] as String? ?? '',
      descriptionSi: json['description_si'] as String?,
      descriptionTa: json['description_ta'] as String?,
      originalPrice: (json['original_price'] as num).toDouble(),
      offerPrice: (json['offer_price'] as num).toDouble(),
      imageUrls: (json['image_urls'] as List).cast<String>(),
      location: json['restaurant']['address'] as String? ?? '',
      endDate: DateTime.parse(json['end_date'] as String),
      isFavorite: json['is_favorited'] as bool? ?? false,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }

  Offer copyWith({
    String? id,
    String? restaurantId,
    String? restaurantName,
    String? restaurantSlug,
    String? title,
    String? titleSi,
    String? titleTa,
    String? description,
    String? descriptionSi,
    String? descriptionTa,
    double? originalPrice,
    double? offerPrice,
    List<String>? imageUrls,
    String? location,
    DateTime? endDate,
    bool? isFavorite,
    double? distanceKm,
  }) {
    return Offer(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantSlug: restaurantSlug ?? this.restaurantSlug,
      title: title ?? this.title,
      titleSi: titleSi ?? this.titleSi,
      titleTa: titleTa ?? this.titleTa,
      description: description ?? this.description,
      descriptionSi: descriptionSi ?? this.descriptionSi,
      descriptionTa: descriptionTa ?? this.descriptionTa,
      originalPrice: originalPrice ?? this.originalPrice,
      offerPrice: offerPrice ?? this.offerPrice,
      imageUrls: imageUrls ?? this.imageUrls,
      location: location ?? this.location,
      endDate: endDate ?? this.endDate,
      isFavorite: isFavorite ?? this.isFavorite,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}
```

### `lib/models/app_user.dart`

Add `fromJson` factory:

```dart
factory AppUser.fromJson(Map<String, dynamic> json) {
  return AppUser(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    isLoggedIn: true,
    isGuest: false,
  );
}
```

## Firebase Setup

### iOS (`ios/Runner/Info.plist`)
- Add `GoogleService-Info.plist` from Firebase Console
- Configure `CFBundleURLTypes` for Google Sign-In

### Android (`android/app/google-services.json`)
- Add `google-services.json` from Firebase Console
- Apply `google-services` plugin in `android/app/build.gradle`

### Flutter init (in `main.dart`)
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const NomNomBootstrap());
}
```

## Login Flow Update (`lib/screens/login_screen.dart`)

```dart
Future<void> _signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final idToken = await userCredential.user?.getIdToken();

    if (idToken != null) {
      await context.read<AuthProvider>().signInWithFirebase(idToken);
    }
  } catch (e) {
    // Handle error
  }
}
```

## Migration Checklist

- [ ] Add `dio`, `flutter_secure_storage`, `firebase_core`, `firebase_auth` to pubspec
- [ ] Create `ApiClient` with auth interceptor
- [ ] Create `ApiAuthService` (Firebase + JWT)
- [ ] Create `ApiOfferService`
- [ ] Create `ApiFavoritesService`
- [ ] Update `Offer` model (new fields, fromJson)
- [ ] Update `AppUser` model (fromJson)
- [ ] Update `AuthProvider` to call `ApiAuthService`
- [ ] Update `OfferProvider` to call `ApiOfferService` + `ApiFavoritesService`
- [ ] Add Firebase config files for iOS + Android
- [ ] Initialize Firebase in `main.dart`
- [ ] Update `LoginScreen` to use Firebase Auth SDK
- [ ] Add locale selector (Language dropdown in Profile)
- [ ] Test full auth flow
- [ ] Test offer browsing
- [ ] Test favorites sync
- [ ] Test search
- [ ] Remove mock data files once verified
