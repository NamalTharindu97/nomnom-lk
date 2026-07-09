import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../models/offer.dart';

class OfferStore {
  static const String _boxName = 'offers';
  Box<String>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  Future<void> saveOffersByPage(int page, List<Offer> offers) async {
    if (_box == null) return;
    final data = offers.map((o) => o.toJson()).toList();
    await _box!.put('offers_page_$page', jsonEncode(data));
  }

  List<Offer>? getOffersByPage(int page) {
    if (_box == null) return null;
    final raw = _box!.get('offers_page_$page');
    if (raw == null) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Offer.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> clear() async {
    await _box?.clear();
  }
}
