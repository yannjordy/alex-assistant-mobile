import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/api_models.dart';
import '../models/chat_message.dart';
import '../models/chat_stream_event.dart';
import '../models/tools_models.dart';

/// Client HTTP vers le backend "brain" d'Alex (FastAPI). Reproduit les
/// routes utilisées par la PWA (`/chat/opencode`, `/history`, `/models`,
/// `/voices`, `/memory`, `/vocal`, `/health`) et va plus loin : le parsing
/// du flux SSE gère aussi `task_progress`, `image` et `shape`, que le
/// client web ignorait silencieusement. Complété avec vision, code,
/// carte, intégrations et activité — présents côté backend mais absents
/// (ou seulement partiels) côté PWA mobile.
class AlexApiService {
  AlexApiService({String? baseUrl}) : baseUrl = baseUrl ?? 'http://localhost:8765';

  String baseUrl;
  final http.Client _client = http.Client();

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  /// URL WebSocket équivalente à [baseUrl] (http→ws, https→wss), pour
  /// `AlexSocketService`.
  String get wsBaseUrl {
    if (baseUrl.startsWith('https://')) return 'wss://${baseUrl.substring(8)}';
    if (baseUrl.startsWith('http://')) return 'ws://${baseUrl.substring(7)}';
    return baseUrl;
  }

  Future<HealthStatus> checkHealth() async {
    try {
      final res = await _client.get(_uri('/health')).timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return HealthStatus.unknown;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return HealthStatus(
        ok: data['status'] == 'ok',
        model: data['model'] as String? ?? '',
        online: data['online'] as bool? ?? false,
      );
    } catch (_) {
      return HealthStatus.unknown;
    }
  }

