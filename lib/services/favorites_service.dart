import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const _favoriteIdsKey = 'favorite_offer_ids';

  Future<Set<String>> loadFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_favoriteIdsKey) ?? const <String>[]).toSet();
  }

  Future<void> saveFavoriteIds(Set<String> favoriteIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoriteIdsKey, favoriteIds.toList()..sort());
  }
}
