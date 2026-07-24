import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart' as gsi;

import '../models/app_user.dart';
import '../services/api_auth_service.dart';
import '../services/api_client.dart';
import '../services/fcm_messaging_service.dart';
import '../services/local/favorite_store.dart';
import '../services/local/notification_store.dart';
import '../services/local/offer_store.dart';
import '../services/local/restaurant_store.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(
    this._authService, {
    ApiClient? apiClient,
    FavoriteStore? favoriteStore,
    NotificationStore? notificationStore,
    OfferStore? offerStore,
    RestaurantStore? restaurantStore,
  })  : _apiClient = apiClient,
        _favoriteStore = favoriteStore,
        _notificationStore = notificationStore,
        _offerStore = offerStore,
        _restaurantStore = restaurantStore;

  final ApiAuthService _authService;
  final ApiClient? _apiClient;
  final FavoriteStore? _favoriteStore;
  final NotificationStore? _notificationStore;
  final OfferStore? _offerStore;
  final RestaurantStore? _restaurantStore;

  AppUser? _user;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isSigningOut = false;

  AppUser? get user => _user;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user?.isLoggedIn ?? false;
  bool get isGuest => _user?.isGuest ?? false;
  bool get canEnterApp => isLoggedIn || isGuest;

  Future<void> restoreSession() async {
    _setLoading(true);
    _user = await _authService.restoreUser();
    _isInitialized = true;
    _setLoading(false);
    if (_user?.isLoggedIn == true) {
      await fcmService?.registerCurrentToken();
    }
  }

  Future<void> signInWithFirebase(String firebaseToken) async {
    _setLoading(true);
    try {
      _user = await _authService.signInWithFirebase(firebaseToken);
      _isInitialized = true;
      fcmService?.registerCurrentToken();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      _user = await _authService.login(email, password);
      _isInitialized = true;
      _setLoading(false);
      fcmService?.registerCurrentToken();
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> register(String email, String password, String name) async {
    _setLoading(true);
    try {
      await _authService.register(email, password, name);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> sendVerificationCode(String email) async {
    await _authService.sendVerificationCode(email);
  }

  Future<void> verifyEmail(String email, String code) async {
    _setLoading(true);
    try {
      _user = await _authService.verifyEmail(email, code);
      _isInitialized = true;
      _setLoading(false);
      await fcmService?.registerCurrentToken();
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> continueAsGuest() async {
    _setLoading(true);
    _user = AppUser.guest();
    _isInitialized = true;
    _setLoading(false);
  }

  Future<void> signOut() async {
    if (_isSigningOut) return;
    _isSigningOut = true;
    _setLoading(true);

    await fcmService?.unregisterToken();

    await _authService.logout();

    try { await fb.FirebaseAuth.instance.signOut(); } catch (_) {}
    try { gsi.GoogleSignIn().signOut(); } catch (_) {}

    _apiClient?.clearCache();
    _apiClient?.clearTokens();

    await _favoriteStore?.clear();
    await _notificationStore?.clear();
    await _offerStore?.clear();
    await _restaurantStore?.clear();

    _user = null;
    _isInitialized = true;
    _isSigningOut = false;
    _setLoading(false);
  }

  void updateUser(AppUser updated) {
    _user = updated;
    notifyListeners();
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }
    _isLoading = value;
    notifyListeners();
  }
}
