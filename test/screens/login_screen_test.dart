import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nomnom_lk/core/theme/app_theme.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';
import 'package:nomnom_lk/providers/auth_provider.dart';
import 'package:nomnom_lk/screens/login_screen.dart';

import '../helpers/mocks.dart';

Widget _buildTestApp(AuthProvider authProvider, {Locale? locale}) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: const LoginScreen(),
    ),
  );
}

Future<void> _pumpAtSize(
  WidgetTester tester,
  AuthProvider authProvider,
  Size size, {
  Locale? locale,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(_buildTestApp(authProvider, locale: locale));
  await tester.pumpAndSettle();
}

void main() {
  group('LoginScreen adaptive layout', () {
    late AuthProvider authProvider;

    setUp(() {
      authProvider = AuthProvider(MockApiAuthService());
    });

    testWidgets('fits a narrow compact window and reveals the email form',
        (tester) async {
      await _pumpAtSize(tester, authProvider, const Size(320, 568));

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('google-sign-in-btn')), findsOneWidget);

      final emailButton = find.byKey(const ValueKey('continue-email-btn'));
      await tester.ensureVisible(emailButton);
      await tester.tap(emailButton);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('email-field')), findsOneWidget);
      expect(find.byKey(const ValueKey('password-field')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('remains scrollable at keyboard-height constraints',
        (tester) async {
      await _pumpAtSize(tester, authProvider, const Size(390, 420));

      final emailButton = find.byKey(const ValueKey('continue-email-btn'));
      await tester.ensureVisible(emailButton);
      await tester.tap(emailButton);
      await tester.pumpAndSettle();

      final signInButton = find.byKey(const ValueKey('sign-in-btn'));
      await tester.ensureVisible(signInButton);
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.getRect(signInButton).bottom, lessThanOrEqualTo(420));
      expect(tester.takeException(), isNull);
    });

    testWidgets('caps content width on medium and expanded windows',
        (tester) async {
      await _pumpAtSize(tester, authProvider, const Size(700, 900));

      final content = find.byKey(const ValueKey('login-content'));
      expect(tester.getSize(content).width, 440);
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(1200, 900);
      await tester.pumpAndSettle();

      expect(tester.getSize(content).width, 440);
      expect(tester.takeException(), isNull);
    });

    testWidgets('preserves entered form state across resize', (tester) async {
      await _pumpAtSize(tester, authProvider, const Size(390, 800));

      await tester.tap(find.byKey(const ValueKey('continue-email-btn')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('email-field')),
        'user@example.com',
      );

      tester.view.physicalSize = const Size(1000, 800);
      await tester.pumpAndSettle();

      expect(find.text('user@example.com'), findsOneWidget);
      expect(find.byKey(const ValueKey('password-field')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final locale in const [Locale('si'), Locale('ta')]) {
      testWidgets(
          'wraps localized actions at narrow width for ${locale.languageCode}',
          (tester) async {
        await _pumpAtSize(
          tester,
          authProvider,
          const Size(320, 568),
          locale: locale,
        );

        expect(find.byKey(const ValueKey('sign-up-link')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
