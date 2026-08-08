import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom_lk/services/cache_interceptor.dart';

RequestOptions _getOptions({String path = '/api/offers', String? lang}) {
  return RequestOptions(
    path: path,
    method: 'GET',
    headers: lang != null ? {'Accept-Language': lang} : {},
  );
}

RequestOptions _postOptions({String path = '/api/offers'}) {
  return RequestOptions(path: path, method: 'POST');
}

Response _buildResponse(RequestOptions options, Map<String, dynamic> data) {
  return Response(requestOptions: options, data: data, statusCode: 200);
}

DioException _buildError(RequestOptions options) {
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: 500),
  );
}

class _RequestHandler extends RequestInterceptorHandler {
  bool nextCalled = false;
  bool resolved = false;
  Response? resolvedResponse;

  @override
  void next(RequestOptions options) => nextCalled = true;

  @override
  void resolve(Response response, [bool callFollowing = false]) {
    resolved = true;
    resolvedResponse = response;
  }

  @override
  void reject(DioException error, [bool callFollowing = false]) {}
}

class _ResponseHandler extends ResponseInterceptorHandler {
  bool nextCalled = false;

  @override
  void next(Response response) => nextCalled = true;

  @override
  void resolve(Response response) {}

  @override
  void reject(DioException error, [bool callFollowing = false]) {}
}

class _ErrorHandler extends ErrorInterceptorHandler {
  bool resolved = false;
  Response? resolvedResponse;

  @override
  void next(DioException error) {}

  @override
  void resolve(Response response) {
    resolved = true;
    resolvedResponse = response;
  }

  @override
  void reject(DioException error) {}
}

