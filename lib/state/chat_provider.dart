import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/api_models.dart';
import '../models/chat_message.dart';
import '../models/chat_stream_event.dart';
import '../services/alex_api_service.dart';
import '../services/alex_socket_service.dart';
import '../services/tts_queue_player.dart';
import '../utils/text_utils.dart';
import 'settings_provider.dart';

/// État "orbe" — reflète ce que fait Alex en ce moment, pour piloter
/// l'animation de l'orbe central.
enum AlexState {
  idle,
  thinking,
  speaking,
  listening,
  searching,
  systemSearch,
  systemLaunch,
}

/// Cœur de l'application : historique de la conversation affichée,
/// envoi des messages, consommation du flux SSE et déclenchement de la
/// synthèse vocale de la réponse.
class ChatProvider extends ChangeNotifier {
  ChatProvider({
    required AlexApiService api,
    required TtsQueuePlayer ttsPlayer,
    required SettingsProvider settings,
    AlexSocketService? socket,
  })  : _api = api,
        _tts = ttsPlayer,
        _settings = settings {
    _socketSub = socket?.events.listen(_onSocketEvent);
  }

  final AlexApiService _api;
  final TtsQueuePlayer _tts;
  final SettingsProvider _settings;
  StreamSubscription<WakeEvent>? _socketSub;

  final List<ChatMessage> messages = [];
  bool isStreaming = false;
  String? statusText;
  AlexState alexState = AlexState.idle;
  String? currentShape;
  Timer? _shapeTimer;

  String _conversationId = Uuid().v4();
  StreamSubscription<ChatStreamEvent>? _subscription;

  bool get hasMessages => messages.isNotEmpty;

  /// Envoie une photo + une question à `/vision/analyze-image` et insère
  /// l'échange dans la conversation, comme un message normal.
  Future<void> sendImageMessage({required String imageDataUrl, required String question}) async {
    if (isStreaming) return;

    final userMessage = ChatMessage(role: ChatRole.user, content: question, imageUrls: [imageDataUrl]);
    messages.add(userMessage);
    final assistantMessage = ChatMessage(role: ChatRole.assistant, content: '', isStreaming: true);
    messages.add(assistantMessage);

    isStreaming = true;
    alexState = AlexState.thinking;
    statusText = 'Alex regarde l\'image…';
    notifyListeners();

    final reply = await _api.analyzeImage(imageDataUrl: imageDataUrl, question: question);

    assistantMessage.content = reply;
    _finishStreaming(assistantMessage);
  }

  Future<void> sendMessage(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || isStreaming) return;

    messages.add(ChatMessage(role: ChatRole.user, content: text));
    final assistantMessage = ChatMessage(role: ChatRole.assistant, content: '', isStreaming: true);
    messages.add(assistantMessage);

    isStreaming = true;
    alexState = AlexState.thinking;
    statusText = 'Alex réfléchit…';
    notifyListeners();

    final buffer = StringBuffer();
    final thinkingBuffer = StringBuffer();

