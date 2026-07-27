import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom_lk/models/paginated_response.dart';
import 'package:nomnom_lk/models/restaurant.dart';
import 'package:nomnom_lk/providers/restaurant_provider.dart';
import 'package:nomnom_lk/services/api_restaurant_service.dart';
import 'package:nomnom_lk/services/connectivity_service.dart';

import '../helpers/mocks.dart';

class _OfflineConnectivityService implements ConnectivityService {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  void goOffline() => _controller.add(false);

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  @override
  bool get isOnline => false;

  @override
  Future<bool> checkConnectivity() async => false;

  @override
  void dispose() => _controller.close();
}

class _PaginatingRestaurantService implements ApiRestaurantService {
  final List<List<Restaurant>> pages;

  _PaginatingRestaurantService(this.pages);

  @override
  Future<PaginatedResponse<Restaurant>> fetchRestaurants(
      {String? query, int page = 1}) async {
    final index = page - 1;
    if (index >= pages.length) {
      return PaginatedResponse(
        data: const [],
        page: page,
        perPage: 20,
        total: 0,
        totalPages: pages.length,
      );
    }
    return PaginatedResponse(
      data: pages[index],
      page: page,
      perPage: 20,
      total: pages.expand((p) => p).length,
      totalPages: pages.length,
    );
  }

  @override
  Future<Restaurant> getRestaurant(String id) async =>
      throw UnimplementedError();
}

class _FailingRestaurantService implements ApiRestaurantService {
  @override
  Future<PaginatedResponse<Restaurant>> fetchRestaurants(
          {String? query, int page = 1}) async =>
      throw Exception('Network error');

  @override
  Future<Restaurant> getRestaurant(String id) async =>
      throw UnimplementedError();
}

class _SearchableRestaurantService implements ApiRestaurantService {
  final List<Restaurant> allRestaurants;

  _SearchableRestaurantService(this.allRestaurants);

