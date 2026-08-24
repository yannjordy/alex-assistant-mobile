import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class EdgeTtsService {
  static const _edgeTtsHost = 'speech.platform.bing.com';
  static const _edgeTtsPath = '/consumer/speech/synthesize/readaloud/edge/v1';

  String _selectedVoice = 'denise';
  String get selectedVoice => _selectedVoice;
  set selectedVoice(String voice) => _selectedVoice = voice;

  Future<Uint8List?> synthesize(String text) async {
    if (kIsWeb) return _synthesizeViaBackend(text: text);
    return _synthesizeNative(text);
  }

  Future<Uint8List?> _synthesizeNative(String text) async {
    try {
      // Sur mobile/desktop: WebSocket natif via dart:io (importé dynamiquement)
      // Pour l'instant, fallback au backend
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _synthesizeViaBackend({required String text}) async {
    try {
      final res = await http.post(
        Uri.parse('http://localhost:8765/vocal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text, 'voice': _selectedVoice}),
      );
      if (res.statusCode != 200) return null;
      return res.bodyBytes;
    } catch (_) {
      return null;
    }
  }

  String _edgeVoiceName(String voice) {
    const voiceMap = {
      'denise': 'fr-FR-DeniseNeural',
      'henri': 'fr-FR-HenriNeural',
      'sylvie': 'fr-FR-SylvieNeural',
      'jacques': 'fr-FR-JacquesNeural',
      'vivienne': 'fr-FR-VivienneNeural',
      'mathieu': 'fr-FR-MathieuNeural',
      'celeste': 'fr-FR-CelesteNeural',
      'cécile': 'fr-FR-CecileNeural',
      'yvette': 'fr-FR-YvetteNeural',
      'ines': 'fr-FR-InesNeural',
      'elodie': 'fr-FR-ElodieNeural',
      'ariane': 'fr-FR-ArianeNeural',
      'djibril': 'fr-FR-DjibrilNeural',
    };
    return voiceMap[voice] ?? 'fr-FR-DeniseNeural';
  }

  String _generateConnectionId() {
    final chars = 'abcdef0123456789';
    final random = DateTime.now().microsecondsSinceEpoch;
    return List.generate(16, (i) => chars[(random >> (i * 4)) & 0xf]).join();
  }

  Uint8List? _combineAudioChunks(List<Uint8List> chunks) {
    if (chunks.isEmpty) return null;
    final totalLength = chunks.fold<int>(0, (sum, c) => sum + c.length);
    final combined = Uint8List(totalLength);
    var offset = 0;
    for (final chunk in chunks) {
      combined.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return combined;
  }

  Future<Uint8List?> synthesizeViaBackend({
    required String text,
    required String backendUrl,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$backendUrl/vocal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text, 'voice': _selectedVoice}),
      );
      if (res.statusCode != 200) return null;
      return res.bodyBytes;
    } catch (_) {
      return null;
    }
  }
}
