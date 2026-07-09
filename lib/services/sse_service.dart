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
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _initialDelay = Duration(seconds: 1);
  static const Duration _maxDelay = Duration(seconds: 30);
  StreamSubscription? _subscription;
  HttpClient? _client;
  final _controller = StreamController<SSEEvent>.broadcast();
  bool _isConnected = false;
  bool _shouldReconnect = true;
  String _buffer = '';

  Stream<SSEEvent> get events => _controller.stream;
  bool get isConnected => _isConnected;
  bool get isReconnecting => _reconnectAttempts > 0;

  Duration _getReconnectDelay() {
    final delay = _initialDelay * (1 << _reconnectAttempts);
    return delay > _maxDelay ? _maxDelay : delay;
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect || _reconnectAttempts >= _maxReconnectAttempts) return;
    _reconnectAttempts++;
    final delay = _getReconnectDelay();
    debugPrint('SSE reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)...');
    Future.delayed(delay, () {
      if (_shouldReconnect && !_isConnected) {
        debugPrint('SSE reconnecting...');
        connect();
      }
    });
  }

  Future<void> connect() async {
    if (_isConnected) return;
    _shouldReconnect = true;
    _buffer = '';

    try {
      final uri = Uri.parse('$baseUrl/events');

      _client = HttpClient();
      _client!.connectionTimeout = const Duration(seconds: 5);
      final request = await _client!.getUrl(uri);
      request.headers.set('Accept', 'text/event-stream');
      request.headers.set('Cache-Control', 'no-cache');

      final response = await request.close().timeout(const Duration(seconds: 10));
      _isConnected = true;
      _reconnectAttempts = 0;
      debugPrint('SSE connected');

      _subscription = response.transform(utf8.decoder).listen(
        (data) {
          _buffer += data;
          while (true) {
            final delimiter = _buffer.indexOf('\n\n');
            if (delimiter == -1) break;

            final block = _buffer.substring(0, delimiter);
            _buffer = _buffer.substring(delimiter + 2);

            String? currentEvent;
            for (final line in block.split('\n')) {
              if (line.startsWith('event:')) {
                currentEvent = line.substring(6).trim();
              } else if (line.startsWith('data:')) {
                final payload = line.substring(5).trim();
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
    _reconnectAttempts = 0;
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
}