  Future<List<HistoryMessage>> getHistory({int limit = 300}) async {
    try {
      final res = await _client.get(_uri('/history?limit=$limit'));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final list = data['messages'] as List<dynamic>? ?? [];
      return list.map((e) => HistoryMessage.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> clearHistory() async {
    try {
      final res = await _client.delete(_uri('/history'));
      if (res.statusCode != 200) return false;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['ok'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<ModelsInfo> getModels() async {
    try {
      final res = await _client.get(_uri('/models'));
      if (res.statusCode != 200) return ModelsInfo.empty;
      return ModelsInfo.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return ModelsInfo.empty;
    }
  }

  Future<bool> setModel(String model) async {
    try {
      final res = await _client.post(
        _uri('/model'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'model': model}),
      );
      if (res.statusCode != 200) return false;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['ok'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<List<VoiceOption>> getVoices() async {
    try {
      final res = await _client.get(_uri('/voices'));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final list = data['voices'] as List<dynamic>? ?? [];
      return list.map((e) => VoiceOption.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<MemoryInfo> getMemory() async {
    try {
      final res = await _client.get(_uri('/memory'));
      if (res.statusCode != 200) return MemoryInfo.empty;
      return MemoryInfo.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return MemoryInfo.empty;
    }
  }

  /// Récupère l'audio MP3 (Edge TTS) généré par le backend pour `text`.
  Future<Uint8List?> fetchSpeech({required String text, required String voice}) async {
    try {
      final res = await _client.post(
        _uri('/vocal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text, 'voice': voice}),
      );
      if (res.statusCode != 200) return null;
      return res.bodyBytes;
    } catch (_) {
      return null;
    }
  }

  /// Ouvre le flux SSE de `/chat/opencode` et transforme chaque bloc
  /// `data: {...}` en [ChatStreamEvent] typé. Le flux se termine dès la
  /// réception du marqueur `[DONE]`, exactement comme côté PWA.
  Stream<ChatStreamEvent> streamChat({
    required String message,
    required String conversationId,
    String mode = 'auto',
  }) async* {
    final request = http.Request('POST', _uri('/chat/opencode'))
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'text/event-stream'
      ..body = jsonEncode({'message': message, 'mode': mode, 'cid': conversationId});

    http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await _client.send(request);
    } catch (_) {
      yield ChatStreamEvent.error('Impossible de joindre le serveur Alex. Vérifie l\'URL dans les réglages.');
      return;
    }

    if (streamedResponse.statusCode != 200) {
      yield ChatStreamEvent.error('Erreur serveur (${streamedResponse.statusCode}).');
      return;
    }

    var buffer = '';
    try {
      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        buffer += chunk;
        final parts = buffer.split('\n\n');
        buffer = parts.isEmpty ? '' : parts.removeLast();

        for (final rawPart in parts) {
          final part = rawPart.trim();
          if (!part.startsWith('data:')) continue;
          final payload = part.substring(5).trim();
          if (payload == '[DONE]') return;

          Map<String, dynamic>? json;
          try {
            json = jsonDecode(payload) as Map<String, dynamic>;
          } catch (_) {
            // Le flux a renvoyé du texte brut au lieu de JSON : on le
            // traite comme un simple delta, comme le fait la PWA.
            yield ChatStreamEvent.delta(payload);
            continue;
          }

          final event = _parseEvent(json);
          if (event != null) yield event;
        }
      }
    } catch (_) {
      yield ChatStreamEvent.error('Connexion interrompue.');
    }
  }

  ChatStreamEvent? _parseEvent(Map<String, dynamic> json) {
    if (json.containsKey('error')) {
      return ChatStreamEvent.error(json['error'].toString());
    }
    if (json.containsKey('shape') && !json.containsKey('type')) {
      return ChatStreamEvent.shape(json['shape'].toString());
    }
    switch (json['type'] as String?) {
      case 'thinking':
        return ChatStreamEvent.thinking(json['text'] as String? ?? '');
      case 'delta':
        return ChatStreamEvent.delta(json['text'] as String? ?? '');
      case 'status':
        return ChatStreamEvent.status(json['text'] as String? ?? '');
      case 'task_progress':
        final steps = (json['steps'] as List<dynamic>? ?? [])
            .map((s) => TaskStep(
                  label: (s as Map<String, dynamic>)['label'] as String? ?? '',
                  status: s['status'] as String? ?? 'pending',
                ))
            .toList();
        return ChatStreamEvent.taskProgress(
          title: json['title'] as String? ?? '',
          steps: steps,
          progress: (json['progress'] as num?)?.toInt() ?? 0,
          done: json['done'] as bool? ?? false,
        );
      case 'image':
        return ChatStreamEvent.image(json['url'] as String? ?? '');
      default:
        return null;
    }
  }

  void dispose() {
    _client.close();
  }

  // ─── Vision ────────────────────────────────────────────────────────────

  /// Envoie une photo (`dataUrl` = `data:image/...;base64,...`) et une
  /// question à `/vision/analyze-image`. Réponse synchrone (pas de SSE).
  Future<String> analyzeImage({required String imageDataUrl, required String question}) async {
    try {
      final res = await _client
          .post(
            _uri('/vision/analyze-image'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'image': imageDataUrl, 'question': question}),
          )
          .timeout(const Duration(seconds: 60));
      if (res.statusCode != 200) return 'Erreur serveur lors de l\'analyse de l\'image.';
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['reply'] as String? ?? 'Je n\'ai rien trouvé à dire sur cette image.';
    } catch (_) {
      return 'Impossible de joindre Alex pour analyser cette image.';
    }
  }

  /// Envoie un contenu texte déjà extrait (ex. document) à
  /// `/vision/analyze-document`.
  Future<String> analyzeDocument({required String filename, required String content, required String question}) async {
    try {
      final res = await _client
          .post(
            _uri('/vision/analyze-document'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'filename': filename, 'content': content, 'question': question}),
          )
          .timeout(const Duration(seconds: 60));
      if (res.statusCode != 200) return 'Erreur serveur lors de l\'analyse du document.';
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['reply'] as String? ?? 'Je n\'ai rien trouvé à dire sur ce document.';
    } catch (_) {
      return 'Impossible de joindre Alex pour analyser ce document.';
    }
  }

  // ─── Activité ──────────────────────────────────────────────────────────

  Future<List<ActivityEvent>> getActivity({int limit = 120}) async {
    try {
      final res = await _client.get(_uri('/activity?limit=$limit'));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final list = data['events'] as List<dynamic>? ?? [];
      return list.map((e) => ActivityEvent.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> clearActivity() async {
    try {
      final res = await _client.post(_uri('/activity/clear'));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── Code ──────────────────────────────────────────────────────────────

  Future<List<CodeLogEvent>> getCodeLog({int limit = 30}) async {
    try {
      final res = await _client.get(_uri('/code/log?limit=$limit'));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final list = data['events'] as List<dynamic>? ?? [];
      return list.map((e) => CodeLogEvent.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Exécute `code` (JS ou Python) côté serveur, dans un bac à sable
  /// temporaire, et renvoie la sortie.
  Future<({bool ok, String output})> runCode({required String code, required String lang}) async {
    try {
      final res = await _client
          .post(
            _uri('/code/run'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'code': code, 'lang': lang}),
          )
          .timeout(const Duration(seconds: 20));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return (ok: data['ok'] as bool? ?? false, output: data['output'] as String? ?? '');
    } catch (_) {
      return (ok: false, output: 'Impossible de joindre le serveur.');
    }
  }

  // ─── Carte ─────────────────────────────────────────────────────────────

  Future<List<MapMarkerData>> getMapData() async {
    try {
      final res = await _client.get(_uri('/map/data'));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final list = data['markers'] as List<dynamic>? ?? [];
      return list.map((e) => MapMarkerData.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Intégrations ──────────────────────────────────────────────────────

  Future<List<IntegrationInfo>> getIntegrations() async {
    try {
      final res = await _client.get(_uri('/integrations'));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final list = data['integrations'] as List<dynamic>? ?? [];
      return list.map((e) => IntegrationInfo.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Connecte une intégration. Le backend ne précise pas si elle attend un
  /// jeton (`bearer`) ou une paire client_id/client_secret (`oauth2`) —
  /// on envoie ce que l'utilisateur a rempli et on laisse le backend
  /// valider.
  Future<({bool ok, String message})> connectIntegration({
    required String name,
    String token = '',
    String clientId = '',
    String clientSecret = '',
  }) async {
    try {
      final res = await _client.post(
        _uri('/integrations/$name/connect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'client_id': clientId, 'client_secret': clientSecret}),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) {
        return (ok: false, message: data['error'] as String? ?? 'Échec de la connexion.');
      }
      return (ok: data['ok'] as bool? ?? false, message: data['message'] as String? ?? '');
    } catch (_) {
      return (ok: false, message: 'Impossible de joindre le serveur.');
    }
  }

  Future<bool> disconnectIntegration(String name) async {
    try {
      final res = await _client.post(_uri('/integrations/$name/disconnect'));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<String> executeIntegrationAction({
    required String name,
    required String action,
    Map<String, dynamic> params = const {},
  }) async {
    try {
      final res = await _client.post(
        _uri('/integrations/$name/execute'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': action, 'params': params}),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) return data['error']?.toString() ?? 'Erreur lors de l\'exécution.';
      return data['result']?.toString() ?? 'Terminé.';
    } catch (_) {
      return 'Impossible de joindre le serveur.';
    }
  }
}
