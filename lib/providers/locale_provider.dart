import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _boxName = 'settings';
  static const String _key = 'locale';

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  LocaleProvider();

  Future<void> initialize() async {
    await _loadLocale();
  }

  Future<void> _loadLocale() async {
    final box = await Hive.openBox<String>(_boxName);
    final code = box.get(_key, defaultValue: 'en');
    _locale = Locale(code ?? 'en');
    Intl.defaultLocale = code ?? 'en';
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    Intl.defaultLocale = languageCode;
    notifyListeners();
    final box = await Hive.openBox<String>(_boxName);
    await box.put(_key, languageCode);
  }

  String get displayName {
    switch (_locale.languageCode) {
      case 'si':
        return 'සිංහල';
      case 'ta':
        return 'தமிழ்';
      default:
        return 'English';
    }
  }

  String get flag {
    switch (_locale.languageCode) {
      case 'si':
        return '🇱🇰';
      case 'ta':
        return '🇱🇰';
      default:
        return '🇬🇧';
    }
  }

  List<_LocaleOption> get supportedLocales => const [
    _LocaleOption('en', 'English', '🇬🇧'),
    _LocaleOption('si', 'සිංහල', '🇱🇰'),
    _LocaleOption('ta', 'தமிழ்', '🇱🇰'),
  ];
}

class _LocaleOption {
  final String code;
  final String name;
  final String flag;

  const _LocaleOption(this.code, this.name, this.flag);
}
