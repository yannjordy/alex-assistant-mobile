import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/tools_models.dart';
import '../services/alex_api_service.dart';
import '../services/alex_socket_service.dart';

/// Journal des modifications de code faites par Alex (`GET /code/log`),
/// mis à jour en direct via le WebSocket `/wake` (évènement
/// `code_changed`) — sans avoir besoin de rafraîchir manuellement.
class CodeProvider extends ChangeNotifier {
  CodeProvider({required AlexApiService api, required AlexSocketService socket})
      : _api = api,
        _socket = socket {
    _sub = _socket.events.listen(_onWakeEvent);
  }

  final AlexApiService _api;
  final AlexSocketService _socket;
  StreamSubscription<WakeEvent>? _sub;

  final List<CodeLogEvent> events = [];
  bool isLoading = false;

  Future<void> refresh() async {
    isLoading = true;
    notifyListeners();
    final fetched = await _api.getCodeLog();
    events
      ..clear()
      ..addAll(fetched.reversed);
    isLoading = false;
    notifyListeners();
  }

  Future<({bool ok, String output})> runCode(CodeLogEvent event) {
    final code = event.new_ ?? '';
    return _api.runCode(code: code, lang: event.lang);
  }

  void _onWakeEvent(WakeEvent event) {
    if (event.kind != WakeEventKind.codeChanged) return;
    try {
      events.insert(0, CodeLogEvent.fromJson(event.raw));
      notifyListeners();
    } catch (_) {
      // évènement mal formé : ignoré
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
