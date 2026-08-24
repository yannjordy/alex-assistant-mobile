/// Un évènement du terminal d'activité (`GET /activity`), aussi reçu en
/// direct via le WebSocket `/wake` sous forme d'évènements `notification`
/// et `code_changed`.
class ActivityEvent {
  final double time;
  final String level; // cmd | info | success | warn | error
  final String message;
  final String source;

  const ActivityEvent({required this.time, required this.level, required this.message, required this.source});

  factory ActivityEvent.fromJson(Map<String, dynamic> json) => ActivityEvent(
        time: (json['t'] as num?)?.toDouble() ?? 0,
        level: json['level'] as String? ?? 'info',
        message: json['message'] as String? ?? '',
        source: json['source'] as String? ?? 'brain',
      );

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch((time * 1000).round());
}

/// Une entrée du journal de code (`GET /code/log`, ou reçue en direct via
/// l'évènement WebSocket `code_changed`) : le code qu'Alex a écrit ou
/// modifié, avant/après, avec le diff déjà calculé côté serveur.
class CodeLogEvent {
  final double time;
  final String path;
  final String diff;
  final bool ok;
  final String? old;
  final String? new_;
  final String lang;
  final String? source;

  const CodeLogEvent({
    required this.time,
    required this.path,
    required this.diff,
    required this.ok,
    this.old,
    this.new_,
    required this.lang,
    this.source,
  });

  factory CodeLogEvent.fromJson(Map<String, dynamic> json) => CodeLogEvent(
        time: (json['time'] as num?)?.toDouble() ?? 0,
        path: json['path'] as String? ?? '',
        diff: json['diff'] as String? ?? '',
        ok: json['ok'] as bool? ?? true,
        old: json['old'] as String?,
        new_: json['new'] as String?,
        lang: json['lang'] as String? ?? '',
        source: json['source'] as String?,
      );

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch((time * 1000).round());
  bool get isRunnable => lang == 'javascript' || lang == 'js' || lang == 'python' || lang == 'py';
}

/// Une intégration tierce telle que listée par `GET /integrations`.
class IntegrationInfo {
  final String name;
  final String nameDisplay;
  final String description;
  final String icon;
  final String color;
  final bool connected;
  final List<String> actions;

  const IntegrationInfo({
    required this.name,
    required this.nameDisplay,
    required this.description,
    required this.icon,
    required this.color,
    required this.connected,
    required this.actions,
  });

  factory IntegrationInfo.fromJson(Map<String, dynamic> json) => IntegrationInfo(
        name: json['name'] as String? ?? '',
        nameDisplay: json['name_display'] as String? ?? json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        icon: json['icon'] as String? ?? '🔌',
        color: json['color'] as String? ?? '#888888',
        connected: json['connected'] as bool? ?? false,
        actions: (json['actions'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      );
}

/// Un marqueur de la carte d'Alex (`GET /map/data`).
class MapMarkerData {
  final double lat;
  final double lng;
  final String label;
  final String color;

  const MapMarkerData({required this.lat, required this.lng, required this.label, required this.color});

  factory MapMarkerData.fromJson(Map<String, dynamic> json) => MapMarkerData(
        lat: (json['lat'] as num?)?.toDouble() ?? 0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0,
        label: json['label'] as String? ?? '',
        color: json['color'] as String? ?? '#ff9d3d',
      );
}
