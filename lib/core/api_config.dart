import 'dart:io' show Platform;

class ApiConfig {
  ApiConfig._();

  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get _defaultBaseUrl {
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8080/api/v1';
      }
    } catch (_) {}
    return 'http://localhost:8080/api/v1';
  }

  static String get baseUrl =>
      _configuredBaseUrl.isNotEmpty ? _configuredBaseUrl : _defaultBaseUrl;

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const int perPage = 20;

  static String resolveUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final origin = baseUrl.replaceAll('/api/v1', '');
    return '$origin$path';
  }
}
