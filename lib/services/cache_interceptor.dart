import 'package:dio/dio.dart';

class _CacheEntry {
  final Map<String, dynamic> data;
  final DateTime expiresAt;

  _CacheEntry(this.data, this.expiresAt);
}

class CacheInterceptor extends Interceptor {
  final Map<String, _CacheEntry> _cache = {};
  final Duration ttl;

  CacheInterceptor({this.ttl = const Duration(minutes: 2)});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method != 'GET') {
      return handler.next(options);
    }

    final key = _cacheKey(options);
    final entry = _cache[key];

    if (entry != null && DateTime.now().isBefore(entry.expiresAt)) {
      return handler.resolve(
        Response(
          requestOptions: options,
          data: entry.data,
          statusCode: 200,
        ),
      );
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.method == 'GET' && response.data != null) {
      final key = _cacheKey(response.requestOptions);
      _cache[key] = _CacheEntry(
        response.data as Map<String, dynamic>,
        DateTime.now().add(ttl),
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

  String _cacheKey(RequestOptions options) {
    final uri = options.uri.toString();
    return uri;
  }
}
