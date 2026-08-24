import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/glass.dart';

/// Bulle repliable "🧠 Penser" — reprend le comportement de la PWA
/// (masqué par défaut, on déplie pour lire le raisonnement d'Alex).
class ThinkingChip extends StatefulWidget {
  const ThinkingChip({super.key, required this.text, this.isLive = false});

  final String text;
  final bool isLive;

  @override
  State<ThinkingChip> createState() => _ThinkingChipState();
}

class _ThinkingChipState extends State<ThinkingChip> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.text.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassPanel(
        borderRadius: 16,
        tintOpacity: 0.04,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🧠', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    widget.isLive ? 'Réflexion en cours…' : 'Réflexion',
                    style: const TextStyle(color: AppColors.creamFaint, fontSize: 12.5),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 16,
                    color: AppColors.creamFaint,
                  ),
                ],
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  widget.text,
                  style: const TextStyle(color: AppColors.creamFaint, fontSize: 12.5, height: 1.4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
