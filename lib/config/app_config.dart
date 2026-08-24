/// Constantes de configuration de l'application. Le backend reste le même
/// "brain" FastAPI que celui utilisé par la PWA — seule l'URL par défaut
/// change selon l'endroit où Alex tourne (PC local, serveur maison, etc.).
class AppConfig {
  AppConfig._();

  static const String appName = 'Alex';
  static const String defaultBackendUrl = 'http://localhost:8765';
  static const String defaultVoice = 'denise';
  static const String defaultLocale = 'fr_FR';

  // OpenCode — IA locale sur le port 4096
  static const String defaultOpenCodeUrl = 'http://localhost:4096';
  static const String defaultModel = 'mimo-v2.5-free';

  // 7 modèles gratuits disponibles
  static const List<String> freeModels = [
    'deepseek-v4-flash-free',
    'mimo-v2.5-free',
    'nemotron-3-ultra-free',
    'longcat-2.0-free',
    'ling-3.5-free',
    'gemini-3-flash-lite-preview-free',
    'mimo-v2-pro-free',
  ];

  static const Map<String, String> modelLabels = {
    'deepseek-v4-flash-free': 'DeepSeek V4 Flash',
    'mimo-v2.5-free': 'MiMo V2.5',
    'nemotron-3-ultra-free': 'Nemotron 3 Ultra',
    'longcat-2.0-free': 'LongCat 2.0',
    'ling-3.5-free': 'Ling 3.5',
    'gemini-3-flash-lite-preview-free': 'Gemini 3 Flash Lite',
    'mimo-v2-pro-free': 'MiMo V2 Pro',
  };

  // 13 voix Edge TTS (français)
  static const List<String> edgeVoices = [
    'denise', 'henri', 'sylvie', 'jacques', 'vivienne',
    'mathieu', 'celeste', 'cécile', 'yvette', 'ines',
    'elodie', 'ariane', 'djibril',
  ];

  static const Map<String, String> voiceLabels = {
    'denise': 'Denise (F)',
    'henri': 'Henri (H)',
    'sylvie': 'Sylvie (F)',
    'jacques': 'Jacques (H)',
    'vivienne': 'Vivienne (F)',
    'mathieu': 'Mathieu (H)',
    'celeste': 'Céleste (F)',
    'cécile': 'Cécile (F)',
    'yvette': 'Yvette (F)',
    'ines': 'Inès (F)',
    'elodie': 'Élodie (F)',
    'ariane': 'Ariane (F)',
    'djibril': 'Djibril (H)',
  };

  // Clés SharedPreferences
  static const String prefBackendUrl = 'alex_backend_url';
  static const String prefVoice = 'alex_voice';
  static const String prefVoiceEnabled = 'alex_voice_enabled';
  static const String prefModel = 'alex_model';
  static const String prefOpenCodeUrl = 'alex_opencode_url';
  static const String prefWakeWordEnabled = 'alex_wake_word_enabled';
}
