import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class SSEEvent {
  final String event;
  final Map<String, dynamic> data;

  SSEEvent({required this.event, required this.data});

  @override
  String toString() => 'SSEEvent($event, $data)';
}

class SSEService {
  SSEService(this.baseUrl);

  final String baseUrl;
  StreamSubscription? _subscription;
  HttpClient? _client;
  final _controller = StreamController<SSEEvent>.broadcast();
  bool _isConnected = false;
  bool _shouldReconnect = true;

  Stream<SSEEvent> get events => _controller.stream;
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;
    _shouldReconnect = true;

    try {
      final uri = Uri.parse('$baseUrl/events');

      _client = HttpClient();
      final request = await _client!.getUrl(uri);
      request.headers.set('Accept', 'text/event-stream');
      request.headers.set('Cache-Control', 'no-cache');

      final response = await request.close();
      _isConnected = true;
      debugPrint('SSE connected');

      String? currentEvent;

      _subscription = response.transform(utf8.decoder).listen(
        (data) {
          for (final line in data.split('\n')) {
            if (line.startsWith('event: ')) {
              currentEvent = line.substring(7);
            } else if (line.startsWith('data: ')) {
              final payload = line.substring(6);
              final event = currentEvent ?? 'message';
              currentEvent = null;
              try {
                final json = jsonDecode(payload) as Map<String, dynamic>;
                _controller.add(SSEEvent(event: event, data: json));
              } catch (_) {
                debugPrint('SSE parse error: $payload');
              }
            }
          }
        },
        onError: (error) {
          debugPrint('SSE error: $error');
          _isConnected = false;
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('SSE disconnected');
          _isConnected = false;
          _client?.close();
          _client = null;
          _scheduleReconnect();
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('SSE connection failed: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  void disconnect() {
    _shouldReconnect = false;
    _subscription?.cancel();
    _subscription = null;
    _client?.close();
    _client = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect) return;
    Future.delayed(const Duration(seconds: 5), () {
      if (_shouldReconnect && !_isConnected) {
        debugPrint('SSE reconnecting...');
        connect();
      }
    });
  }
}
