import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'alex_api_service.dart';

class TtsQueuePlayer {
  TtsQueuePlayer(this._api);

  final AlexApiService _api;
  final List<_TtsItem> _queue = [];
  bool _playing = false;
  bool _stopped = false;

  bool get isPlaying => _playing;

  Future<void> enqueue(String text, {required String voice}) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    _stopped = false;
    _queue.add(_TtsItem(text: clean, voice: voice));
  }

  Future<void> stop() async {
    _stopped = true;
    _queue.clear();
    _playing = false;
  }

  void dispose() {}
}

class _TtsItem {
  final String text;
  final String voice;
  const _TtsItem({required this.text, required this.voice});
}
