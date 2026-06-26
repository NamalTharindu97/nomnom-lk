import 'package:flutter/foundation.dart';

import '../models/restaurant.dart';
import '../services/api_restaurant_service.dart';

class RestaurantProvider extends ChangeNotifier {
  RestaurantProvider(this._service);

  final ApiRestaurantService _service;

  List<Restaurant> _restaurants = const [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  int _total = 0;

  List<Restaurant> get restaurants => List.unmodifiable(_restaurants);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;
  int get total => _total;

  Future<void> loadRestaurants({bool forceRefresh = false}) async {
    if (!forceRefresh && _restaurants.isNotEmpty) return;
    _setLoading(true);
    _error = null;
    _currentPage = 1;
    try {
      final result = await _service.fetchRestaurants(page: _currentPage);
      _restaurants = result.data;
      _hasMore = result.hasMore;
      _total = result.total;
    } catch (e) {
      _error = 'Failed to load restaurants.';
      debugPrint('Failed to load restaurants: $e');
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

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }
}
