import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nomnom_lk/core/theme/app_theme.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';
import 'package:nomnom_lk/providers/auth_provider.dart';
import 'package:nomnom_lk/screens/verify_email_screen.dart';

import '../helpers/mocks.dart';

Widget _buildTestApp(AuthProvider authProvider, {Locale? locale}) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: const VerifyEmailScreen(
        email: 'a.very.long.email.address@example-domain.com',
      ),
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
  group('VerifyEmailScreen adaptive layout', () {
    late AuthProvider authProvider;

    setUp(() {
      authProvider = AuthProvider(MockApiAuthService());
    });

    testWidgets('fits narrow and long email content', (tester) async {
      await _pumpAtSize(tester, authProvider, const Size(320, 568));

      expect(find.byKey(const ValueKey('verification-code-field')), findsOne);
      expect(tester.takeException(), isNull);
    });

    testWidgets('scrolls at keyboard-short and phone landscape constraints',
        (tester) async {
      await _pumpAtSize(tester, authProvider, const Size(390, 420));
      final button = find.byType(ElevatedButton);
      await tester.ensureVisible(button);
      expect(tester.getRect(button).bottom, lessThanOrEqualTo(420));
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(844, 390);
      await tester.pumpAndSettle();
      await tester.ensureVisible(button);
      expect(tester.takeException(), isNull);
    });

    testWidgets('caps width and preserves code across resize', (tester) async {
      await _pumpAtSize(tester, authProvider, const Size(390, 844));
      final codeField = find.byKey(const ValueKey('verification-code-field'));
      await tester.enterText(codeField, '123456');

      tester.view.physicalSize = const Size(700, 390);
      await tester.pumpAndSettle();

      expect(
        tester
            .getSize(find.byKey(const ValueKey('verify-email-content')))
            .width,
        480,
      );
      expect(find.text('123456'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final locale in const [Locale('si'), Locale('ta')]) {
      testWidgets('fits narrow localized content in ${locale.languageCode}',
          (tester) async {
        await _pumpAtSize(
          tester,
          authProvider,
          const Size(320, 568),
          locale: locale,
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
