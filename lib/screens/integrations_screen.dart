import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tools_models.dart';
import '../state/integrations_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/glass.dart';

class IntegrationsScreen extends StatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  State<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends State<IntegrationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<IntegrationsProvider>().refresh());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IntegrationsProvider>();

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Intégrations', style: AppTheme.wordmark(fontSize: 16)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.creamDim), onPressed: provider.refresh),
        ],
      ),
      body: provider.isLoading && provider.integrations.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2))
          : ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: provider.integrations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _IntegrationTile(integration: provider.integrations[i]),
            ),
    );
  }
}

class _IntegrationTile extends StatelessWidget {
  const _IntegrationTile({required this.integration});

  final IntegrationInfo integration;

  Color get _accent {
    try {
      final hex = integration.color.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: GlassPanel(
        borderRadius: 16,
        tintOpacity: 0.05,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: _accent.withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
              child: Text(integration.icon, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(integration.nameDisplay, style: const TextStyle(color: AppColors.cream, fontSize: 14.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    integration.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.creamFaint, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (integration.connected ? AppColors.success : AppColors.creamGhost).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                integration.connected ? 'Connecté' : 'Non connecté',
                style: TextStyle(color: integration.connected ? AppColors.success : AppColors.creamFaint, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _IntegrationDetailSheet(integration: integration),
    );
  }
}

class _IntegrationDetailSheet extends StatefulWidget {
  const _IntegrationDetailSheet({required this.integration});

  final IntegrationInfo integration;

  @override
  State<_IntegrationDetailSheet> createState() => _IntegrationDetailSheetState();
}

class _IntegrationDetailSheetState extends State<_IntegrationDetailSheet> {
  final _tokenController = TextEditingController();
  final _clientIdController = TextEditingController();
  final _clientSecretController = TextEditingController();
  bool _busy = false;
  String? _feedback;

  @override
  void dispose() {
    _tokenController.dispose();
    _clientIdController.dispose();
    _clientSecretController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _feedback = null;
    });
    final result = await context.read<IntegrationsProvider>().connect(
          name: widget.integration.name,
          token: _tokenController.text.trim(),
          clientId: _clientIdController.text.trim(),
          clientSecret: _clientSecretController.text.trim(),
        );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _feedback = result.message;
    });
    if (result.ok) Navigator.of(context).pop();
  }

  Future<void> _disconnect() async {
    setState(() => _busy = true);
    await context.read<IntegrationsProvider>().disconnect(widget.integration.name);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final integration = widget.integration;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
          child: GlassPanel(
            borderRadius: 22,
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(integration.icon, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Text(integration.nameDisplay, style: const TextStyle(color: AppColors.cream, fontSize: 17, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(integration.description, style: const TextStyle(color: AppColors.creamFaint, fontSize: 13)),
                const SizedBox(height: 18),
                if (integration.connected) ...[
                  const Text('Déjà connecté.', style: TextStyle(color: AppColors.success, fontSize: 13)),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _busy ? null : _disconnect,
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                      child: const Text('Déconnecter', style: TextStyle(color: AppColors.error)),
                    ),
                  ),
                ] else ...[
                  Text(
                    'Jeton d\'accès (si l\'intégration en utilise un) :',
                    style: const TextStyle(color: AppColors.creamFaint, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  _field(_tokenController, 'Token'),
                  const SizedBox(height: 10),
                  Text(
                    'Ou identifiants OAuth (si applicable) :',
                    style: const TextStyle(color: AppColors.creamFaint, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  _field(_clientIdController, 'Client ID'),
                  const SizedBox(height: 8),
                  _field(_clientSecretController, 'Client secret', obscure: true),
                  const SizedBox(height: 16),
                  if (_feedback != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(_feedback!, style: const TextStyle(color: AppColors.amberSoft, fontSize: 12.5)),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _connect,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: AppColors.black),
                      child: _busy
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.black))
                          : const Text('Connecter'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: AppColors.cream, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.creamFaint),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.glassBorder)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.amber)),
      ),
    );
  }
}
