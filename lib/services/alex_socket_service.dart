import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'alex_api_service.dart';

enum WakeEventKind { wake, notification, codeChanged, shapeChange, other }

class WakeEvent {
  final WakeEventKind kind;
  final Map<String, dynamic> raw;
  const WakeEvent(this.kind, this.raw);

  factory WakeEvent.fromJson(Map<String, dynamic> json) {
    switch (json['event'] as String?) {
      case 'wake':
        return WakeEvent(WakeEventKind.wake, json);
      case 'notification':
        return WakeEvent(WakeEventKind.notification, json);
      case 'code_changed':
        return WakeEvent(WakeEventKind.codeChanged, json);
      case 'shape_change':
        return WakeEvent(WakeEventKind.shapeChange, json);
      default:
        return WakeEvent(WakeEventKind.other, json);
    }
  }
}

/// Connexion persistante au WebSocket `/wake` du backend : c'est le canal
/// par lequel Alex pousse en direct les notifications, les changements de
/// code qu'elle vient d'écrire, et les changements de forme de l'orbe —
/// indépendamment de toute requête de chat en cours. Se reconnecte tout
/// seul si la connexion tombe.
class AlexSocketService {
  AlexSocketService(this._api);

  final AlexApiService _api;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _retryTimer;
  bool _disposed = false;

  final _controller = StreamController<WakeEvent>.broadcast();
  Stream<WakeEvent> get events => _controller.stream;

  void connect() {
    if (_disposed) return;
    _retryTimer?.cancel();
    try {
      final uri = Uri.parse('${_api.wsBaseUrl}/wake');
      _channel = WebSocketChannel.connect(uri);
      _subscription = _channel!.stream.listen(
        (message) {
          try {
            final json = jsonDecode(message as String) as Map<String, dynamic>;
            _controller.add(WakeEvent.fromJson(json));
          } catch (_) {
            // message non-JSON : ignoré
          }
        },
        onError: (_) => _scheduleReconnect(),
        onDone: () => _scheduleReconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 5), connect);
  }

  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _controller.close();
  }
}
