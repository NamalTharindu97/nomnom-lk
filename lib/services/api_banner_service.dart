import 'package:flutter/foundation.dart';

import '../models/banner.dart';
import 'api_client.dart';

class ApiBannerService {
  ApiBannerService(this._client);

  final ApiClient _client;

  Future<List<FeaturedBanner>> fetchActiveBanners(
      {bool forceRefresh = false}) async {
    if (forceRefresh) {
      _client.invalidateCache('/banners/active');
    }
    final response = await _client.get('/banners/active');
    final data = response['data'] as List<dynamic>;
    final banners = <FeaturedBanner>[];
    for (final item in data) {
      try {
        banners.add(FeaturedBanner.fromJson(item as Map<String, dynamic>));
      } catch (error) {
        debugPrint('Skipping malformed banner: $error');
      }
    }
    return banners;
  }

  Future<void> trackClick(String bannerId) async {
    await _client.post('/banners/$bannerId/click', null);
  }
}
