import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nomnom_lk/l10n/app_localizations.dart';
import 'package:nomnom_lk/models/banner.dart';
import 'package:nomnom_lk/providers/banner_provider.dart';
import 'package:nomnom_lk/widgets/featured_banner_carousel.dart';
import '../helpers/mocks.dart';

void main() {
  testWidgets('bounds the landscape carousel and preserves auto paging',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(844, 390);
    final provider = BannerProvider(MockApiBannerService(banners: [
      FeaturedBanner(
        id: '1',
        image: '/first.jpg',
        linkType: 'offer',
        linkValue: 'offer-1',
        title: 'First Banner',
      ),
      FeaturedBanner(
        id: '2',
        image: '/second.jpg',
        linkType: 'offer',
        linkValue: 'offer-2',
        title: 'Second Banner',
      ),
    ]));
    await provider.loadBanners();

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ChangeNotifierProvider<BannerProvider>.value(
          value: provider,
          child: const FeaturedBannerCarousel(),
        ),
      ),
    ));
    await tester.pump();

    expect(tester.getSize(find.byType(PageView)).width, 568);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Second Banner'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('does not auto page while inactive', (tester) async {
    final provider = BannerProvider(MockApiBannerService(banners: [
      FeaturedBanner(
        id: '1',
        image: '/first.jpg',
        linkType: 'offer',
        linkValue: 'offer-1',
        title: 'First Banner',
      ),
      FeaturedBanner(
        id: '2',
        image: '/second.jpg',
        linkType: 'offer',
        linkValue: 'offer-2',
        title: 'Second Banner',
      ),
    ]));
    await provider.loadBanners();

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChangeNotifierProvider<BannerProvider>.value(
        value: provider,
        child: const FeaturedBannerCarousel(isActive: false),
      ),
    ));
    await tester.pump(const Duration(seconds: 5));

    expect(find.text('First Banner'), findsOneWidget);
    expect(find.text('Second Banner'), findsNothing);
  });

  testWidgets('does not auto page with reduced motion', (tester) async {
    final provider = BannerProvider(MockApiBannerService(banners: [
      FeaturedBanner(
        id: '1',
        image: '/first.jpg',
        linkType: 'offer',
        linkValue: 'offer-1',
        title: 'First Banner',
      ),
      FeaturedBanner(
        id: '2',
        image: '/second.jpg',
        linkType: 'offer',
        linkValue: 'offer-2',
        title: 'Second Banner',
      ),
    ]));
    await provider.loadBanners();

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: ChangeNotifierProvider<BannerProvider>.value(
          value: provider,
          child: const FeaturedBannerCarousel(),
        ),
      ),
    ));
    await tester.pump(const Duration(seconds: 5));

    expect(find.text('First Banner'), findsOneWidget);
    expect(find.text('Second Banner'), findsNothing);
  });
}
