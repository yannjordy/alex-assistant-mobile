import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Client HTTP vers l'API OpenCode (port 4096) pour les 7 modèles gratuits.
/// Gère la santé du service, le routing de chat, et l'information sur les
/// modèles disponibles.
class OpenCodeService {
  OpenCodeService({String? baseUrl})
      : baseUrl = baseUrl ?? 'http://localhost:4096';

  String baseUrl;
  final http.Client _client = http.Client();

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  /// Vérifie si OpenCode est en ligne.
  Future<bool> checkHealth() async {
    try {
      final res =
          await _client.get(_uri('/health')).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Récupère la liste des modèles disponibles depuis OpenCode.
  Future<List<OpenCodeModel>> getModels() async {
    try {
      final res = await _client.get(_uri('/models'));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final list = data['models'] as List<dynamic>? ?? [];
      return list
          .map((e) => OpenCodeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Envoie un message au modèle choisi et retourne un flux SSE de type
  /// `ChatStreamEvent` compatible avec le format du brain d'Alex.
  Stream<OpenCodeStreamEvent> streamChat({
    required String message,
    required String model,
    String? conversationId,
  }) async* {
    final request = http.Request('POST', _uri('/chat'))
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'text/event-stream'
      ..body = jsonEncode({
        'message': message,
        'model': model,
        if (conversationId != null) 'cid': conversationId,
      });

    http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await _client.send(request);
    } catch (_) {
      yield OpenCodeStreamEvent.error(
          'Impossible de joindre OpenCode. Vérifie que le serveur tourne sur le port 4096.');
      return;
    }

    if (streamedResponse.statusCode != 200) {
      yield OpenCodeStreamEvent.error(
          'Erreur serveur OpenCode (${streamedResponse.statusCode}).');
      return;
    }

    var buffer = '';
    try {
      await for (final chunk
          in streamedResponse.stream.transform(utf8.decoder)) {
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
            yield OpenCodeStreamEvent.delta(payload);
            continue;
          }

          final event = _parseEvent(json);
          if (event != null) yield event;
        }
      }
    } catch (_) {
      yield OpenCodeStreamEvent.error('Connexion OpenCode interrompue.');
    }
  }

  OpenCodeStreamEvent? _parseEvent(Map<String, dynamic> json) {
    if (json.containsKey('error')) {
      return OpenCodeStreamEvent.error(json['error'].toString());
    }
    switch (json['type'] as String?) {
      case 'thinking':
        return OpenCodeStreamEvent.thinking(json['text'] as String? ?? '');
      case 'delta':
        return OpenCodeStreamEvent.delta(json['text'] as String? ?? '');
      case 'status':
        return OpenCodeStreamEvent.status(json['text'] as String? ?? '');
      default:
        return null;
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Modèle OpenCode disponible.
class OpenCodeModel {
  final String id;
  final String name;
  final bool available;

  const OpenCodeModel({
    required this.id,
    required this.name,
    this.available = true,
  });

  factory OpenCodeModel.fromJson(Map<String, dynamic> json) {
    return OpenCodeModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['id'] as String? ?? '',
      available: json['available'] as bool? ?? true,
    );
  }
}

enum OpenCodeStreamEventType { thinking, delta, status, error }

class OpenCodeStreamEvent {
  final OpenCodeStreamEventType type;
  final String? text;

  const OpenCodeStreamEvent._(this.type, [this.text]);

  factory OpenCodeStreamEvent.thinking(String text) =>
      OpenCodeStreamEvent._(OpenCodeStreamEventType.thinking, text);
  factory OpenCodeStreamEvent.delta(String text) =>
      OpenCodeStreamEvent._(OpenCodeStreamEventType.delta, text);
  factory OpenCodeStreamEvent.status(String text) =>
      OpenCodeStreamEvent._(OpenCodeStreamEventType.status, text);
  factory OpenCodeStreamEvent.error(String text) =>
      OpenCodeStreamEvent._(OpenCodeStreamEventType.error, text);
}
