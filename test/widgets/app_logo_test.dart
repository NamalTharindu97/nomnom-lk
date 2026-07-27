import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nomnom_lk/l10n/app_localizations.dart';
import 'package:nomnom_lk/widgets/app_logo.dart';

Widget wrapWithApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('AppLogo', () {
    testWidgets('full mode shows brand text', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithApp(const AppLogo()));
      expect(find.text('NomNom LK'), findsOneWidget);
    });

    testWidgets('compact mode shows brand text', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithApp(const AppLogo(compact: true)));
      expect(find.text('NomNom LK'), findsOneWidget);
    });

    testWidgets('renders restaurant menu icon', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithApp(const AppLogo()));
      expect(find.byIcon(Icons.restaurant_menu_rounded), findsOneWidget);
    });
  });
}
