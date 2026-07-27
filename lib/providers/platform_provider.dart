import 'package:flutter/foundation.dart';

import '../services/api_client.dart';
import '../services/api_platform_service.dart';

class PlatformProvider extends ChangeNotifier {
  final ApiClient _client;

  List<PlatformData> _orderPlatforms = [];
  List<SocialPlatformData> _socialPlatforms = [];
  bool _isLoading = true;
  bool _loaded = false;

  PlatformProvider(this._client) {
    _load();
  }

  List<PlatformData> get orderPlatforms => _orderPlatforms;
  List<SocialPlatformData> get socialPlatforms => _socialPlatforms;
  bool get isLoading => _isLoading;

  Future<void> _load() async {
    if (_loaded) return;
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        ApiPlatformService(_client).fetchPlatforms(),
        ApiSocialPlatformService(_client).fetchPlatforms(),
      ]);
      _orderPlatforms = results[0] as List<PlatformData>;
      _socialPlatforms = results[1] as List<SocialPlatformData>;
    } catch (_) {
    } finally {
      _isLoading = false;
      _loaded = true;
      notifyListeners();
    }
  }
}
