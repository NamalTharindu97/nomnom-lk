import 'package:hive_flutter/hive_flutter.dart';

class FavoriteStore {
  static const String _boxName = 'favorites';
  late Box<String> _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  Set<String> getFavorites() {
    final raw = _box.get('favorite_ids');
    if (raw == null || raw.isEmpty) return {};
    return raw.split(',').toSet();
  }

  Future<void> addFavorite(String offerId) async {
    final favorites = getFavorites()..add(offerId);
    await _box.put('favorite_ids', favorites.join(','));
  }

  Future<void> removeFavorite(String offerId) async {
    final favorites = getFavorites()..remove(offerId);
    await _box.put('favorite_ids', favorites.join(','));
  }

  Future<void> syncFromRemote(Set<String> remoteIds) async {
    await _box.put('favorite_ids', remoteIds.join(','));
  }
}
