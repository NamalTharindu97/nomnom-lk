import 'package:flutter_test/flutter_test.dart';

import '../lib/models/banner.dart';
import '../lib/providers/banner_provider.dart';
import 'helpers/mocks.dart';

void main() {
  test('refresh replaces an empty banner list with newly approved banners',
      () async {
    final service = MockApiBannerService();
    final provider = BannerProvider(service);

    await provider.loadBanners();
    expect(provider.banners, isEmpty);

    service.banners = [
      FeaturedBanner(
        id: 'banner-1',
        image: '/api/v1/uploads/banner.jpg',
        linkType: 'offer',
        linkValue: 'offer-1',
        title: 'New approved banner',
      ),
    ];

    await provider.refreshBanners();

    expect(service.lastForceRefresh, isTrue);
    expect(provider.banners, hasLength(1));
    expect(provider.banners.single.id, 'banner-1');
  });
}
