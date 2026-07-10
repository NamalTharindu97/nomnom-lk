import 'package:flutter/foundation.dart';

import '../models/banner.dart';
import '../services/api_banner_service.dart';

class BannerProvider extends ChangeNotifier {
  BannerProvider(this._bannerService);

  final ApiBannerService _bannerService;

  List<FeaturedBanner> _banners = const [];
  bool _isLoading = false;
  String? _error;

  List<FeaturedBanner> get banners => _banners;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadBanners({bool forceRefresh = false}) async {
    if (_banners.isNotEmpty && !forceRefresh) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _banners = await _bannerService.fetchActiveBanners();
    } catch (e) {
      _error = 'failedLoadPullRetry';
      debugPrint('Banner load error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshBanners() async {
    await loadBanners(forceRefresh: true);
  }

  Future<void> trackClick(String bannerId) async {
    try {
      await _bannerService.trackClick(bannerId);
    } catch (_) {}
  }
}
