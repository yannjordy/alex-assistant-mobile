import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../state/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/glass.dart';

class ModelsScreen extends StatelessWidget {
  const ModelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final currentModel = settings.model ?? AppConfig.defaultModel;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Modèles IA', style: AppTheme.wordmark(fontSize: 16)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: AppConfig.freeModels.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final modelId = AppConfig.freeModels[i];
          final label = AppConfig.modelLabels[modelId] ?? modelId;
          final isSelected = modelId == currentModel;

          return GestureDetector(
            onTap: () => settings.setModel(modelId),
            child: GlassPanel(
              borderRadius: 14,
              tintOpacity: isSelected ? 0.08 : 0.03,
              borderOpacity: isSelected ? 0.25 : 0.06,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppColors.amber : AppColors.creamGhost,
                    ),
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
                          modelId,
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
