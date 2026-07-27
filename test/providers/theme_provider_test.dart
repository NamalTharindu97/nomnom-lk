import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom_lk/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeProvider', () {
    test('default mode is dark', () {
      final provider = ThemeProvider();
      expect(provider.mode, ThemeMode.dark);
      expect(provider.isDark, isTrue);
    });

    test('load with no stored value stays dark', () async {
      final provider = ThemeProvider();
      await provider.load();

      expect(provider.mode, ThemeMode.dark);
      expect(provider.isDark, isTrue);
    });

    test('load with light stored sets light', () async {
      SharedPreferences.setMockInitialValues({'nomnom_theme_mode': 'light'});
      final provider = ThemeProvider();
      await provider.load();

      expect(provider.mode, ThemeMode.light);
      expect(provider.isDark, isFalse);
    });

    test('load with system stored sets system', () async {
      SharedPreferences.setMockInitialValues({'nomnom_theme_mode': 'system'});
      final provider = ThemeProvider();
      await provider.load();

      expect(provider.mode, ThemeMode.system);
      expect(provider.isDark, isFalse);
    });

    test('setMode changes mode and persists', () async {
      final provider = ThemeProvider();

      await provider.setMode(ThemeMode.light);
      expect(provider.mode, ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('nomnom_theme_mode'), 'light');
    });

    test('toggle switches dark to light', () async {
      final provider = ThemeProvider();
      expect(provider.mode, ThemeMode.dark);

      await provider.toggle();
      expect(provider.mode, ThemeMode.light);
    });

    test('toggle switches light to dark', () async {
      final provider = ThemeProvider();
      await provider.setMode(ThemeMode.light);
      expect(provider.mode, ThemeMode.light);

      await provider.toggle();
      expect(provider.mode, ThemeMode.dark);
    });

    test('isDark reflects state', () async {
      final provider = ThemeProvider();
      expect(provider.isDark, isTrue);

      await provider.setMode(ThemeMode.light);
      expect(provider.isDark, isFalse);

      await provider.setMode(ThemeMode.system);
      expect(provider.isDark, isFalse);

      await provider.setMode(ThemeMode.dark);
      expect(provider.isDark, isTrue);
    });

    test('notifyListeners fires on mode change', () async {
      final provider = ThemeProvider();
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.load();
      await provider.setMode(ThemeMode.light);

      expect(notifyCount, greaterThanOrEqualTo(2));
    });
  });
}
