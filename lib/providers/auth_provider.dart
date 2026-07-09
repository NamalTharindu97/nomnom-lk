import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/api_auth_service.dart';
import '../services/fcm_messaging_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService);

  final ApiAuthService _authService;

  AppUser? _user;
  bool _isInitialized = false;
  bool _isLoading = false;

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
    _user = await _authService.signInWithFirebase(firebaseToken);
    _isInitialized = true;
    _setLoading(false);
    fcmService?.registerCurrentToken();
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
    _setLoading(true);
    await fcmService?.unregisterToken();
    await _authService.logout();
    _user = null;
    _isInitialized = true;
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
