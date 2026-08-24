import 'dart:async';

import 'package:flutter/foundation.dart';

class WakeWordService {
  StreamSubscription? _porcupineSubscription;
  bool _isActive = false;
  bool _hasPermission = false;

  VoidCallback? onWakeDetected;
  Function(String error)? onError;

  bool get isActive => _isActive;
  bool get hasPermission => _hasPermission;

  Future<void> start({
    String? accessKey,
    String? keywordPath,
  }) async {
    if (_isActive) return;
    _hasPermission = true;
    _isActive = true;
  }

  Future<void> stop() async {
    _isActive = false;
    await _porcupineSubscription?.cancel();
    _porcupineSubscription = null;
  }

  void pause() {
    if (!_isActive) return;
    _porcupineSubscription?.pause();
  }

  void resume() {
    if (!_isActive) return;
    _porcupineSubscription?.resume();
  }

  void dispose() {
    stop();
  }
}

class MicrophonePermission {
  static Future<bool> request() async => true;
}
