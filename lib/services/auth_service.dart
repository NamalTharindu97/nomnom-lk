import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

class AuthService {
  static const _isLoggedInKey = 'auth_is_logged_in';
  static const _isGuestKey = 'auth_is_guest';
  static const _userIdKey = 'auth_user_id';
  static const _nameKey = 'auth_user_name';
  static const _emailKey = 'auth_user_email';

  Future<AppUser?> restoreUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    final isGuest = prefs.getBool(_isGuestKey) ?? false;

    if (isGuest) {
      return AppUser.guest();
    }

    if (!isLoggedIn) {
      return null;
    }

    return AppUser(
      id: prefs.getString(_userIdKey) ?? 'mock-google-user',
      name: prefs.getString(_nameKey) ?? 'NomNom Foodie',
      email: prefs.getString(_emailKey) ?? 'foodie@nomnom.lk',
      isLoggedIn: true,
    );
  }

  Future<AppUser> signInWithGoogle() async {
    final user = const AppUser(
      id: 'mock-google-user',
      name: 'Nimali Perera',
      email: 'nimali@nomnom.lk',
      isLoggedIn: true,
    );

    await _saveUser(user);
    return user;
  }

  Future<AppUser> continueAsGuest() async {
    final user = AppUser.guest();
    await _saveUser(user);
    return user;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_isGuestKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
  }

  Future<void> _saveUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, user.isLoggedIn);
    await prefs.setBool(_isGuestKey, user.isGuest);
    await prefs.setString(_userIdKey, user.id);
    await prefs.setString(_nameKey, user.name);
    await prefs.setString(_emailKey, user.email);
  }
}
