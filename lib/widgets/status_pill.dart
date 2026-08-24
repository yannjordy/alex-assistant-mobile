import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/glass.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: FloatingGlassPanel(
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.amber),
            ),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(color: AppColors.creamDim, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}
