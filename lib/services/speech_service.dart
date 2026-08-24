import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../config/app_config.dart';

/// Reconnaissance vocale sur l'appareil (moteur natif iOS/Android).
///
/// Dans la PWA d'origine, le bouton micro se contentait de demander la
/// permission du micro sans jamais transcrire quoi que ce soit — c'était
/// une fonctionnalité cassée. Ici, la parole est réellement transcrite en
/// direct et vient remplir le champ de saisie.
class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _available = false;
  bool get isListening => _speech.isListening;

  /// Initialise le moteur de reconnaissance (demande la permission au
  /// premier appel). Retourne `false` si le micro est indisponible ou
  /// refusé par l'utilisateur.
  Future<bool> init({void Function(String status)? onStatus, void Function(String error)? onError}) async {
    try {
      _available = await _speech.initialize(
        onStatus: (s) => onStatus?.call(s),
        onError: (e) => onError?.call(e.errorMsg),
      );
    } catch (_) {
      _available = false;
    }
    return _available;
  }

  /// Démarre l'écoute. `onResult` est appelé à chaque mise à jour de la
  /// transcription (résultats partiels puis final).
  Future<bool> startListening({
    required void Function(String text, bool isFinal) onResult,
  }) async {
    if (!_available) {
      final ok = await init();
      if (!ok) return false;
    }
    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      localeId: AppConfig.defaultLocale,
      listenFor: const Duration(seconds: 45),
      pauseFor: const Duration(seconds: 4),
      partialResults: true,
      cancelOnError: true,
    );
    return true;
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> cancel() async {
    if (_speech.isListening) {
      await _speech.cancel();
    }
  }
}
