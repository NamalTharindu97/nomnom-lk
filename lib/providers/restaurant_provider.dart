import 'package:flutter/foundation.dart';

import '../models/restaurant.dart';
import '../services/api_restaurant_service.dart';

class RestaurantProvider extends ChangeNotifier {
  RestaurantProvider(this._service);

  final ApiRestaurantService _service;

  List<Restaurant> _restaurants = const [];
  bool _isLoading = false;
  String? _error;

  List<Restaurant> get restaurants => List.unmodifiable(_restaurants);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadRestaurants() async {
    _setLoading(true);
    _error = null;
    try {
      _restaurants = await _service.fetchRestaurants();
    } catch (e) {
      _error = 'Failed to load restaurants.';
      debugPrint('Failed to load restaurants: $e');
    }
    _setLoading(false);
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }
}
