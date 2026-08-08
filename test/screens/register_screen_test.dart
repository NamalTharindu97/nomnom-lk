import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nomnom_lk/core/theme/app_theme.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';
import 'package:nomnom_lk/providers/auth_provider.dart';
import 'package:nomnom_lk/screens/register_screen.dart';
import '../helpers/mocks.dart';

Widget buildTestApp(AuthProvider authProvider, {Locale? locale}) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: const RegisterScreen(),
    ),
  );
}

Future<void> pumpAtSize(
  WidgetTester tester,
  AuthProvider authProvider,
  Size size, {
  Locale? locale,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(buildTestApp(authProvider, locale: locale));
  await tester.pumpAndSettle();
}

void main() {
  group('RegisterScreen', () {
    late AuthProvider authProvider;

    setUp(() {
      authProvider = AuthProvider(MockApiAuthService());
    });

    testWidgets('renders all form fields', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(authProvider));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(4));
    });

    testWidgets('renders register button', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(authProvider));
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('shows validation for empty fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(authProvider));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Name and email fields show validation errors for empty input
      expect(find.byType(TextFormField), findsNWidgets(4));
      // Trigger form validation by submitting empty fields
      final formKey =
          tester.widget<Form>(find.byType(Form)).key as GlobalKey<FormState>;
      expect(formKey.currentState!.validate(), isFalse);
    });

    testWidgets('shows validation for short password',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(authProvider));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(2), '12');
      await tester.enterText(fields.at(3), '34');

      final formKey =
          tester.widget<Form>(find.byType(Form)).key as GlobalKey<FormState>;
      expect(formKey.currentState!.validate(), isFalse);
    });

    testWidgets('fits narrow and keyboard-short constraints', (tester) async {
      await pumpAtSize(tester, authProvider, const Size(320, 568));
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(390, 420);
      await tester.pumpAndSettle();
      final button = find.byType(ElevatedButton);
      await tester.ensureVisible(button);
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.getRect(button).bottom, lessThanOrEqualTo(420));
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits supported phone landscape sizes', (tester) async {
      await pumpAtSize(tester, authProvider, const Size(700, 390));
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(844, 390);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(ElevatedButton));
      expect(tester.takeException(), isNull);
    });

    testWidgets('caps width and preserves form state across resize',
        (tester) async {
      await pumpAtSize(tester, authProvider, const Size(390, 844));
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Namal');
      await tester.enterText(fields.at(1), 'user@example.com');

      tester.view.physicalSize = const Size(700, 390);
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byKey(const ValueKey('register-content'))).width,
        480,
      );
      expect(find.text('Namal'), findsOneWidget);
      expect(find.text('user@example.com'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final locale in const [Locale('si'), Locale('ta')]) {
      testWidgets('wraps narrow footer in ${locale.languageCode}',
          (tester) async {
        await pumpAtSize(
          tester,
          authProvider,
          const Size(320, 568),
          locale: locale,
        );
        await tester.ensureVisible(find.byType(Wrap));

        expect(tester.takeException(), isNull);
      });
    }
  });
}
