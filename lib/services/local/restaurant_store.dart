import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../models/restaurant.dart';

class RestaurantStore {
  static const String _boxName = 'restaurants';
  Box<String>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  Future<void> saveRestaurantsByPage(int page, List<Restaurant> restaurants) async {
    if (_box == null) return;
    final data = restaurants.map((o) => o.toJson()).toList();
    await _box!.put('restaurants_page_$page', jsonEncode(data));
  }

  List<Restaurant>? getRestaurantsByPage(int page) {
    if (_box == null) return null;
    final raw = _box!.get('restaurants_page_$page');
    if (raw == null) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Restaurant.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> clear() async {
    await _box?.clear();
  }
}
