import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nomnom_lk/l10n/app_localizations.dart';
import 'package:nomnom_lk/models/social_link.dart';
import 'package:nomnom_lk/services/api_platform_service.dart';
import 'package:nomnom_lk/widgets/follow_section.dart';

Widget wrapWithApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('FollowSection', () {
    testWidgets('renders platform display names', (tester) async {
      final links = [
        const SocialLink(
            platform: 'instagram', url: 'https://instagram.com/test'),
        const SocialLink(
            platform: 'facebook', url: 'https://facebook.com/test'),
      ];
      final platforms = [
        SocialPlatformData(
            id: '1',
            slug: 'instagram',
            displayName: 'Instagram',
            primaryColor: '#E1306C'),
        SocialPlatformData(
            id: '2',
            slug: 'facebook',
            displayName: 'Facebook',
            primaryColor: '#1877F2'),
      ];

      await tester.pumpWidget(wrapWithApp(
        FollowSection(socialLinks: links, platforms: platforms),
      ));

      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('Facebook'), findsOneWidget);
    });

    testWidgets('renders Follow heading', (tester) async {
      final links = [
        const SocialLink(
            platform: 'instagram', url: 'https://instagram.com/test'),
      ];

      await tester.pumpWidget(wrapWithApp(
        FollowSection(socialLinks: links),
      ));

      expect(find.textContaining('Follow'), findsWidgets);
    });

    testWidgets('empty social links renders nothing', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        const FollowSection(socialLinks: []),
      ));

      expect(find.byType(Column), findsNothing);
    });

    testWidgets('renders correct number of chevron icons', (tester) async {
      final links = [
        const SocialLink(
            platform: 'instagram', url: 'https://instagram.com/test'),
        const SocialLink(
            platform: 'facebook', url: 'https://facebook.com/test'),
      ];

      await tester.pumpWidget(wrapWithApp(
        FollowSection(socialLinks: links),
      ));

      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(2));
    });

    testWidgets('falls back to platform slug when no SocialPlatformData match',
        (tester) async {
      final links = [
        const SocialLink(platform: 'twitter', url: 'https://twitter.com/test'),
      ];

      await tester.pumpWidget(wrapWithApp(
        FollowSection(socialLinks: links),
      ));

      expect(find.text('twitter'), findsOneWidget);
    });

    testWidgets('wraps long social labels at 320 width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrapWithApp(FollowSection(
        socialLinks: const [
          SocialLink(platform: 'community', url: 'https://example.com'),
        ],
        platforms: [
          SocialPlatformData(
            id: '1',
            slug: 'community',
            displayName: 'A Very Long Restaurant Community Social Page',
            primaryColor: '#1877F2',
          ),
        ],
      )));

      expect(tester.takeException(), isNull);
    });
  });
}
