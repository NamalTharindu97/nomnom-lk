import 'dart:io';

class AppStore {
  AppStore._();

  static const _androidId = 'com.nomnomlk.nomnom_lk';
  static const _iosId = '';

  static String get storeUrl {
    if (Platform.isAndroid) {
      return 'https://play.google.com/store/apps/details?id=$_androidId';
    }
    return 'https://apps.apple.com/app/id$_iosId';
  }

  static String get marketUri {
    if (Platform.isAndroid) {
      return 'market://details?id=$_androidId';
    }
    return 'https://apps.apple.com/app/id$_iosId';
  }
}
