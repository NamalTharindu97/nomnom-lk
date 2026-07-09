import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  bool _isOnline = true;
  bool get isOnline => _isOnline;
  Stream<bool> get onConnectivityChanged => _controller.stream;

  ConnectivityService() {
    _connectivity.onConnectivityChanged.listen((result) {
      final online = result != ConnectivityResult.none;
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(online);
      }
    });
  }

  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
    return _isOnline;
  }

  void dispose() {
    _controller.close();
  }
}
