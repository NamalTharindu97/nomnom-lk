import 'dart:collection';

import 'package:dio/dio.dart';

class _CacheEntry {
  final Map<String, dynamic> data;
  final DateTime expiresAt;

  _CacheEntry(this.data, this.expiresAt);
}

class CacheInterceptor extends Interceptor {
  final int maxEntries;
  final Duration ttl;
  final Map<String, _CacheEntry> _cache = LinkedHashMap();

  CacheInterceptor({this.ttl = const Duration(minutes: 5), this.maxEntries = 100});

  void _set(String key, _CacheEntry entry) {
    if (_cache.length >= maxEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = entry;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method != 'GET') {
      return handler.next(options);
    }

    final key = _cacheKey(options);
    final entry = _cache[key];

    if (entry != null && DateTime.now().isBefore(entry.expiresAt)) {
      _cache.remove(key);
      _cache[key] = entry;
      return handler.resolve(
        Response(
          requestOptions: options,
          data: entry.data,
          statusCode: 200,
        ),
      );
    }

    _cache.remove(key);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.method == 'GET' && response.data != null) {
      _set(
        _cacheKey(response.requestOptions),
        _CacheEntry(
          response.data as Map<String, dynamic>,
          DateTime.now().add(ttl),
        ),
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.requestOptions.method == 'GET') {
      final key = _cacheKey(err.requestOptions);
      final entry = _cache[key];
      if (entry != null) {
        _cache.remove(key);
        _cache[key] = entry;
        return handler.resolve(
          Response(
            requestOptions: err.requestOptions,
            data: entry.data,
            statusCode: 200,
          ),
        );
      }
    }
    handler.next(err);
  }

  void invalidate(String path) {
    final keysToRemove = _cache.keys.where((k) => k.contains(path)).toList();
    for (final k in keysToRemove) {
      _cache.remove(k);
    }
  }

  void clear() {
    _cache.clear();
  }

  int get cachedEntryCount => _cache.length;

  String _cacheKey(RequestOptions options) {
    final locale = options.headers['Accept-Language'] ?? 'en';
    return '${options.uri.toString()}|lang=$locale';
  }
}
