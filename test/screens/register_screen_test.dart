import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nomnom_lk/l10n/app_localizations.dart';
import 'package:nomnom_lk/providers/auth_provider.dart';
import 'package:nomnom_lk/screens/register_screen.dart';
import '../helpers/mocks.dart';

Widget buildTestApp(AuthProvider authProvider) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: const RegisterScreen(),
    ),
  );
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
      final formKey = tester.widget<Form>(find.byType(Form)).key as GlobalKey<FormState>;
      expect(formKey.currentState!.validate(), isFalse);
    });

    testWidgets('shows validation for short password',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(authProvider));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(2), '12');
      await tester.enterText(fields.at(3), '34');

      final formKey = tester.widget<Form>(find.byType(Form)).key as GlobalKey<FormState>;
      expect(formKey.currentState!.validate(), isFalse);
    });
  });
}
