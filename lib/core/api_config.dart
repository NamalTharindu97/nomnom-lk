import 'dart:io' show Platform;

class ApiConfig {
  ApiConfig._();

  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static const String _appEnv = String.fromEnvironment('APP_ENV');
  static const String _buildSha = String.fromEnvironment('BUILD_SHA');

  static bool get isRelease => _appEnv == 'release';
  static String get appEnv => _appEnv.isNotEmpty ? _appEnv : 'debug';
  static String get buildSha => _buildSha.isNotEmpty ? _buildSha : 'local';

  static String get _defaultBaseUrl {
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8080/api/v1';
      }
    } catch (_) {}
    return 'http://localhost:8080/api/v1';
  }

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      _assertValidReleaseUrl(_configuredBaseUrl);
      return _configuredBaseUrl;
    }
    if (isRelease) {
      throw StateError(
        'API_BASE_URL must be set for release builds. '
        'Pass --dart-define=API_BASE_URL=https://your-api.example.com/api/v1',
      );
    }
    return _defaultBaseUrl;
  }

  static void _assertValidReleaseUrl(String url) {
    if (!isRelease) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw StateError('API_BASE_URL must be a valid absolute URL in release mode');
    }
    if (uri.scheme != 'https') {
      throw StateError('API_BASE_URL must use HTTPS in release mode, got: ${uri.scheme}');
    }
    final host = uri.host.toLowerCase();
    final blocked = ['localhost', '127.0.0.1', '::1', '10.0.2.2'];
    if (blocked.contains(host) ||
        host.startsWith('192.168.') ||
        host.startsWith('10.') ||
        host.startsWith('172.16.')) {
      throw StateError('API_BASE_URL must not point to local or private network in release mode');
    }
  }

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
