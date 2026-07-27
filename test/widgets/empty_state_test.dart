import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nomnom_lk/l10n/app_localizations.dart';
import 'package:nomnom_lk/widgets/empty_state.dart';

Widget wrapWithApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('EmptyState', () {
    const title = 'No offers found';
    const message = 'Try adjusting your filters';
    const icon = Icons.search_off_rounded;

    testWidgets('renders title and message', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithApp(
        const EmptyState(icon: icon, title: title, message: message),
      ));
      expect(find.text(title), findsOneWidget);
      expect(find.text(message), findsOneWidget);
    });

    testWidgets('renders icon', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithApp(
        const EmptyState(icon: icon, title: title, message: message),
      ));
      expect(find.byIcon(icon), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithApp(
        EmptyState(
          icon: icon,
          title: title,
          message: message,
          onRetry: () {},
        ),
      ));
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('hides retry button when onRetry is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithApp(
        const EmptyState(icon: icon, title: title, message: message),
      ));
      expect(find.byType(FilledButton), findsNothing);
    });
  });
}
