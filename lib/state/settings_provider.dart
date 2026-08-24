import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/api_models.dart';
import '../services/alex_api_service.dart';

enum ConnectionStatus { unknown, checking, online, offline }

/// Réglages persistants de l'application (URL du backend, voix choisie,
/// modèle, activation des réponses vocales, wake word, OpenCode) + état
/// de connexion et informations récupérées du backend.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._api);

  final AlexApiService _api;

  String _backendUrl = AppConfig.defaultBackendUrl;
  String _voice = AppConfig.defaultVoice;
  bool _voiceEnabled = true;
  String _model = AppConfig.defaultModel;
  String _openCodeUrl = AppConfig.defaultOpenCodeUrl;
  bool _wakeWordEnabled = false;

  ConnectionStatus _connection = ConnectionStatus.unknown;
  ModelsInfo _models = ModelsInfo.empty;
  List<VoiceOption> _voices = [];
  MemoryInfo _memory = MemoryInfo.empty;
  bool _loadingBackendInfo = false;

  String get backendUrl => _backendUrl;
  String get voice => _voice;
  bool get voiceEnabled => _voiceEnabled;
  String get model => _model;
  String get openCodeUrl => _openCodeUrl;
  bool get wakeWordEnabled => _wakeWordEnabled;
  ConnectionStatus get connection => _connection;
  ModelsInfo get models => _models;
  List<VoiceOption> get voices => _voices;
  MemoryInfo get memory => _memory;
  bool get loadingBackendInfo => _loadingBackendInfo;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _backendUrl = prefs.getString(AppConfig.prefBackendUrl) ?? AppConfig.defaultBackendUrl;
    _voice = prefs.getString(AppConfig.prefVoice) ?? AppConfig.defaultVoice;
    _voiceEnabled = prefs.getBool(AppConfig.prefVoiceEnabled) ?? true;
    _model = prefs.getString(AppConfig.prefModel) ?? AppConfig.defaultModel;
    _openCodeUrl = prefs.getString(AppConfig.prefOpenCodeUrl) ?? AppConfig.defaultOpenCodeUrl;
    _wakeWordEnabled = prefs.getBool(AppConfig.prefWakeWordEnabled) ?? false;
    _api.baseUrl = _backendUrl;
    notifyListeners();
    unawaited(refreshBackendInfo());
  }

  Future<void> setBackendUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    _backendUrl = trimmed;
    _api.baseUrl = trimmed;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.prefBackendUrl, trimmed);
    await refreshBackendInfo();
  }

  Future<void> setVoice(String voiceId) async {
    _voice = voiceId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.prefVoice, voiceId);
  }

  Future<void> setVoiceEnabled(bool enabled) async {
    _voiceEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConfig.prefVoiceEnabled, enabled);
  }

  Future<void> setModel(String modelId) async {
    _model = modelId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.prefModel, modelId);
    await _api.setModel(modelId);
  }

  Future<void> setOpenCodeUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    _openCodeUrl = trimmed;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.prefOpenCodeUrl, trimmed);
  }

  Future<void> setWakeWordEnabled(bool enabled) async {
    _wakeWordEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConfig.prefWakeWordEnabled, enabled);
  }

  /// Vérifie la connexion et recharge modèles / voix / mémoire depuis le
  /// backend. Appelé au démarrage et après tout changement d'URL.
  Future<void> refreshBackendInfo() async {
    _connection = ConnectionStatus.checking;
    _loadingBackendInfo = true;
    notifyListeners();

    final health = await _api.checkHealth();
    _connection = health.ok ? ConnectionStatus.online : ConnectionStatus.offline;

    if (health.ok) {
      final results = await Future.wait([_api.getModels(), _api.getVoices(), _api.getMemory()]);
      _models = results[0] as ModelsInfo;
      _voices = results[1] as List<VoiceOption>;
      _memory = results[2] as MemoryInfo;
      if (_model.isEmpty && _models.current.isNotEmpty) {
        _model = _models.current;
      }
      if (_voices.isNotEmpty && !_voices.any((v) => v.id == _voice)) {
        _voice = _voices.first.id;
      }
    }

    _loadingBackendInfo = false;
    notifyListeners();
  }
}