void main() {
  late CacheInterceptor interceptor;

  setUp(() {
    interceptor = CacheInterceptor(ttl: const Duration(seconds: 10));
  });

  group('onRequest', () {
    test('GET cache miss calls handler.next', () {
      final handler = _RequestHandler();
      interceptor.onRequest(_getOptions(), handler);

      expect(handler.nextCalled, isTrue);
      expect(handler.resolved, isFalse);
    });

    for (final path in [
      '/favorites',
      '/notifications',
      '/notifications/unread-count',
      '/users/me',
    ]) {
      test('private $path responses are never cached', () {
        final options = _getOptions(path: path);
        interceptor.onResponse(
          _buildResponse(options, {'private': true}),
          _ResponseHandler(),
        );

        final handler = _RequestHandler();
        interceptor.onRequest(options, handler);

        expect(interceptor.cachedEntryCount, 0);
        expect(handler.nextCalled, isTrue);
        expect(handler.resolved, isFalse);
      });
    }

    test('GET cache hit resolves with cached data', () {
      final reqOpts = _getOptions();
      final data = {'id': 1, 'name': 'Burger Deal'};

      interceptor.onResponse(_buildResponse(reqOpts, data), _ResponseHandler());

      final handler = _RequestHandler();
      interceptor.onRequest(reqOpts, handler);

      expect(handler.resolved, isTrue);
      expect(handler.resolvedResponse, isNotNull);
      expect(handler.resolvedResponse!.data, equals(data));
      expect(handler.resolvedResponse!.statusCode, 200);
      expect(handler.nextCalled, isFalse);
    });

    test('POST request always passes through', () {
      final handler = _RequestHandler();
      final postOpts = _postOptions();

      final getOpts = _getOptions();
      interceptor.onResponse(
          _buildResponse(getOpts, {'cached': true}), _ResponseHandler());

      interceptor.onRequest(postOpts, handler);

      expect(handler.nextCalled, isTrue);
      expect(handler.resolved, isFalse);
    });

    test('PUT/PATCH/DELETE requests pass through', () {
      for (final method in ['PUT', 'PATCH', 'DELETE']) {
        final handler = _RequestHandler();
        interceptor.onRequest(
          RequestOptions(path: '/api/x', method: method),
          handler,
        );
        expect(handler.nextCalled, isTrue, reason: '$method passes through');
      }
    });

    test('expired cache entry causes cache miss', () async {
      final shortTtl = CacheInterceptor(ttl: const Duration(milliseconds: 1));
      final opts = _getOptions();

      shortTtl.onResponse(
          _buildResponse(opts, {'old': true}), _ResponseHandler());

      await Future.delayed(const Duration(milliseconds: 10));

      final handler = _RequestHandler();
      shortTtl.onRequest(opts, handler);

      expect(handler.nextCalled, isTrue);
      expect(handler.resolved, isFalse);
    });

    test('cache hit refreshes entry position (LRU)', () {
      final opts1 = _getOptions(path: '/api/a');
      final opts2 = _getOptions(path: '/api/b');

      interceptor.onResponse(
          _buildResponse(opts1, {'a': 1}), _ResponseHandler());
      interceptor.onResponse(
          _buildResponse(opts2, {'b': 2}), _ResponseHandler());

      // Access opts1 (moves to end)
      interceptor.onRequest(opts1, _RequestHandler());

      expect(interceptor.cachedEntryCount, 2);
    });
  });

  group('onResponse', () {
    test('caches GET responses', () {
      final opts = _getOptions();
      final data = {'id': 5, 'title': 'Pizza Deal'};

      interceptor.onResponse(_buildResponse(opts, data), _ResponseHandler());

      expect(interceptor.cachedEntryCount, 1);

      final handler = _RequestHandler();
      interceptor.onRequest(opts, handler);
      expect(handler.resolved, isTrue);
      expect(handler.resolvedResponse!.data, equals(data));
    });

    test('ignores non-GET responses', () {
      interceptor.onResponse(
        _buildResponse(_postOptions(), {'created': true}),
        _ResponseHandler(),
      );

      expect(interceptor.cachedEntryCount, 0);
    });

    test('ignores responses with null data', () {
      final opts = _getOptions();
      interceptor.onResponse(
        Response(requestOptions: opts, data: null, statusCode: 200),
        _ResponseHandler(),
      );

      expect(interceptor.cachedEntryCount, 0);
    });

    test('passes response through via handler.next', () {
      final handler = _ResponseHandler();
      interceptor.onResponse(
        _buildResponse(_getOptions(), {'key': 'value'}),
        handler,
      );

      expect(handler.nextCalled, isTrue);
    });

    test('same-key GET response overwrites previous', () {
      final opts = _getOptions(path: '/api/dup');

      interceptor.onResponse(
          _buildResponse(opts, {'v': 1}), _ResponseHandler());
      interceptor.onResponse(
          _buildResponse(opts, {'v': 2}), _ResponseHandler());

      expect(interceptor.cachedEntryCount, 1);

      final handler = _RequestHandler();
      interceptor.onRequest(opts, handler);
      expect(handler.resolvedResponse!.data, {'v': 2});
    });
  });

  group('onError', () {
    test('falls back to cached data for GET requests', () {
      final opts = _getOptions();
      final cachedData = {'id': 99, 'fallback': true};

      interceptor.onResponse(
          _buildResponse(opts, cachedData), _ResponseHandler());

      final handler = _ErrorHandler();
      interceptor.onError(_buildError(opts), handler);

      expect(handler.resolved, isTrue);
      expect(handler.resolvedResponse!.data, equals(cachedData));
      expect(handler.resolvedResponse!.statusCode, 200);
    });

    test('propagates error for GET requests with no cache', () {
      final handler = _ErrorHandler();
      interceptor.onError(_buildError(_getOptions()), handler);

      expect(handler.resolved, isFalse);
    });

    test('propagates error for non-GET requests', () {
      final postOpts = _postOptions();
      final getOpts = _getOptions();
      interceptor.onResponse(
          _buildResponse(getOpts, {'data': 'exists'}), _ResponseHandler());

      final handler = _ErrorHandler();
      interceptor.onError(_buildError(postOpts), handler);

      expect(handler.resolved, isFalse);
    });

    test('GET error refreshes cached entry position (LRU)', () {
      final opts1 = _getOptions(path: '/api/a');
      final opts2 = _getOptions(path: '/api/b');

      interceptor.onResponse(
          _buildResponse(opts1, {'a': 1}), _ResponseHandler());
      interceptor.onResponse(
          _buildResponse(opts2, {'b': 2}), _ResponseHandler());

      // Error fallback on opts1 moves it to end
      interceptor.onError(_buildError(opts1), _ErrorHandler());

      expect(interceptor.cachedEntryCount, 2);
    });

    test(
        'GET error resolves stale data even when entry is expired (resilience fallback)',
        () async {
      final shortTtl = CacheInterceptor(ttl: const Duration(milliseconds: 1));
      final opts = _getOptions();

      shortTtl.onResponse(
          _buildResponse(opts, {'stale': true}), _ResponseHandler());

      await Future.delayed(const Duration(milliseconds: 10));

      final handler = _ErrorHandler();
      shortTtl.onError(_buildError(opts), handler);

      // onError intentionally ignores TTL — prefers stale data over error
      expect(handler.resolved, isTrue);
      expect(handler.resolvedResponse!.data, {'stale': true});
    });
  });

  group('TTL expiry', () {
    test('expired entry causes cache miss on GET', () async {
      final shortTtl = CacheInterceptor(ttl: const Duration(milliseconds: 5));
      final opts = _getOptions();

      shortTtl.onResponse(
          _buildResponse(opts, {'stale': true}), _ResponseHandler());
      expect(shortTtl.cachedEntryCount, 1);

      await Future.delayed(const Duration(milliseconds: 20));

      final handler = _RequestHandler();
      shortTtl.onRequest(opts, handler);

      expect(handler.nextCalled, isTrue);
      expect(handler.resolved, isFalse);
    });

    test('valid entry within TTL resolves from cache', () {
      final opts = _getOptions();
      interceptor.onResponse(
          _buildResponse(opts, {'fresh': true}), _ResponseHandler());

      final handler = _RequestHandler();
      interceptor.onRequest(opts, handler);

      expect(handler.resolved, isTrue);
      expect(handler.resolvedResponse!.data, {'fresh': true});
    });

    test('new entry has TTL measured from cache time', () async {
      final shortTtl = CacheInterceptor(ttl: const Duration(milliseconds: 50));
      final opts = _getOptions();

      shortTtl.onResponse(
          _buildResponse(opts, {'data': 1}), _ResponseHandler());

      // 20ms in — still valid
      await Future.delayed(const Duration(milliseconds: 20));
      final h1 = _RequestHandler();
      shortTtl.onRequest(opts, h1);
      expect(h1.resolved, isTrue);

      // 60ms in — expired
      await Future.delayed(const Duration(milliseconds: 50));
      final h2 = _RequestHandler();
      shortTtl.onRequest(opts, h2);
      expect(h2.nextCalled, isTrue);
      expect(h2.resolved, isFalse);
    });
  });

  group('invalidate', () {
    test('removes entries matching path prefix', () {
      final opts1 = _getOptions(path: '/api/offers');
      final opts2 = _getOptions(path: '/api/offers/123');
      final opts3 = _getOptions(path: '/api/restaurants');

      interceptor.onResponse(
          _buildResponse(opts1, {'list': true}), _ResponseHandler());
      interceptor.onResponse(
          _buildResponse(opts2, {'detail': true}), _ResponseHandler());
      interceptor.onResponse(
          _buildResponse(opts3, {'restaurants': true}), _ResponseHandler());
      expect(interceptor.cachedEntryCount, 3);

      interceptor.invalidate('/api/offers');

      expect(interceptor.cachedEntryCount, 1);

      final handler = _RequestHandler();
      interceptor.onRequest(opts3, handler);
      expect(handler.resolved, isTrue);
    });

    test('non-matching path leaves cache untouched', () {
      final opts = _getOptions(path: '/api/offers');
      interceptor.onResponse(
          _buildResponse(opts, {'data': 1}), _ResponseHandler());

      interceptor.invalidate('/api/users');

      expect(interceptor.cachedEntryCount, 1);
    });

    test('removes multiple matching entries', () {
      for (var i = 0; i < 5; i++) {
        interceptor.onResponse(
          _buildResponse(_getOptions(path: '/api/offers/$i'), {'id': i}),
          _ResponseHandler(),
        );
      }
      expect(interceptor.cachedEntryCount, 5);

      interceptor.invalidate('/api/offers');

      expect(interceptor.cachedEntryCount, 0);
    });

    test('empty cache does not throw', () {
      expect(() => interceptor.invalidate('/api/anything'), returnsNormally);
    });

    test('partial path match works', () {
      interceptor.onResponse(
        _buildResponse(_getOptions(path: '/api/offer-specials'), {'s': 1}),
        _ResponseHandler(),
      );
      interceptor.onResponse(
        _buildResponse(_getOptions(path: '/api/restaurant-menu'), {'m': 1}),
        _ResponseHandler(),
      );

      interceptor.invalidate('/api/offer');

      // '/api/offer-specials' contains '/api/offer'
      expect(interceptor.cachedEntryCount, 1);
    });
  });

  group('clear', () {
    test('removes all entries', () {
      for (var i = 0; i < 5; i++) {
        interceptor.onResponse(
          _buildResponse(_getOptions(path: '/api/path$i'), {'n': i}),
          _ResponseHandler(),
        );
      }
      expect(interceptor.cachedEntryCount, 5);

      interceptor.clear();

      expect(interceptor.cachedEntryCount, 0);
    });

    test('empty cache does not throw', () {
      expect(() => interceptor.clear(), returnsNormally);
    });

    test('cache is fully invalidated after clear', () {
      final opts = _getOptions();
      interceptor.onResponse(
          _buildResponse(opts, {'data': 1}), _ResponseHandler());
      interceptor.clear();

      final handler = _RequestHandler();
      interceptor.onRequest(opts, handler);
      expect(handler.nextCalled, isTrue);
      expect(handler.resolved, isFalse);
    });
  });

  group('maxEntries', () {
    test('evicts oldest entry when limit is reached', () {
      final small =
          CacheInterceptor(ttl: const Duration(minutes: 5), maxEntries: 3);

      final o1 = _getOptions(path: '/api/1');
      final o2 = _getOptions(path: '/api/2');
      final o3 = _getOptions(path: '/api/3');
      final o4 = _getOptions(path: '/api/4');

      small.onResponse(_buildResponse(o1, {'a': 1}), _ResponseHandler());
      small.onResponse(_buildResponse(o2, {'a': 2}), _ResponseHandler());
      small.onResponse(_buildResponse(o3, {'a': 3}), _ResponseHandler());
      expect(small.cachedEntryCount, 3);

      small.onResponse(_buildResponse(o4, {'a': 4}), _ResponseHandler());
      expect(small.cachedEntryCount, 3);

      // o1 evicted
      final h1 = _RequestHandler();
      small.onRequest(o1, h1);
      expect(h1.nextCalled, isTrue);
      expect(h1.resolved, isFalse);

      // o4 present
      final h4 = _RequestHandler();
      small.onRequest(o4, h4);
      expect(h4.resolved, isTrue);
    });

    test('cache hit refreshes entry preventing eviction', () {
      final small =
          CacheInterceptor(ttl: const Duration(minutes: 5), maxEntries: 3);

      final o1 = _getOptions(path: '/api/1');
      final o2 = _getOptions(path: '/api/2');
      final o3 = _getOptions(path: '/api/3');
      final o4 = _getOptions(path: '/api/4');

      small.onResponse(_buildResponse(o1, {'a': 1}), _ResponseHandler());
      small.onResponse(_buildResponse(o2, {'a': 2}), _ResponseHandler());
      small.onResponse(_buildResponse(o3, {'a': 3}), _ResponseHandler());

      // Access o1 — moves to end
      small.onRequest(o1, _RequestHandler());

      // Add o4 — evicts o2 (now oldest)
      small.onResponse(_buildResponse(o4, {'a': 4}), _ResponseHandler());

      final h1 = _RequestHandler();
      small.onRequest(o1, h1);
      expect(h1.resolved, isTrue);

      final h2 = _RequestHandler();
      small.onRequest(o2, h2);
      expect(h2.nextCalled, isTrue);
    });

    test('maxEntries=1 allows only one entry', () {
      final one =
          CacheInterceptor(ttl: const Duration(minutes: 5), maxEntries: 1);

      final o1 = _getOptions(path: '/api/first');
      final o2 = _getOptions(path: '/api/second');

      one.onResponse(_buildResponse(o1, {'first': true}), _ResponseHandler());
      expect(one.cachedEntryCount, 1);

      one.onResponse(_buildResponse(o2, {'second': true}), _ResponseHandler());
      expect(one.cachedEntryCount, 1);

      final h1 = _RequestHandler();
      one.onRequest(o1, h1);
      expect(h1.resolved, isFalse);

      final h2 = _RequestHandler();
      one.onRequest(o2, h2);
      expect(h2.resolved, isTrue);
    });

    test('onRequest LRU move also respects maxEntries', () {
      final small =
          CacheInterceptor(ttl: const Duration(minutes: 5), maxEntries: 2);

      final o1 = _getOptions(path: '/api/1');
      final o2 = _getOptions(path: '/api/2');
      final o3 = _getOptions(path: '/api/3');

      small.onResponse(_buildResponse(o1, {'a': 1}), _ResponseHandler());
      small.onResponse(_buildResponse(o2, {'a': 2}), _ResponseHandler());

      // Access o1 via onRequest (moves to end via LRU refresh)
      small.onRequest(o1, _RequestHandler());

      // Add o3 — should evict o2 (now oldest)
      small.onResponse(_buildResponse(o3, {'a': 3}), _ResponseHandler());

      final h1 = _RequestHandler();
      small.onRequest(o1, h1);
      expect(h1.resolved, isTrue);

      final h2 = _RequestHandler();
      small.onRequest(o2, h2);
      expect(h2.nextCalled, isTrue);
    });

    test('onError LRU move also respects maxEntries', () {
      final small =
          CacheInterceptor(ttl: const Duration(minutes: 5), maxEntries: 2);

      final o1 = _getOptions(path: '/api/1');
      final o2 = _getOptions(path: '/api/2');
      final o3 = _getOptions(path: '/api/3');

      small.onResponse(_buildResponse(o1, {'a': 1}), _ResponseHandler());
      small.onResponse(_buildResponse(o2, {'a': 2}), _ResponseHandler());

      // Access o1 via onError (moves to end via LRU refresh)
      small.onError(_buildError(o1), _ErrorHandler());

      // Add o3 — should evict o2
      small.onResponse(_buildResponse(o3, {'a': 3}), _ResponseHandler());

      final h1 = _RequestHandler();
      small.onRequest(o1, h1);
      expect(h1.resolved, isTrue);

      final h2 = _RequestHandler();
      small.onRequest(o2, h2);
      expect(h2.nextCalled, isTrue);
    });
  });

  group('cachedEntryCount', () {
    test('starts at zero', () {
      expect(interceptor.cachedEntryCount, 0);
    });

    test('increments on GET response caching', () {
      interceptor.onResponse(
        _buildResponse(_getOptions(path: '/api/1'), {'a': 1}),
        _ResponseHandler(),
      );
      expect(interceptor.cachedEntryCount, 1);

      interceptor.onResponse(
        _buildResponse(_getOptions(path: '/api/2'), {'b': 2}),
        _ResponseHandler(),
      );
      expect(interceptor.cachedEntryCount, 2);
    });

    test('does not increment on non-GET response', () {
      interceptor.onResponse(
        _buildResponse(_postOptions(), {'created': true}),
        _ResponseHandler(),
      );
      expect(interceptor.cachedEntryCount, 0);
    });

    test('same key overwrites without increasing count', () {
      final opts = _getOptions(path: '/api/same');

      interceptor.onResponse(
          _buildResponse(opts, {'v': 1}), _ResponseHandler());
      expect(interceptor.cachedEntryCount, 1);

      interceptor.onResponse(
          _buildResponse(opts, {'v': 2}), _ResponseHandler());
      expect(interceptor.cachedEntryCount, 1);
    });

    test('decreases after invalidate', () {
      for (var i = 0; i < 3; i++) {
        interceptor.onResponse(
          _buildResponse(_getOptions(path: '/api/x$i'), {'i': i}),
          _ResponseHandler(),
        );
      }
      expect(interceptor.cachedEntryCount, 3);

      interceptor.invalidate('/api/x0');

      expect(interceptor.cachedEntryCount, 2);
    });
  });

  group('cache key', () {
    test('includes Accept-Language header', () {
      final optsEn = _getOptions(lang: 'en');
      final optsSi = _getOptions(lang: 'si');

      interceptor.onResponse(
          _buildResponse(optsEn, {'lang': 'en'}), _ResponseHandler());
      interceptor.onResponse(
          _buildResponse(optsSi, {'lang': 'si'}), _ResponseHandler());

      expect(interceptor.cachedEntryCount, 2);

      final hEn = _RequestHandler();
      interceptor.onRequest(optsEn, hEn);
      expect(hEn.resolvedResponse!.data, {'lang': 'en'});

      final hSi = _RequestHandler();
      interceptor.onRequest(optsSi, hSi);
      expect(hSi.resolvedResponse!.data, {'lang': 'si'});
    });

    test('defaults to en when Accept-Language header is missing', () {
      final opts = _getOptions(); // no lang
      interceptor.onResponse(
          _buildResponse(opts, {'data': 1}), _ResponseHandler());

      final handler = _RequestHandler();
      interceptor.onRequest(_getOptions(), handler);
      expect(handler.resolved, isTrue);
    });

    test('different paths produce different cache keys', () {
      final opts1 = _getOptions(path: '/api/a');
      final opts2 = _getOptions(path: '/api/b');

      interceptor.onResponse(
          _buildResponse(opts1, {'a': 1}), _ResponseHandler());
      interceptor.onResponse(
          _buildResponse(opts2, {'b': 2}), _ResponseHandler());

      expect(interceptor.cachedEntryCount, 2);

      final h1 = _RequestHandler();
      interceptor.onRequest(opts1, h1);
      expect(h1.resolvedResponse!.data, {'a': 1});

      final h2 = _RequestHandler();
      interceptor.onRequest(opts2, h2);
      expect(h2.resolvedResponse!.data, {'b': 2});
    });

    test('same path with different lang are separate entries', () {
      final optsEn = _getOptions(path: '/api/data', lang: 'en');
      final optsTa = _getOptions(path: '/api/data', lang: 'ta');

      interceptor.onResponse(
          _buildResponse(optsEn, {'en': true}), _ResponseHandler());
      interceptor.onResponse(
          _buildResponse(optsTa, {'ta': true}), _ResponseHandler());

      expect(interceptor.cachedEntryCount, 2);
    });
  });
}
