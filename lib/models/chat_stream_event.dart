import 'chat_message.dart';

/// Les types d'évènements réellement émis par `POST /chat/opencode`
/// côté backend. La PWA d'origine n'en gérait qu'une partie (thinking,
/// delta, status) et ignorait silencieusement `task_progress`, `image`
/// et `shape` : ce client les gère tous.
enum ChatEventType { thinking, delta, status, taskProgress, image, shape, error }

class ChatStreamEvent {
  final ChatEventType type;
  final String? text;
  final String? title;
  final List<TaskStep>? steps;
  final int? progress;
  final bool? done;
  final String? url;
  final String? shape;

  const ChatStreamEvent._({
    required this.type,
    this.text,
    this.title,
    this.steps,
    this.progress,
    this.done,
    this.url,
    this.shape,
  });

  factory ChatStreamEvent.thinking(String text) => ChatStreamEvent._(type: ChatEventType.thinking, text: text);

  factory ChatStreamEvent.delta(String text) => ChatStreamEvent._(type: ChatEventType.delta, text: text);

  factory ChatStreamEvent.status(String text) => ChatStreamEvent._(type: ChatEventType.status, text: text);

  factory ChatStreamEvent.taskProgress({
    required String title,
    required List<TaskStep> steps,
    required int progress,
    bool done = false,
  }) =>
      ChatStreamEvent._(
        type: ChatEventType.taskProgress,
        title: title,
        steps: steps,
        progress: progress,
        done: done,
      );

  factory ChatStreamEvent.image(String url) => ChatStreamEvent._(type: ChatEventType.image, url: url);

  factory ChatStreamEvent.shape(String shape) => ChatStreamEvent._(type: ChatEventType.shape, shape: shape);

  factory ChatStreamEvent.error(String message) => ChatStreamEvent._(type: ChatEventType.error, text: message);
}
