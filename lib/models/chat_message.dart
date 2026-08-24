import 'package:uuid/uuid.dart';

enum ChatRole { user, assistant }

/// Une étape d'exécution d'outil, telle qu'envoyée par l'évènement SSE
/// `task_progress` (ex : "Recherche web" — pending / active / done).
class TaskStep {
  final String label;
  final String status; // pending | active | done
  const TaskStep({required this.label, required this.status});
}

/// Progression d'une série d'outils exécutés par Alex pour répondre
/// (ex : "Alex exécute 2 tâche(s)", 40 %, étapes en cours).
class TaskProgress {
  final String title;
  final List<TaskStep> steps;
  final int progress; // 0-100
  final bool done;
  const TaskProgress({
    required this.title,
    required this.steps,
    required this.progress,
    this.done = false,
  });
}

/// Un message de la conversation affiché à l'écran. Les messages
/// "assistant" sont mutables pendant le streaming : leur contenu grandit
/// au fil des évènements SSE reçus du backend.
class ChatMessage {
  ChatMessage({
    String? id,
    required this.role,
    this.content = '',
    this.thinking,
    this.taskProgress,
    List<String>? imageUrls,
    this.isError = false,
    this.isStreaming = false,
    DateTime? timestamp,
  })  : id = id ?? Uuid().v4(),
        imageUrls = imageUrls ?? [],
        timestamp = timestamp ?? DateTime.now();

  final String id;
  final ChatRole role;
  String content;
  String? thinking;
  TaskProgress? taskProgress;
  final List<String> imageUrls;
  bool isError;
  bool isStreaming;
  final DateTime timestamp;

  bool get isEmpty =>
      content.trim().isEmpty &&
      (thinking == null || thinking!.trim().isEmpty) &&
      taskProgress == null &&
      imageUrls.isEmpty &&
      !isError;
}
