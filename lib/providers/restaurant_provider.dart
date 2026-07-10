import 'package:flutter/foundation.dart';

import '../models/restaurant.dart';
import '../services/api_restaurant_service.dart';
import '../services/connectivity_service.dart';
import '../services/local/restaurant_store.dart';

class RestaurantProvider extends ChangeNotifier {
  RestaurantProvider(
    this._service, {
    required RestaurantStore restaurantStore,
    required ConnectivityService connectivityService,
  })  : _restaurantStore = restaurantStore,
        _connectivityService = connectivityService {
    _connectivityService.onConnectivityChanged.listen((online) {
      _isOnline = online;
    });
  }

  final ApiRestaurantService _service;
  final RestaurantStore _restaurantStore;
  final ConnectivityService _connectivityService;

  bool _isOnline = true;

  List<Restaurant> _restaurants = const [];
  List<Restaurant> _searchResults = const [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSearching = false;
  String? _error;
  String? _searchError;
  int _currentPage = 1;
  bool _hasMore = true;
  int _total = 0;

  List<Restaurant> get restaurants => List.unmodifiable(_restaurants);
  List<Restaurant> get searchResults => List.unmodifiable(_searchResults);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSearching => _isSearching;
  String? get error => _error;
  String? get searchError => _searchError;
  bool get hasMore => _hasMore;
  int get total => _total;

  Future<void> loadRestaurants({bool forceRefresh = false}) async {
    if (!forceRefresh && _restaurants.isNotEmpty) return;
    _setLoading(true);
    _error = null;
    _currentPage = 1;

    // Cache-first: populate from Hive immediately
    final cached = _restaurantStore.getRestaurantsByPage(_currentPage);
    if (cached != null && _restaurants.isEmpty) {
      _restaurants = cached;
      _total = cached.length;
      _hasMore = false;
      _setLoading(false);
    }

    if (_isOnline) {
      try {
        final result = await _service.fetchRestaurants(page: _currentPage);
        _restaurants = result.data;
        _hasMore = result.hasMore;
        _total = result.total;
        await _restaurantStore.saveRestaurantsByPage(_currentPage, _restaurants);
      } catch (e) {
        _error = 'failedLoadPullRetry';
        debugPrint('Failed to load restaurants: $e');
      }
    }

    if (_restaurants.isEmpty && !_isOnline) {
      _error ??= 'noInternet';
    }

    _setLoading(false);
  }

  Future<void> loadMoreRestaurants() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final nextPage = _currentPage + 1;
      final result = await _service.fetchRestaurants(page: nextPage);
      _hasMore = result.hasMore;
      _currentPage = nextPage;
      _restaurants = [..._restaurants, ...result.data];
      await _restaurantStore.saveRestaurantsByPage(_currentPage, _restaurants);
    } catch (e) {
      debugPrint('Failed to load more restaurants: $e');
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> refreshRestaurants() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await loadRestaurants(forceRefresh: true);
  }

  Future<void> searchRestaurants(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = const [];
      _searchError = null;
      notifyListeners();
      return;
    }
    _isSearching = true;
    _searchError = null;
    notifyListeners();
    try {
      final result = await _service.fetchRestaurants(query: query);
      _searchResults = result.data;
    } catch (_) {
      _searchError = 'searchFailedTryAgain';
    }
    _isSearching = false;
    notifyListeners();
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }
}
