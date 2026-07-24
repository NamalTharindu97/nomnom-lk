import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/app_user.dart';
import 'api_client.dart';

class ApiAuthService {
  ApiAuthService(this._client);

  final ApiClient _client;
  bool _firebaseAvailable = true;

  bool get firebaseAvailable => _firebaseAvailable;

  String _friendlyErrorMessage(dynamic e) {
    // Handle Firebase Auth exceptions
    if (e is Exception && e.toString().contains('FirebaseAuthException')) {
      final msg = e.toString();
      if (msg.contains('user-not-found') || msg.contains('wrong-password')) {
        return 'Invalid email or password.';
      }
      if (msg.contains('user-disabled')) {
        return 'This account has been disabled.';
      }
      if (msg.contains('too-many-requests')) {
        return 'Too many attempts. Please try later.';
      }
      if (msg.contains('invalid-email')) {
        return 'Please enter a valid email.';
      }
      if (msg.contains('weak-password')) {
        return 'Password is too weak.';
      }
      if (msg.contains('email-already-in-use')) {
        return 'An account with this email already exists.';
      }
      if (msg.contains('operation-not-allowed') || msg.contains('NetworkError')) {
        _firebaseAvailable = false;
        return 'Firebase login unavailable.';
      }
      return 'Sign in failed. Please try again.';
    }
    return 'Sign in failed. Please try again.';
  }

  Future<AppUser> signInWithFirebase(String firebaseToken) async {
    if (!_firebaseAvailable) {
      throw Exception('Firebase login unavailable');
    }
    try {
      final response = await _client.post('/auth/firebase', {
        'firebase_token': firebaseToken,
      });
      return _handleAuthResponse(response);
    } catch (e) {
      _firebaseAvailable = false;
      throw Exception(_friendlyErrorMessage(e));
    }
  }

  Future<AppUser> login(String email, String password) async {
    try {
      final response = await _client.post('/auth/login', {
        'email': email,
        'password': password,
      });
      return _handleAuthResponse(response);
    } catch (e) {
      throw Exception(_friendlyErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String name) async {
    try {
      return await _client.post('/auth/register', {
        'email': email,
        'password': password,
        'name': name,
      });
    } catch (e) {
      throw Exception(_friendlyErrorMessage(e));
    }
  }

  Future<void> sendVerificationCode(String email) async {
    try {
      await _client.post('/auth/send-verification', {
        'email': email,
      });
    } catch (e) {
      throw Exception(_friendlyErrorMessage(e));
    }
  }

  Future<AppUser> verifyEmail(String email, String code) async {
    try {
      final response = await _client.post('/auth/verify-email', {
        'email': email,
        'code': code,
      });
      return _handleAuthResponse(response);
    } catch (e) {
      throw Exception(_friendlyErrorMessage(e));
    }
  }

  Future<void> logout() async {
    try {
      await _client.post('/auth/logout', {});
    } catch (_) {}
    await _client.clearTokens();
  }

  Future<Map<String, dynamic>> requestDeletion() async {
    return await _client.post('/users/me/delete-account', {});
  }

  Future<Map<String, dynamic>> cancelDeletion() async {
    return await _client.post('/users/me/cancel-deletion', {});
  }

  Future<AppUser?> restoreUser() async {
    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    if (token == null) return null;

    try {
      final response = await _client.get('/users/me');
      return AppUser.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      // Token refresh may have failed — auth interceptor handles token wipe
      return null;
    }
  }

  Future<AppUser> _handleAuthResponse(Map<String, dynamic> response) async {
    final storage = const FlutterSecureStorage();
    await storage.write(
      key: 'access_token',
      value: response['access_token'] as String,
    );
    await storage.write(
      key: 'refresh_token',
      value: response['refresh_token'] as String,
    );
    return AppUser.fromJson(response['user'] as Map<String, dynamic>);
  }
}
