import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:nomnom_lk/core/theme/theme_provider.dart';
import 'package:nomnom_lk/screens/login_screen.dart';
import 'package:nomnom_lk/services/api_client.dart';
import 'package:nomnom_lk/providers/auth_provider.dart';
import 'package:nomnom_lk/services/api_auth_service.dart';

Widget createTestApp({Widget? home}) {
  final themeProvider = ThemeProvider();
  final apiClient = ApiClient();
  return MultiProvider(
    providers: [
      Provider<ApiClient>.value(value: apiClient),
      ChangeNotifierProvider.value(value: themeProvider),
      ChangeNotifierProvider(
        create: (_) => AuthProvider(ApiAuthService(apiClient)),
      ),
    ],
    child: MaterialApp(
      title: 'NomNom LK',
      home: home ?? const LoginScreen(),
      theme: ThemeData.light(),
    ),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('NomNom LK Integration Tests', () {
    testWidgets('Login screen renders brand name and tagline', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('NomNom LK'), findsOneWidget);
      expect(
        find.text('Discover the best food deals in Sri Lanka'),
        findsOneWidget,
      );
    });

    testWidgets('Login screen shows email form after tapping continue with email',
        (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('continue-email-btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('email-field')), findsOneWidget);
      expect(find.byKey(const ValueKey('password-field')), findsOneWidget);
      expect(find.byKey(const ValueKey('sign-in-btn')), findsOneWidget);
    });

    testWidgets('Login screen has sign up link', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('continue-email-btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('sign-up-link')), findsOneWidget);
    });

    testWidgets('Email field accepts input', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('continue-email-btn')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('email-field')),
        'test@example.com',
      );
      await tester.pumpAndSettle();

      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('Password field accepts input', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('continue-email-btn')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('password-field')),
        'TestPass123',
      );
      await tester.pumpAndSettle();

      expect(find.text('TestPass123'), findsOneWidget);
    });
  });
}
