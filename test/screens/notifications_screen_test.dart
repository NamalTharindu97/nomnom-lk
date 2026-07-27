import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nomnom_lk/l10n/app_localizations.dart';
import 'package:nomnom_lk/models/notification_model.dart';
import 'package:nomnom_lk/providers/notification_provider.dart';
import 'package:nomnom_lk/screens/notifications_screen.dart';
import '../helpers/mocks.dart';

Widget buildTestApp(NotificationProvider provider) {
  return MaterialApp(
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
  });
}
