import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'alex_api_service.dart';

/// File d'attente de lecture vocale : chaque texte est envoyé au backend
/// (`/vocal`, Edge TTS) puis joué à la suite du précédent — même principe
/// de file que `speechQueue` / `playNextInQueue` côté PWA, réécrit avec
/// `just_audio`.
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
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/alex_tts_${_fileCounter++}.mp3';
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);
      if (_stopped) return;

      await _player.setFilePath(path);
      await _player.play();
      unawaited(file.delete());
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
