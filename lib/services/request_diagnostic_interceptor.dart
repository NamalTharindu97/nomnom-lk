import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final _safeRequestId = RegExp(r'^[A-Za-z0-9._:-]{1,128}$');
final _uuidPathSegment = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);
final _numericPathSegment = RegExp(r'^\d+$');
const _diagnosticRecordedKey = 'request_diagnostic_recorded';

String? responseRequestId(Response<dynamic>? response) {
  final values = response?.headers['x-request-id'];
  if (values == null || values.length != 1) return null;
  final requestId = values.single.trim();
  if (!_safeRequestId.hasMatch(requestId)) return null;
  return requestId;
}

String diagnosticRequestPath(Uri uri) {
  final segments = uri.pathSegments.map((segment) {
    if (_uuidPathSegment.hasMatch(segment) ||
        _numericPathSegment.hasMatch(segment)) {
      return ':id';
    }
    return segment;
  });
  return '/${segments.join('/')}';
}

class RequestDiagnosticInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.requestOptions.extra[_diagnosticRecordedKey] == true) {
      handler.next(err);
      return;
    }
    err.requestOptions.extra[_diagnosticRecordedKey] = true;

    final requestId = responseRequestId(err.response);
    if (requestId != null) {
      err.requestOptions.extra['request_id'] = requestId;
    }

    final method = err.requestOptions.method;
    final path = diagnosticRequestPath(err.requestOptions.uri);
    final status = err.response?.statusCode;
    debugPrint(
      'API error: $method $path status=${status ?? 'none'} '
      'request_id=${requestId ?? 'none'}',
    );

    Sentry.addBreadcrumb(Breadcrumb(
      category: 'http',
      level: SentryLevel.error,
      message: 'API request failed',
      data: <String, dynamic>{
        'method': method,
        'path': path,
        if (status != null) 'status': status,
        if (requestId != null) 'request_id': requestId,
      },
    ));

    handler.next(err);
  }
}
