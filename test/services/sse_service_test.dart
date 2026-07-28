import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom_lk/services/sse_service.dart';

void main() {
  test('uses a 30 second connection response timeout', () {
    expect(
      SSEService.connectionResponseTimeout,
      const Duration(seconds: 30),
    );
  });
}
