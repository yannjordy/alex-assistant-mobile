import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/glass.dart';

const List<String> kQuickActions = [
  'Quelle heure est-il ?',
  'Résume mes dernières notes',
  'Trouve-moi une image inspirante',
  'Quel temps fait-il aujourd\'hui ?',
];

class QuickActionPills extends StatelessWidget {
  const QuickActionPills({super.key, required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: kQuickActions
          .map(
            (label) => GestureDetector(
              onTap: () => onTap(label),
              child: GlassPanel(
                borderRadius: 18,
                tintOpacity: 0.05,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Text(label, style: const TextStyle(color: AppColors.creamDim, fontSize: 13)),
              ),
            ),
          )
          .toList(),
    );
  }
}
