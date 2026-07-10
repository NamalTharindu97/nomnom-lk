import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../core/api_config.dart';
import 'auth_interceptor.dart';
import 'cache_interceptor.dart';

class ApiClient {
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  late final CacheInterceptor _cacheInterceptor;

  ApiClient() {
    final locale = Intl.defaultLocale?.split('_').first ?? 'en';
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {'Accept-Language': locale},
    ));

    _cacheInterceptor = CacheInterceptor(ttl: const Duration(minutes: 2));
    _dio.interceptors.addAll([
      AuthInterceptor(_storage, _dio),
      _cacheInterceptor,
    ]);
  }

  void invalidateCache(String path) => _cacheInterceptor.invalidate(path);
  void clearCache() => _cacheInterceptor.clear();

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get(path, queryParameters: queryParameters);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> post(String path, dynamic data) async {
    final response = await _dio.post(path, data: data);
    if (response.data == null || response.data is! Map) return <String, dynamic>{};
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> put(String path, dynamic data) async {
    final response = await _dio.put(path, data: data);
    if (response.data == null || response.data is! Map) return <String, dynamic>{};
    return response.data as Map<String, dynamic>;
  }

  Future<void> delete(String path, {dynamic data}) async {
    await _dio.delete(path, data: data);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String fileField,
    required String filePath,
    Map<String, String>? queryParams,
  }) async {
    final formData = FormData.fromMap({
      fileField: await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post(path, data: formData, queryParameters: queryParams);
    if (response.data == null || response.data is! Map) return <String, dynamic>{};
    return response.data as Map<String, dynamic>;
  }

  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }
}
