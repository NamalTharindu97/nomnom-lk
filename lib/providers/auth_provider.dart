import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService);

  final AuthService _authService;

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
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    _user = await _authService.signInWithGoogle();
    _isInitialized = true;
    _setLoading(false);
  }

  Future<void> continueAsGuest() async {
    _setLoading(true);
    _user = await _authService.continueAsGuest();
    _isInitialized = true;
    _setLoading(false);
  }

  Future<void> signOut() async {
    _setLoading(true);
    await _authService.signOut();
    _user = null;
    _isInitialized = true;
    _setLoading(false);
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }

    _isLoading = value;
    notifyListeners();
  }
}
