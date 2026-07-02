import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nomnom_lk/main.dart' as app;
import 'package:nomnom_lk/screens/login_screen.dart';
import 'package:nomnom_lk/core/theme/theme_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login Screen', () {
    testWidgets('renders login form with email and password fields', (tester) async {
      final themeProvider = ThemeProvider();
      await themeProvider.load();
      await tester.pumpWidget(
        MaterialApp(
          home: const LoginScreen(),
          theme: ThemeData.light(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NomNom LK'), findsOneWidget);
    });

    testWidgets('shows validation error with empty fields', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const LoginScreen(),
          theme: ThemeData.light(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('continue-email-btn')));
      await tester.pumpAndSettle();

      final emailField = find.byKey(const ValueKey('email-field'));
      expect(emailField, findsOneWidget);

      await tester.enterText(emailField, '');
      await tester.pumpAndSettle();
    });

    testWidgets('navigates to register screen on sign up tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const LoginScreen(),
          theme: ThemeData.light(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('continue-email-btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('sign-up-link')), findsOneWidget);
    });
  });
}
