import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../state/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/glass.dart';

class VoicesScreen extends StatelessWidget {
  const VoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final currentVoice = settings.voice;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Voix Edge TTS', style: AppTheme.wordmark(fontSize: 16)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: AppConfig.edgeVoices.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final voiceId = AppConfig.edgeVoices[i];
          final label = AppConfig.voiceLabels[voiceId] ?? voiceId;
          final isSelected = voiceId == currentVoice;

          return GestureDetector(
            onTap: () => settings.setVoice(voiceId),
            child: GlassPanel(
              borderRadius: 14,
              tintOpacity: isSelected ? 0.08 : 0.03,
              borderOpacity: isSelected ? 0.25 : 0.06,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    voiceId == 'henri' || voiceId == 'jacques' || voiceId == 'mathieu' || voiceId == 'djibril'
                        ? Icons.person_rounded
                        : Icons.person_2_rounded,
                    color: isSelected ? AppColors.amber : AppColors.creamGhost,
                    size: 22,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? AppColors.cream : AppColors.creamDim,
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          voiceId,
                          style: const TextStyle(
                            color: AppColors.creamGhost,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, color: AppColors.amber, size: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
