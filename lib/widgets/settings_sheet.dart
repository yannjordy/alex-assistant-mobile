import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/glass.dart';

Future<void> showSettingsSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late final TextEditingController _urlController;
  late final TextEditingController _openCodeUrlController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _urlController = TextEditingController(text: settings.backendUrl);
    _openCodeUrlController = TextEditingController(text: settings.openCodeUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _openCodeUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            decoration: BoxDecoration(
              color: AppColors.black.withOpacity(0.92),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.creamGhost,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('RÉGLAGES', style: AppTheme.wordmark(fontSize: 16)),
                    const SizedBox(height: 20),

                    _SectionLabel('Serveur'),
                    const SizedBox(height: 8),
                    GlassPanel(
                      borderRadius: 14,
                      tintOpacity: 0.05,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _urlController,
                              style: const TextStyle(color: AppColors.cream, fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: 'http://192.168.1.10:8765',
                                hintStyle: TextStyle(color: AppColors.creamFaint),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              onSubmitted: (v) => context.read<SettingsProvider>().setBackendUrl(v),
                            ),
                          ),
                          _ConnectionBadge(status: settings.connection),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, color: AppColors.amberSoft, size: 20),
                            onPressed: () => context.read<SettingsProvider>().setBackendUrl(_urlController.text),
                            tooltip: 'Tester la connexion',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),
                    _SectionLabel('Modèle'),
                    const SizedBox(height: 8),
                    _DropdownField<String>(
                      value: settings.models.models.contains(settings.model) ? settings.model : null,
                      hint: settings.loadingBackendInfo ? 'Chargement…' : 'Sélectionner un modèle',
                      items: settings.models.models,
                      onChanged: (v) {
                        if (v != null) context.read<SettingsProvider>().setModel(v);
                      },
                    ),

                    const SizedBox(height: 22),
                    _SectionLabel('Voix'),
                    const SizedBox(height: 8),
                    _DropdownField<String>(
                      value: settings.voices.any((v) => v.id == settings.voice) ? settings.voice : null,
                      hint: settings.loadingBackendInfo ? 'Chargement…' : 'Sélectionner une voix',
                      items: settings.voices.map((v) => v.id).toList(),
                      labelBuilder: (id) => settings.voices.firstWhere((v) => v.id == id).name,
                      onChanged: (v) {
                        if (v != null) context.read<SettingsProvider>().setVoice(v);
                      },
                    ),

                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: settings.voiceEnabled,
                      onChanged: (v) => context.read<SettingsProvider>().setVoiceEnabled(v),
                      title: const Text('Réponses vocales', style: TextStyle(color: AppColors.cream, fontSize: 14)),
                      subtitle: const Text(
                        'Alex lit ses réponses à voix haute',
                        style: TextStyle(color: AppColors.creamFaint, fontSize: 12),
                      ),
                    ),

                    const SizedBox(height: 18),
                    _SectionLabel('OpenCode (IA locale)'),
                    const SizedBox(height: 8),
                    GlassPanel(
                      borderRadius: 14,
                      tintOpacity: 0.05,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.psychology_rounded, color: AppColors.amberSoft, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _openCodeUrlController,
                              style: const TextStyle(color: AppColors.cream, fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: 'http://localhost:4096',
                                hintStyle: TextStyle(color: AppColors.creamFaint),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              onSubmitted: (v) => context.read<SettingsProvider>().setOpenCodeUrl(v),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    _SectionLabel('Écoute continue'),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: settings.wakeWordEnabled,
                      onChanged: (v) => context.read<SettingsProvider>().setWakeWordEnabled(v),
                      title: const Text('Wake word "Alex"', style: TextStyle(color: AppColors.cream, fontSize: 14)),
                      subtitle: const Text(
                        'Alex s\'active quand vous dites "Alex"',
                        style: TextStyle(color: AppColors.creamFaint, fontSize: 12),
                      ),
                    ),

                    const SizedBox(height: 18),
                    _SectionLabel('Mémoire'),
                    const SizedBox(height: 8),
                    GlassPanel(
                      borderRadius: 14,
                      tintOpacity: 0.05,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.memory_rounded, color: AppColors.amberSoft, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            'Niveau ${settings.memory.level} · ${settings.memory.factsCount} faits appris',
                            style: const TextStyle(color: AppColors.creamDim, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(color: AppColors.creamFaint, fontSize: 11.5, letterSpacing: 1.4, fontWeight: FontWeight.w600),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge({required this.status});
  final ConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    String label = '';
    Color color = AppColors.creamFaint;
    switch (status) {
      case ConnectionStatus.online:
        label = 'En ligne';
        color = AppColors.success;
        break;
      case ConnectionStatus.offline:
        label = 'Hors ligne';
        color = AppColors.error;
        break;
      case ConnectionStatus.checking:
        label = 'Test…';
        color = AppColors.amberSoft;
        break;
      case ConnectionStatus.unknown:
        label = '';
        color = AppColors.creamFaint;
        break;
    }
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11)),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.labelBuilder,
  });

  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final String Function(T)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: 14,
      tintOpacity: 0.05,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(hint ?? '', style: const TextStyle(color: AppColors.creamFaint, fontSize: 13.5)),
          dropdownColor: const Color(0xFF17110A),
          icon: const Icon(Icons.expand_more_rounded, color: AppColors.creamFaint),
          style: const TextStyle(color: AppColors.cream, fontSize: 13.5),
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(labelBuilder != null ? labelBuilder!(item) : item.toString()),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