    _subscription = _api
        .streamChat(message: text, conversationId: _conversationId)
        .listen(
          (event) => _handleEvent(event, assistantMessage, buffer, thinkingBuffer),
          onError: (_) {
            assistantMessage.isError = true;
            assistantMessage.content = 'Alex est indisponible pour le moment.';
            _finishStreaming(assistantMessage);
          },
          onDone: () => _finishStreaming(assistantMessage),
          cancelOnError: true,
        );
  }

  void _handleEvent(
    ChatStreamEvent event,
    ChatMessage message,
    StringBuffer buffer,
    StringBuffer thinkingBuffer,
  ) {
    switch (event.type) {
      case ChatEventType.thinking:
        thinkingBuffer.write(event.text ?? '');
        message.thinking = thinkingBuffer.toString();
        alexState = AlexState.thinking;
        break;
      case ChatEventType.delta:
        buffer.write(event.text ?? '');
        message.content = buffer.toString();
        statusText = null;
        break;
      case ChatEventType.status:
        statusText = event.text;
        // Détection d'état système depuis le statut du backend
        final lowerStatus = (event.text ?? '').toLowerCase();
        if (lowerStatus.contains('recherche') || lowerStatus.contains('searching')) {
          alexState = AlexState.searching;
        } else if (lowerStatus.contains('système') || lowerStatus.contains('system')) {
          alexState = AlexState.systemSearch;
        } else if (lowerStatus.contains('lancement') || lowerStatus.contains('launch')) {
          alexState = AlexState.systemLaunch;
        }
        break;
      case ChatEventType.taskProgress:
        message.taskProgress = TaskProgress(
          title: event.title ?? '',
          steps: event.steps ?? const [],
          progress: event.progress ?? 0,
          done: event.done ?? false,
        );
        statusText = event.title;
        break;
      case ChatEventType.image:
        if (event.url != null && event.url!.isNotEmpty) {
          message.imageUrls.add(event.url!);
        }
        break;
      case ChatEventType.shape:
        // La forme envoyée par le backend (via set_shape tool)
        if (event.text != null && event.text!.isNotEmpty) {
          currentShape = event.text;
          notifyListeners();
          // Réinitialise la forme après 5 secondes (hold_ms par défaut)
          _shapeTimer?.cancel();
          _shapeTimer = Timer(const Duration(seconds: 5), () {
            currentShape = null;
            notifyListeners();
          });
        }
        break;
      case ChatEventType.error:
        message.isError = true;
        message.content = event.text ?? 'Une erreur est survenue.';
        break;
    }
    notifyListeners();
  }

  void _finishStreaming(ChatMessage message) {
    message.isStreaming = false;
    isStreaming = false;
    statusText = null;
    alexState = AlexState.idle;
    _subscription = null;
    notifyListeners();

    if (message.content.trim().isNotEmpty && !message.isError && _settings.voiceEnabled) {
      alexState = AlexState.speaking;
      notifyListeners();
      unawaited(
        _tts.enqueue(stripMarkdownForSpeech(message.content), voice: _settings.voice).then((_) {
          if (alexState == AlexState.speaking) {
            alexState = AlexState.idle;
            notifyListeners();
          }
        }),
      );
    }
  }

  /// Interrompt la génération en cours (équivalent de `stopAlex` côté PWA).
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    if (messages.isNotEmpty && messages.last.role == ChatRole.assistant) {
      messages.last.isStreaming = false;
    }
    isStreaming = false;
    statusText = null;
    alexState = AlexState.idle;
    await _tts.stop();
    notifyListeners();
  }

  void newChat() {
    messages.clear();
    _conversationId = Uuid().v4();
    notifyListeners();
  }

  Future<List<ConversationTurn>> loadHistoryTurns() async {
    final history = await _api.getHistory();
    return buildConversationTurns(history);
  }

  void openConversationTurn(ConversationTurn turn) {
    messages
      ..clear()
      ..addAll(turn.messages.map(
        (m) => ChatMessage(
          role: m.role == 'user' ? ChatRole.user : ChatRole.assistant,
          content: m.content,
        ),
      ));
    _conversationId = Uuid().v4();
    notifyListeners();
  }

  Future<bool> clearHistory() async {
    final ok = await _api.clearHistory();
    if (ok) newChat();
    return ok;
  }

  /// Gère les événements WebSocket (shape_change envoyé par le backend).
  void _onSocketEvent(WakeEvent event) {
    if (event.kind == WakeEventKind.shapeChange) {
      final shape = event.raw['shape'] as String?;
      final holdMs = (event.raw['hold_ms'] as num?)?.toInt() ?? 5000;
      if (shape != null && shape.isNotEmpty) {
        currentShape = shape;
        notifyListeners();
        _shapeTimer?.cancel();
        _shapeTimer = Timer(Duration(milliseconds: holdMs), () {
          currentShape = null;
          notifyListeners();
        });
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _socketSub?.cancel();
    _shapeTimer?.cancel();
    super.dispose();
  }
}
