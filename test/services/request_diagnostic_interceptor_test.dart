import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom_lk/services/request_diagnostic_interceptor.dart';

void main() {
  group('responseRequestId', () {
    test('returns a safe request identifier', () {
      final response = Response<void>(
        requestOptions: RequestOptions(path: '/offers'),
        headers: Headers.fromMap({
          'x-request-id': ['trace:mobile-123'],
        }),
      );

      expect(responseRequestId(response), 'trace:mobile-123');
    });

    test('trims a safe request identifier', () {
      final response = Response<void>(
        requestOptions: RequestOptions(path: '/offers'),
        headers: Headers.fromMap({
          'x-request-id': ['  request-123  '],
        }),
      );

      expect(responseRequestId(response), 'request-123');
    });

    test('rejects unsafe request identifiers', () {
      final response = Response<void>(
        requestOptions: RequestOptions(path: '/offers'),
        headers: Headers.fromMap({
          'x-request-id': ['unsafe\nrequest'],
        }),
      );

      expect(responseRequestId(response), isNull);
    });

    test('returns null when the response has no identifier', () {
      final response = Response<void>(
        requestOptions: RequestOptions(path: '/offers'),
      );

      expect(responseRequestId(response), isNull);
      expect(responseRequestId(null), isNull);
    });

    test('rejects duplicate request identifier headers', () {
      final response = Response<void>(
        requestOptions: RequestOptions(path: '/offers'),
        headers: Headers.fromMap({
          'x-request-id': ['request-1', 'request-2'],
        }),
      );

      expect(responseRequestId(response), isNull);
    });
  });

  group('diagnosticRequestPath', () {
    test('redacts UUID and numeric resource identifiers', () {
      final uri = Uri.parse(
        'https://api.nomnomlk.com/api/v1/users/'
        '123e4567-e89b-12d3-a456-426614174000/offers/42?token=private',
      );

      expect(diagnosticRequestPath(uri), '/api/v1/users/:id/offers/:id');
    });

    test('preserves non-identifying route segments', () {
      final uri = Uri.parse('https://api.nomnomlk.com/api/v1/offers/active');

      expect(diagnosticRequestPath(uri), '/api/v1/offers/active');
    });
  });
}
