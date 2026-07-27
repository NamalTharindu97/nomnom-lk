import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nomnom_lk/providers/locale_provider.dart';

void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.path);
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  setUp(() async {
    if (Hive.isBoxOpen('settings')) {
      await Hive.box<String>('settings').clear();
    }
  });

  group('LocaleProvider', () {
    test('default locale is English', () {
      final provider = LocaleProvider();
      expect(provider.locale.languageCode, 'en');
    });

    test('setLocale updates locale', () async {
      final provider = LocaleProvider();

      await provider.setLocale('si');
      expect(provider.locale.languageCode, 'si');

      await provider.setLocale('ta');
      expect(provider.locale.languageCode, 'ta');
    });

    test('setLocale persists to Hive', () async {
      final provider = LocaleProvider();

      await provider.setLocale('si');

      final box = Hive.box<String>('settings');
      expect(box.get('locale'), 'si');
    });

    test('initialize loads persisted locale', () async {
      final box = Hive.box<String>('settings');
      await box.put('locale', 'ta');

      final provider = LocaleProvider();
      await provider.initialize();

      expect(provider.locale.languageCode, 'ta');
    });

    test('displayName returns correct name for each locale', () async {
      final provider = LocaleProvider();

      expect(provider.displayName, 'English');

      await provider.setLocale('si');
      expect(provider.displayName, 'සිංහල');

      await provider.setLocale('ta');
      expect(provider.displayName, 'தமிழ்');

      await provider.setLocale('en');
      expect(provider.displayName, 'English');
    });

    test('flag returns correct flag for each locale', () async {
      final provider = LocaleProvider();

      expect(provider.flag, '🇬🇧');

      await provider.setLocale('si');
      expect(provider.flag, '🇱🇰');

      await provider.setLocale('ta');
      expect(provider.flag, '🇱🇰');

      await provider.setLocale('en');
      expect(provider.flag, '🇬🇧');
    });

    test('supportedLocales has 3 entries', () {
      final provider = LocaleProvider();
      expect(provider.supportedLocales, hasLength(3));
    });

    test('notifyListeners fires on locale change', () async {
      final provider = LocaleProvider();
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.setLocale('si');

      expect(notifyCount, 1);
    });
  });
}