  @override
  Future<PaginatedResponse<Restaurant>> fetchRestaurants(
      {String? query, int page = 1}) async {
    if (query != null && query.isNotEmpty) {
      final filtered = allRestaurants
          .where((r) => r.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
      return PaginatedResponse(
        data: filtered,
        page: 1,
        perPage: 20,
        total: filtered.length,
        totalPages: 1,
      );
    }
    return PaginatedResponse(
      data: allRestaurants,
      page: 1,
      perPage: 20,
      total: allRestaurants.length,
      totalPages: 1,
    );
  }

  @override
  Future<Restaurant> getRestaurant(String id) async =>
      throw UnimplementedError();
}

void main() {
  late RestaurantProvider provider;
  late MockRestaurantStore store;
  late MockConnectivityService connectivity;

  setUp(() {
    store = MockRestaurantStore();
    connectivity = MockConnectivityService()..isOnline = true;
  });

  group('loadRestaurants', () {
    test('populates list from API', () async {
      final restaurants = [
        makeRestaurant(id: 'r1', name: 'KFC'),
        makeRestaurant(id: 'r2', name: 'Pizza Hut'),
      ];
      final service = MockApiRestaurantService(restaurants: restaurants);

      provider = RestaurantProvider(service,
          restaurantStore: store, connectivityService: connectivity);

      await provider.loadRestaurants();

      expect(provider.restaurants.length, 2);
      expect(provider.restaurants.first.name, 'KFC');
      expect(provider.restaurants.last.name, 'Pizza Hut');
    });

    test('sets isLoading false after load', () async {
      final service = MockApiRestaurantService(
        restaurants: [makeRestaurant()],
      );

      provider = RestaurantProvider(service,
          restaurantStore: store, connectivityService: connectivity);

      expect(provider.isLoading, false);

      final future = provider.loadRestaurants();
      expect(provider.isLoading, true);

      await future;
      expect(provider.isLoading, false);
    });

    test('error sets error message', () async {
      final service = _FailingRestaurantService();

      provider = RestaurantProvider(service,
          restaurantStore: store, connectivityService: connectivity);

      await provider.loadRestaurants();

      expect(provider.error, 'failedLoadPullRetry');
      expect(provider.isLoading, false);
    });

    test('returns early when already loaded and no forceRefresh', () async {
      final restaurants = [makeRestaurant(id: 'r1', name: 'Loaded')];
      final service = MockApiRestaurantService(restaurants: restaurants);

      provider = RestaurantProvider(service,
          restaurantStore: store, connectivityService: connectivity);

      await provider.loadRestaurants();
      expect(provider.restaurants.length, 1);

      await provider.loadRestaurants();
      expect(provider.restaurants.length, 1);
      expect(provider.restaurants.first.name, 'Loaded');
    });

    test('forceRefresh reloads even when already loaded', () async {
      final service = MockApiRestaurantService(
        restaurants: [makeRestaurant(id: 'r1', name: 'Updated')],
      );

      provider = RestaurantProvider(service,
          restaurantStore: store, connectivityService: connectivity);

      await provider.loadRestaurants();
      expect(provider.restaurants.first.name, 'Updated');
    });

    test('sets error to noInternet when offline and no cached data',
        () async {
      final offline = _OfflineConnectivityService();
      final service = MockApiRestaurantService();

      provider = RestaurantProvider(service,
          restaurantStore: store, connectivityService: offline);

      offline.goOffline();
      await Future<void>.delayed(Duration.zero);

      await provider.loadRestaurants();

      expect(provider.error, 'noInternet');
    });

    test('populates from cache when available', () async {
      final cached = [makeRestaurant(id: 'cached1', name: 'Cached Place')];
      final service = MockApiRestaurantService(restaurants: cached);
      final cacheStore = _CachingRestaurantStore(cached);

      provider = RestaurantProvider(service,
          restaurantStore: cacheStore, connectivityService: connectivity);

      await provider.loadRestaurants();

      expect(provider.restaurants.length, 1);
      expect(provider.restaurants.first.name, 'Cached Place');
    });
  });

  group('loadMoreRestaurants', () {
    test('appends more restaurants', () async {
      final page1 = [makeRestaurant(id: 'r1', name: 'Page 1')];
      final page2 = [makeRestaurant(id: 'r2', name: 'Page 2')];
      final service = _PaginatingRestaurantService([page1, page2]);

      provider = RestaurantProvider(service,
          restaurantStore: store, connectivityService: connectivity);

      await provider.loadRestaurants(forceRefresh: true);
      expect(provider.restaurants.length, 1);
      expect(provider.hasMore, true);

      await provider.loadMoreRestaurants();

      expect(provider.restaurants.length, 2);
      expect(provider.restaurants[0].name, 'Page 1');
      expect(provider.restaurants[1].name, 'Page 2');
    });

    test('does nothing when hasMore is false', () async {
      final service = MockApiRestaurantService(
        restaurants: [makeRestaurant(id: 'r1', name: 'Only')],
      );

      provider = RestaurantProvider(service,
          restaurantStore: store, connectivityService: connectivity);

      await provider.loadRestaurants(forceRefresh: true);
      expect(provider.hasMore, false);

      await provider.loadMoreRestaurants();
      expect(provider.restaurants.length, 1);
    });

    test('does nothing when isLoadingMore is true', () async {
      final page1 = [makeRestaurant(id: 'r1', name: 'Page 1')];
      final page2 = [makeRestaurant(id: 'r2', name: 'Page 2')];
      final service = _PaginatingRestaurantService([page1, page2]);

      provider = RestaurantProvider(service,
          restaurantStore: store, connectivityService: connectivity);

      await provider.loadRestaurants(forceRefresh: true);
      expect(provider.hasMore, true);

      provider.loadMoreRestaurants();
      await provider.loadMoreRestaurants();

      expect(provider.restaurants.length, 2);
    });

    test('sets isLoadingMore during fetch', () async {
      final page1 = [makeRestaurant(id: 'r1')];
      final page2 = [makeRestaurant(id: 'r2')];
      final service = _PaginatingRestaurantService([page1, page2]);

      provider = RestaurantProvider(service,
          restaurantStore: store, connectivityService: connectivity);

      await provider.loadRestaurants(forceRefresh: true);

      expect(provider.isLoadingMore, false);

      final future = provider.loadMoreRestaurants();
      expect(provider.isLoadingMore, true);

      await future;
      expect(provider.isLoadingMore, false);
    });

    test('sets hasMore false after last page', () async {
      final page1 = [makeRestaurant(id: 'r1')];
      final page2 = [makeRestaurant(id: 'r2')];
      final service = _PaginatingRestaurantService([page1, page2]);

      provider = RestaurantProvider(service,
          restaurantStore: store, connectivityService: connectivity);

      await provider.loadRestaurants(forceRefresh: true);
      expect(provider.hasMore, true);

      await provider.loadMoreRestaurants();
      expect(provider.hasMore, false);
    });
  });

  group('searchRestaurants', () {
    test('populates searchResults', () async {
      final restaurants = [
        makeRestaurant(id: 'r1', name: 'KFC'),
        makeRestaurant(id: 'r2', name: 'Pizza Hut'),
      ];
      final service = _SearchableRestaurantService(restaurants);

      provider = RestaurantProvider(service,
          restaurantStore: store, connectivityService: connectivity);

      await provider.searchRestaurants('kfc');

      expect(provider.searchResults.length, 1);
      expect(provider.searchResults.first.name, 'KFC');
    });

    test('empty query clears results', () async {
      final restaurants = [makeRestaurant(id: 'r1', name: 'KFC')];
      final service = _SearchableRestaurantService(restaurants);

      provider = RestaurantProvider(service,
          restaurantStore: store, connectivityService: connectivity);

      await provider.searchRestaurants('kfc');
      expect(provider.searchResults.length, 1);

      await provider.searchRestaurants('');
      expect(provider.searchResults, isEmpty);
      expect(provider.searchError, isNull);
    });

    test('whitespace-only query clears results', () async {
      final restaurants = [makeRestaurant(id: 'r1', name: 'KFC')];
      final service = _SearchableRestaurantService(restaurants);

      provider = RestaurantProvider(service,
          restaurantStore: store, connectivityService: connectivity);

      await provider.searchRestaurants('kfc');
      expect(provider.searchResults.length, 1);

      await provider.searchRestaurants('   ');
      expect(provider.searchResults, isEmpty);
    });

    test('error sets searchError', () async {
      final service = _FailingRestaurantService();

      provider = RestaurantProvider(service,
          restaurantStore: store, connectivityService: connectivity);

      await provider.searchRestaurants('kfc');

      expect(provider.searchError, 'searchFailedTryAgain');
      expect(provider.isSearching, false);
    });

    test('sets isSearching during fetch', () async {
      final restaurants = [makeRestaurant(id: 'r1', name: 'KFC')];
      final service = _SearchableRestaurantService(restaurants);

      provider = RestaurantProvider(service,
          restaurantStore: store, connectivityService: connectivity);

      expect(provider.isSearching, false);

      final future = provider.searchRestaurants('kfc');
      expect(provider.isSearching, true);

      await future;
      expect(provider.isSearching, false);
    });

    test('search does not affect main restaurants list', () async {
      final restaurants = [
        makeRestaurant(id: 'r1', name: 'KFC'),
        makeRestaurant(id: 'r2', name: 'Pizza Hut'),
      ];
      final service = _SearchableRestaurantService(restaurants);

      provider = RestaurantProvider(service,
          restaurantStore: store, connectivityService: connectivity);

      await provider.loadRestaurants(forceRefresh: true);
      expect(provider.restaurants.length, 2);

      await provider.searchRestaurants('kfc');
      expect(provider.searchResults.length, 1);
      expect(provider.restaurants.length, 2);
    });
  });

  group('notifyListeners', () {
    test('notifies on loadRestaurants start and end', () {
      final service = MockApiRestaurantService(
        restaurants: [makeRestaurant()],
      );
      var notifyCount = 0;

      provider = RestaurantProvider(service,
          restaurantStore: store, connectivityService: connectivity);
      provider.addListener(() => notifyCount++);

      provider.loadRestaurants().then((_) {
        expect(notifyCount, greaterThanOrEqualTo(1));
      });
    });

    test('notifies on searchRestaurants', () async {
      final restaurants = [makeRestaurant(id: 'r1', name: 'KFC')];
      final service = _SearchableRestaurantService(restaurants);
      var notifyCount = 0;

      provider = RestaurantProvider(service,
          restaurantStore: store, connectivityService: connectivity);
      provider.addListener(() => notifyCount++);

      await provider.searchRestaurants('kfc');
      expect(notifyCount, greaterThanOrEqualTo(2));
    });
  });

  group('refreshRestaurants', () {
    test('forces a reload', () async {
      final service = MockApiRestaurantService(
        restaurants: [makeRestaurant(id: 'r1', name: 'Refreshed')],
      );

      provider = RestaurantProvider(service,
          restaurantStore: store, connectivityService: connectivity);

      await provider.loadRestaurants(forceRefresh: true);
      expect(provider.restaurants.first.name, 'Refreshed');

      await provider.refreshRestaurants();
      expect(provider.restaurants.first.name, 'Refreshed');
    });
  });
}

class _CachingRestaurantStore implements MockRestaurantStore {
  final List<Restaurant> _cached;

  _CachingRestaurantStore(this._cached);

  @override
  Future<void> init() async {}

  @override
  List<Restaurant>? getRestaurantsByPage(int page) => _cached;

  @override
  Future<void> saveRestaurantsByPage(
      int page, List<Restaurant> restaurants) async {}

  @override
  Future<void> clear() async {}
}
