import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class SSEService {
  SSEService(this.baseUrl);

  final String baseUrl;
  StreamSubscription? _subscription;
  final _controller = StreamController<String>.broadcast();
  bool _isConnected = false;

  Stream<String> get events => _controller.stream;
  bool get isConnected => _isConnected;

  Future<void> connect(String token) async {
    if (_isConnected) return;

    try {
      final uri = Uri.parse('$baseUrl/events').replace(
        queryParameters: {'token': token},
      );

      final client = HttpClient();
      final request = await client.getUrl(uri);
      request.headers.set('Accept', 'text/event-stream');
      request.headers.set('Cache-Control', 'no-cache');

      final response = await request.close();
      _isConnected = true;

      _subscription = response.transform(utf8.decoder).listen(
        (data) {
          for (final line in data.split('\n')) {
            if (line.startsWith('data: ')) {
              final payload = line.substring(6);
              _controller.add(payload);
            }
          }
        },
        onError: (error) {
          debugPrint('SSE error: $error');
          _isConnected = false;
        },
        onDone: () {
          _isConnected = false;
          client.close();
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('SSE connection failed: $e');
      _isConnected = false;
    }
  }

  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
