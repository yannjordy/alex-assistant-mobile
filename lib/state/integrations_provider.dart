import 'package:flutter/foundation.dart';

import '../models/tools_models.dart';
import '../services/alex_api_service.dart';

class IntegrationsProvider extends ChangeNotifier {
  IntegrationsProvider({required AlexApiService api}) : _api = api;

  final AlexApiService _api;

  List<IntegrationInfo> integrations = [];
  bool isLoading = false;

  Future<void> refresh() async {
    isLoading = true;
    notifyListeners();
    integrations = await _api.getIntegrations();
    isLoading = false;
    notifyListeners();
  }

  Future<({bool ok, String message})> connect({
    required String name,
    String token = '',
    String clientId = '',
    String clientSecret = '',
  }) async {
    final result = await _api.connectIntegration(
      name: name,
      token: token,
      clientId: clientId,
      clientSecret: clientSecret,
    );
    if (result.ok) await refresh();
    return result;
  }

  Future<void> disconnect(String name) async {
    await _api.disconnectIntegration(name);
    await refresh();
  }

  Future<String> execute({required String name, required String action}) {
    return _api.executeIntegrationAction(name: name, action: action);
  }
}
