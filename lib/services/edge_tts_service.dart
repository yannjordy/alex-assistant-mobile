import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Service Edge TTS direct — synthèse vocale via le WebSocket Edge TTS
/// de Microsoft (13 voix françaises). Pas besoin de clé API.
///
/// Alternative au backend `/vocal` pour une latence plus faible et
/// un fonctionnement hors ligne partiel (les modèles vocaux sont
/// téléchargés à la première utilisation).
class EdgeTtsService {
  static const _edgeTtsHost = 'speech.platform.bing.com';
  static const _edgeTtsPath = '/consumer/speech/synthesize/readaloud/edge/v1';

  String _selectedVoice = 'denise';
  String get selectedVoice => _selectedVoice;
  set selectedVoice(String voice) => _selectedVoice = voice;

  /// Convertit texte en audio MP3 via le WebSocket Edge TTS.
  Future<Uint8List?> synthesize(String text) async {
    try {
      final wsUrl = Uri.parse('wss://$_edgeTtsPath?TrustedClientToken=6A5AA1D4EAFF4E9FB37E23D68491D6F4&ConnectionId=${_generateConnectionId()}');

      final ws = await WebSocket.connect(wsUrl.toString());
      final completer = Completer<Uint8List?>();
      final audioChunks = <Uint8List>[];

      // Envoyer la config vocale
      ws.add(_buildConfigMessage(text));

      // Recevoir l'audio
      ws.listen(
        (data) {
          if (data is String) {
            // Réponse de config ou marker
            if (data.contains('Path:audio\r\n')) {
              final audioStart = data.indexOf('Path:audio\r\n') + 'Path:audio\r\n'.length;
              final audioData = data.substring(audioStart);
              if (audioData.isNotEmpty) {
                audioChunks.add(base64.decode(audioData));
              }
            }
          } else if (data is Uint8List) {
            audioChunks.add(data);
          }
        },
        onDone: () {
          final combined = _combineAudioChunks(audioChunks);
          if (!completer.isCompleted) {
            completer.complete(combined);
          }
        },
        onError: (e) {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
      );

      // Timeout de 30 secondes
      Timer(const Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          ws.close();
          completer.complete(null);
        }
      });

      return await completer.future;
    } catch (_) {
      return null;
    }
  }

  /// Construit le message de configuration WebSocket pour Edge TTS.
  String _buildConfigMessage(String text) {
    return '''
Content-Type:application/json; charset=utf-8\r\nPath:speech.config\r\n\r\n{"context":{"synthesis":{"audio":{"metadataOptions":{"sentenceBoundaryEnabled":"false","wordBoundaryEnabled":"false"},"outputFormat":"audio-24khz-96kbitrate-mono-mp3"}}},"synthesis":{"audio":"data:text/plain;base64,${base64.encode(utf8.encode(text))}","voice":"${_edgeVoiceName(_selectedVoice)}"}}''';
  }

  /// Mappe nos identifiants vocaux vers les noms Edge TTS complets.
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

  /// Fallback: utilise le backend /vocal si Edge TTS direct échoue.
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
