import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, this._dio);

  static const _retriedKey = 'auth_retried';

  final FlutterSecureStorage _storage;
  final Dio _dio;
  Future<String>? _refreshFuture;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept-Language'] =
        Intl.defaultLocale?.split('_').first ?? 'en';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        request.path.endsWith('/auth/refresh') ||
        request.extra[_retriedKey] == true) {
      handler.next(err);
      return;
    }

    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) {
      handler.next(err);
      return;
    }

    final refreshFuture = _refreshFuture ??= _refresh(refreshToken);
    try {
      final accessToken = await refreshFuture;
      request.extra[_retriedKey] = true;
      request.headers['Authorization'] = 'Bearer $accessToken';
      handler.resolve(await _dio.fetch(request));
      return;
    } on DioException catch (refreshError) {
      if (refreshError.response?.statusCode == 401) {
        await _storage.delete(key: 'access_token');
        await _storage.delete(key: 'refresh_token');
      }
    } catch (_) {
      // Keep the session for transient network and response parsing failures.
    } finally {
      if (identical(_refreshFuture, refreshFuture)) {
        _refreshFuture = null;
      }
    }

    handler.next(err);
  }

  Future<String> _refresh(String refreshToken) async {
    final refreshDio = Dio(BaseOptions(
      baseUrl: _dio.options.baseUrl,
      connectTimeout: _dio.options.connectTimeout,
      receiveTimeout: _dio.options.receiveTimeout,
      headers: {
        'Accept-Language': Intl.defaultLocale?.split('_').first ?? 'en',
      },
    ));
    final response = await refreshDio.post('/auth/refresh', data: {
      'refresh_token': refreshToken,
    });
    final data = response.data as Map<String, dynamic>;
    final accessToken = data['access_token'] as String;
    final nextRefreshToken = data['refresh_token'] as String;
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: nextRefreshToken);
    return accessToken;
  }
}
