import 'package:flutter/material.dart';

/// Palette de marque d'Alex : noir profond + ambre, reprise de la PWA
/// d'origine et étendue pour un habillage "verre" (glassmorphism) 2026.
class AppColors {
  AppColors._();

  static const Color black = Color(0xFF000000);
  static const Color backgroundTop = Color(0xFF120B04);
  static const Color backgroundBottom = Color(0xFF000000);

  static const Color amber = Color(0xFFFF9D3D);
  static const Color amberSoft = Color(0xFFFFC98C);
  static const Color amberDim = Color(0x1FFF9D3D); // ~12 %

  static const Color cream = Color(0xFFFFF6EA);
  static const Color creamDim = Color(0xB3FFF6EA); // 70 %
  static const Color creamFaint = Color(0x66FFF6EA); // 40 %
  static const Color creamGhost = Color(0x33FFF6EA); // 20 %

  static const Color glassBorder = Color(0x1AFFFFFF); // blanc 10 %
  static const Color glassBorderStrong = Color(0x33FF9D3D); // ambre 20 %

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF5350);

  /// Dégradé de fond de l'écran principal : noir avec une lueur ambrée
  /// discrète qui rappelle l'orbe de la version PWA/desktop.
  static const RadialGradient ambientGlow = RadialGradient(
    center: Alignment(0, -0.2),
    radius: 1.1,
    colors: [Color(0xFF2A1608), Color(0xFF000000)],
    stops: [0.0, 1.0],
  );
}
