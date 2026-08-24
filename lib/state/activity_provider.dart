import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/tools_models.dart';
import '../services/alex_api_service.dart';
import '../services/alex_socket_service.dart';

/// Terminal d'activité : charge `/activity` puis reste à jour en direct
/// grâce au WebSocket `/wake` (évènements `notification` et
/// `code_changed`, convertis en lignes d'activité).
class ActivityProvider extends ChangeNotifier {
  ActivityProvider({required AlexApiService api, required AlexSocketService socket})
      : _api = api,
        _socket = socket {
    _sub = _socket.events.listen(_onWakeEvent);
  }

  final AlexApiService _api;
  final AlexSocketService _socket;
  StreamSubscription<WakeEvent>? _sub;

  final List<ActivityEvent> events = [];
  bool isLoading = false;
  String? latestNotificationTitle;
  String? latestNotificationMessage;

  Future<void> refresh() async {
    isLoading = true;
    notifyListeners();
    final fetched = await _api.getActivity();
    events
      ..clear()
      ..addAll(fetched.reversed); // plus récent en premier
    isLoading = false;
    notifyListeners();
  }

  Future<void> clear() async {
    final ok = await _api.clearActivity();
    if (ok) {
      events.clear();
      notifyListeners();
    }
  }

  void _onWakeEvent(WakeEvent event) {
    switch (event.kind) {
      case WakeEventKind.notification:
        final title = event.raw['title'] as String? ?? '';
        final message = event.raw['message'] as String? ?? '';
        latestNotificationTitle = title;
        latestNotificationMessage = message;
        events.insert(
          0,
          ActivityEvent(
            time: DateTime.now().millisecondsSinceEpoch / 1000,
            level: 'info',
            message: '🔔 $title — $message',
            source: 'notification',
          ),
        );
        notifyListeners();
        break;
      case WakeEventKind.codeChanged:
        final path = event.raw['path'] as String? ?? '';
        events.insert(
          0,
          ActivityEvent(
            time: DateTime.now().millisecondsSinceEpoch / 1000,
            level: 'success',
            message: '📝 Code mis à jour — $path',
            source: 'code',
          ),
        );
        notifyListeners();
        break;
      case WakeEventKind.wake:
      case WakeEventKind.shapeChange:
      case WakeEventKind.other:
        break;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
