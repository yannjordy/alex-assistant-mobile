import '../models/api_models.dart';

/// Retire la mise en forme Markdown d'un texte avant de l'envoyer en
/// synthèse vocale (portage de `stripMdForTTS` côté PWA d'origine).
String stripMarkdownForSpeech(String input) {
  var text = input;
  text = text.replaceAll(RegExp(r'```[\s\S]*?```'), ' ');
  text = text.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m.group(1) ?? '');
  text = text.replaceAll(RegExp(r'\*+'), '');
  text = text.replaceAll(RegExp(r'[#_~|>]'), '');
  text = text.replaceAll(RegExp(r'^[ \t]*[-*+•]\s+', multiLine: true), '');
  text = text.replaceAll(RegExp(r'https?://\S+'), ' ');
  text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  try {
    text = text.replaceAll(RegExp(r'\p{Extended_Pictographic}', unicode: true), ' ');
  } catch (_) {
    // Échappements Unicode non supportés sur cette plateforme : on ignore.
  }
  return text.trim();
}

/// Un tour de conversation reconstruit pour l'historique : la question de
/// l'utilisateur, un aperçu de la réponse, et les messages complets.
class ConversationTurn {
  ConversationTurn({required this.question, required this.answerPreview, required this.messages});
  final String question;
  String answerPreview;
  final List<HistoryMessage> messages;
}

/// Regroupe la liste plate renvoyée par `/history` en tours de
/// conversation (même logique que `buildConversations` côté PWA), du
/// plus récent au plus ancien.
List<ConversationTurn> buildConversationTurns(List<HistoryMessage> messages) {
  final turns = <ConversationTurn>[];
  ConversationTurn? current;
  for (final m in messages) {
    if (m.role == 'user') {
      if (current != null) turns.add(current);
      current = ConversationTurn(question: m.content, answerPreview: '', messages: [m]);
    } else if (current != null) {
      current.messages.add(m);
      current.answerPreview = m.content.length > 140 ? m.content.substring(0, 140) : m.content;
    }
  }
  if (current != null) turns.add(current);
  return turns.reversed.toList();
}
