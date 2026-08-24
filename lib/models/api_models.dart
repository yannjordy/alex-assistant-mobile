/// Une voix TTS Edge disponible côté backend (`GET /voices`).
class VoiceOption {
  final String id;
  final String name;
  final String gender;
  final String lang;
  const VoiceOption({required this.id, required this.name, required this.gender, required this.lang});

  factory VoiceOption.fromJson(Map<String, dynamic> json) => VoiceOption(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        gender: json['gender'] as String? ?? '',
        lang: json['lang'] as String? ?? 'fr-FR',
      );
}

/// Liste des modèles LLM "free" disponibles et modèle actif (`GET /models`).
class ModelsInfo {
  final List<String> models;
  final String current;
  const ModelsInfo({required this.models, required this.current});

  factory ModelsInfo.fromJson(Map<String, dynamic> json) => ModelsInfo(
        models: (json['models'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        current: json['current'] as String? ?? '',
      );

  static const empty = ModelsInfo(models: [], current: '');
}

/// Résumé de la mémoire d'Alex (`GET /memory`).
class MemoryInfo {
  final int level;
  final int factsCount;
  final String today;
  const MemoryInfo({required this.level, required this.factsCount, required this.today});

  factory MemoryInfo.fromJson(Map<String, dynamic> json) => MemoryInfo(
        level: (json['level'] as num?)?.toInt() ?? 1,
        factsCount: (json['facts_count'] as num?)?.toInt() ?? 0,
        today: json['today']?.toString() ?? '',
      );

  static const empty = MemoryInfo(level: 1, factsCount: 0, today: '');
}

/// Un message brut tel que renvoyé par `GET /history`.
class HistoryMessage {
  final String role;
  final String content;
  final String createdAt;
  const HistoryMessage({required this.role, required this.content, required this.createdAt});

  factory HistoryMessage.fromJson(Map<String, dynamic> json) => HistoryMessage(
        role: json['role'] as String? ?? 'user',
        content: json['content'] as String? ?? '',
        createdAt: json['created_at']?.toString() ?? '',
      );
}

class HealthStatus {
  final bool ok;
  final String model;
  final bool online;
  const HealthStatus({required this.ok, required this.model, required this.online});

  static const unknown = HealthStatus(ok: false, model: '', online: false);
}
