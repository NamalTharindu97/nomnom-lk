import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nomnom_lk/l10n/app_localizations.dart';
import 'package:nomnom_lk/models/notification_model.dart';
import 'package:nomnom_lk/providers/notification_provider.dart';
import 'package:nomnom_lk/screens/notifications_screen.dart';
import '../helpers/mocks.dart';

Widget buildTestApp(
  NotificationProvider provider, {
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ChangeNotifierProvider<NotificationProvider>.value(
      value: provider,
      child: const NotificationsScreen(),
    ),
  );
}

void main() {
  group('NotificationsScreen', () {
    testWidgets('shows empty state when no notifications',
        (WidgetTester tester) async {
      final provider = NotificationProvider(
        MockApiNotificationService(),
        notificationStore: MockNotificationStore(),
      );

      await tester.pumpWidget(buildTestApp(provider));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    });

    testWidgets('shows notification list when loaded',
        (WidgetTester tester) async {
      final mockService = MockApiNotificationService();
      mockService.notifications = [
        AppNotification(
          id: 'n1',
          type: 'offer',
          title: 'New Deal',
          body: '50% off pizza',
          isRead: false,
          createdAt: DateTime(2026, 7, 25, 10, 0),
        ),
        AppNotification(
          id: 'n2',
          type: 'offer',
          title: 'Update',
          body: 'Offer updated',
          isRead: true,
          createdAt: DateTime(2026, 7, 25, 8, 0),
        ),
      ];
      final provider = NotificationProvider(
        mockService,
        notificationStore: MockNotificationStore(),
      );

      await tester.pumpWidget(buildTestApp(provider));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.text('New Deal'), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);
    });

    testWidgets('long localized content reflows at compact and landscape sizes',
        (WidgetTester tester) async {
      final mockService = MockApiNotificationService();
      mockService.notifications = [
        AppNotification(
          id: 'long',
          type: 'offer',
          title:
              'A very long notification title that must remain bounded on a narrow phone',
          body:
              'A long notification body that should be constrained and safely truncated '
              'without changing notification provider state.',
          isRead: false,
          createdAt: DateTime.now(),
        ),
      ];
      final provider = NotificationProvider(
        mockService,
        notificationStore: MockNotificationStore(),
      );
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;

      for (final size in const [
        Size(320, 568),
        Size(390, 844),
        Size(700, 390),
        Size(844, 390),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(buildTestApp(
          provider,
          locale: const Locale('ta'),
        ));
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull, reason: 'Failed at $size');
      }

      final title = tester.widget<Text>(find.textContaining(
        'A very long notification title',
      ));
      expect(title.maxLines, isNull);
      expect(title.overflow, isNull);
    });
  });
}
