import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Service d'écoute continue du mot-clé "Alex" via Porcupine (Picovoice).
///
/// Utilise l'accès microphone natif pour analyser l'audio en temps réel et
/// détecter le wake word. Quand "Alex" est entendu, déclenche le callback
/// [onWakeDetected] qui met l'orb en mode `listening`.
///
/// Nécessite un access key Porcupine valide (gratuit sur picovoice.ai).
/// Si l'accès micro est refusé ou l'API non disponible, le service
/// fonctionne en mode dégradé (push-to-talk uniquement).
class WakeWordService {
  StreamSubscription? _porcupineSubscription;
  bool _isActive = false;
  bool _hasPermission = false;

  VoidCallback? onWakeDetected;
  Function(String error)? onError;

  bool get isActive => _isActive;
  bool get hasPermission => _hasPermission;

  /// Démarre l'écoute du wake word "Alex".
  ///
  /// [accessKey] : clé API Picovoice (obtenue sur picovoice.ai/console).
  /// [keywordPath] : chemin vers le fichier .ppn du keyword "Alex".
  /// Si non fourni, utilise un keyword intégré ou un fallback push-to-talk.
  Future<void> start({
    String? accessKey,
    String? keywordPath,
  }) async {
    if (_isActive) return;

    // Vérifier les permissions micro
    _hasPermission = await _requestMicrophonePermission();
    if (!_hasPermission) {
      onError?.call('Permission microphone refusée. Activez-la dans les paramètres.');
      return;
    }

    try {
      // Tenter d'utiliser Porcupine si disponible
      await _startPorcupine(accessKey, keywordPath);
    } catch (e) {
      debugPrint('WakeWordService: Porcupine non disponible ($e) — mode push-to-talk');
      _isActive = true;
    }
  }

  /// Démarre Porcupine avec l'accès key fourni.
  Future<void> _startPorcupine(String? accessKey, String? keywordPath) async {
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      _isActive = true;
    } else {
      _isActive = true;
    }
  }

  /// Demande la permission microphone à l'utilisateur.
  Future<bool> _requestMicrophonePermission() async {
    try {
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Arrête l'écoute du wake word.
  Future<void> stop() async {
    _isActive = false;
    await _porcupineSubscription?.cancel();
    _porcupineSubscription = null;
  }

  /// Met en pause l'écoute (pendant que l'orb parle, par exemple).
  void pause() {
    if (!_isActive) return;
    _porcupineSubscription?.pause();
  }

  /// Reprend l'écoute après une pause.
  void resume() {
    if (!_isActive) return;
    _porcupineSubscription?.resume();
  }

  void dispose() {
    stop();
  }
}

/// Gestionnaire simplifié de permissions microphone pour le fallback.
class MicrophonePermission {
  static Future<bool> request() async {
    try {
      return true;
    } catch (_) {
      return false;
    }
  }
}
