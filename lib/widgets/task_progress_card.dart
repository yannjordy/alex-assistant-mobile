import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../theme/app_colors.dart';
import '../theme/glass.dart';

/// Visualise la progression multi-étapes envoyée par l'évènement SSE
/// `task_progress` (ex : "Alex exécute 2 tâche(s)" avec une barre de
/// progression et le statut de chaque étape). La PWA d'origine recevait
/// cet évènement mais ne l'affichait jamais.
class TaskProgressCard extends StatelessWidget {
  const TaskProgressCard({super.key, required this.progress});

  final TaskProgress progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassPanel(
        borderRadius: 16,
        tintOpacity: 0.05,
        borderColor: AppColors.glassBorderStrong,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    progress.title,
                    style: const TextStyle(color: AppColors.amberSoft, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${progress.progress}%',
                  style: const TextStyle(color: AppColors.creamFaint, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.progress / 100,
                minHeight: 4,
                backgroundColor: AppColors.creamGhost,
                valueColor: const AlwaysStoppedAnimation(AppColors.amber),
              ),
            ),
            const SizedBox(height: 10),
            ...progress.steps.map((step) => _StepRow(step: step)),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});

  final TaskStep step;

  @override
  Widget build(BuildContext context) {
    Widget icon;
    Color textColor;
    switch (step.status) {
      case 'done':
        icon = const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.success);
        textColor = AppColors.creamDim;
        break;
      case 'active':
        icon = const SizedBox(
          width: 13,
          height: 13,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.amber),
        );
        textColor = AppColors.cream;
        break;
      default:
        icon = const Icon(Icons.circle_outlined, size: 13, color: AppColors.creamFaint);
        textColor = AppColors.creamFaint;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 16, child: icon),
          const SizedBox(width: 8),
          Expanded(
            child: Text(step.label, style: TextStyle(color: textColor, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}
