import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/glass.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    required this.onMenuTap,
    required this.onSettingsTap,
  });

  final VoidCallback onMenuTap;
  final VoidCallback onSettingsTap;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final connection = context.select<SettingsProvider, ConnectionStatus>((s) => s.connection);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: FloatingGlassPanel(
          borderRadius: 22,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: SizedBox(
            height: 46,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu_rounded, color: AppColors.creamDim),
                  onPressed: onMenuTap,
                  tooltip: 'Historique',
                ),
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('ALEX', style: AppTheme.wordmark()),
                        const SizedBox(width: 8),
                        _ConnectionDot(status: connection),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded, color: AppColors.creamDim),
                  onPressed: onSettingsTap,
                  tooltip: 'Réglages',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectionDot extends StatelessWidget {
  const _ConnectionDot({required this.status});

  final ConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.creamFaint;
    switch (status) {
      case ConnectionStatus.online:
        color = AppColors.success;
        break;
      case ConnectionStatus.offline:
        color = AppColors.error;
        break;
      case ConnectionStatus.checking:
      case ConnectionStatus.unknown:
        color = AppColors.creamFaint;
        break;
    }
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color.withOpacity(0.7), blurRadius: 6)],
      ),
    );
  }
}
