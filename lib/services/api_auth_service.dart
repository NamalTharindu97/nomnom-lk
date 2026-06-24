import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/app_user.dart';
import 'api_client.dart';

class ApiAuthService {
  ApiAuthService(this._client);

  final ApiClient _client;

  Future<AppUser> signInWithFirebase(String firebaseToken) async {
    final response = await _client.post('/auth/firebase', {
      'firebase_token': firebaseToken,
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

  Future<AppUser> register(String email, String password, String name) async {
    final response = await _client.post('/auth/register', {
      'email': email,
      'password': password,
      'name': name,
    });
    return _handleAuthResponse(response);
  }

  Future<void> logout() async {
    try {
      await _client.post('/auth/logout', {});
    } catch (_) {}
    await _client.clearTokens();
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
