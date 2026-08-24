import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'alex_api_service.dart';

class TtsQueuePlayer {
  TtsQueuePlayer(this._api);

  final AlexApiService _api;
  final AudioPlayer _player = AudioPlayer();
  final List<_TtsItem> _queue = [];
  bool _playing = false;
  bool _stopped = false;
  int _fileCounter = 0;

  bool get isPlaying => _playing;

  Future<void> enqueue(String text, {required String voice}) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    _stopped = false;
    _queue.add(_TtsItem(text: clean, voice: voice));
    if (!_playing) unawaited(_playNext());
  }

  Future<void> stop() async {
    _stopped = true;
    _queue.clear();
    _playing = false;
    await _player.stop();
  }

  Future<void> _playNext() async {
    if (_stopped || _queue.isEmpty) {
      _playing = false;
      return;
    }
    _playing = true;
    final item = _queue.removeAt(0);
    try {
      final bytes = await _api.fetchSpeech(text: item.text, voice: item.voice);
      if (_stopped) return;
      if (bytes == null || bytes.isEmpty) {
        return _playNext();
      }
      final dataUrl = 'data:audio/mpeg;base64,${base64Encode(bytes)}';
      await _player.setUrl(dataUrl);
      if (!_stopped) await _player.play();
      return _playNext();
    } catch (_) {
      return _playNext();
    }
  }

  void dispose() {
    _player.dispose();
  }
}

class _TtsItem {
  final String text;
  final String voice;
  const _TtsItem({required this.text, required this.voice});
}
