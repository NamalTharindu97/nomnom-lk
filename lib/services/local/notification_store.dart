import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

class NotificationStore {
  static const String _boxName = 'notifications';
  Box<String>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  Future<void> saveNotifications(List<Map<String, dynamic>> notifications) async {
    if (_box == null) return;
    await _box!.put('all', jsonEncode(notifications));
  }

  List<Map<String, dynamic>>? getNotifications() {
    if (_box == null) return null;
    final raw = _box!.get('all');
    if (raw == null) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> clear() async {
    await _box?.clear();
  }
}
