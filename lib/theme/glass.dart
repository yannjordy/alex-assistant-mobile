import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Panneau "verre dépoli" réutilisable : flou d'arrière-plan + léger
/// dégradé translucide + bordure fine + ombre portée douce.
///
/// C'est la brique de base de tout l'habillage "pro 2026, transparent et
/// glass" : barre d'app, bulles de message, tiroir d'historique, feuille
/// de réglages et lecteur média en héritent tous.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.blur = 22,
    this.tint = AppColors.cream,
    this.tintOpacity = 0.06,
    this.borderColor,
    this.borderOpacity,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  final Widget child;
  final double borderRadius;
  final double blur;
  final Color tint;
  final double tintOpacity;
  final Color? borderColor;
  final double? borderOpacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tint.withOpacity(tintOpacity + 0.03),
                  tint.withOpacity(tintOpacity * 0.45),
                ],
              ),
              border: Border.all(
                color: borderColor != null
                    ? borderColor!.withOpacity(borderOpacity ?? 1.0)
                    : AppColors.glassBorder,
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Variante utilisée pour les éléments flottants (barre de saisie, barre
/// d'app, pastille de statut) : ajoute une ombre portée pour détacher le
/// panneau du fond, en plus du flou.
class FloatingGlassPanel extends StatelessWidget {
  const FloatingGlassPanel({
    super.key,
    required this.child,
    this.borderRadius = 28,
    this.blur = 26,
    this.tint = AppColors.cream,
    this.tintOpacity = 0.08,
    this.borderColor,
    this.padding,
    this.margin,
  });

  final Widget child;
  final double borderRadius;
  final double blur;
  final Color tint;
  final double tintOpacity;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: GlassPanel(
        borderRadius: borderRadius,
        blur: blur,
        tint: tint,
        tintOpacity: tintOpacity,
        borderColor: borderColor,
        padding: padding,
        child: child,
      ),
    );
  }
}
