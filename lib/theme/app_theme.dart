import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final bodyText = GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.black,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: AppColors.amber,
        secondary: AppColors.amberSoft,
        surface: AppColors.black,
        error: AppColors.error,
      ),
      textTheme: bodyText.apply(
        bodyColor: AppColors.cream,
        displayColor: AppColors.cream,
      ),
      splashFactory: InkRipple.splashFactory,
      iconTheme: const IconThemeData(color: AppColors.creamDim),
      dividerColor: AppColors.glassBorder,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.amber,
        selectionColor: AppColors.amberDim,
        selectionHandleColor: AppColors.amber,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.amber,
        linearTrackColor: AppColors.creamGhost,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.amber : AppColors.creamDim,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.amberDim : AppColors.creamGhost,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1A1208),
        contentTextStyle: bodyText.bodyMedium?.copyWith(color: AppColors.cream),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  /// Titre élégant façon "ALEX" en en-tête — clin d'œil à la Cormorant
  /// Garamond utilisée par la PWA d'origine.
  static TextStyle wordmark({double fontSize = 19, Color color = AppColors.amberSoft}) {
    return GoogleFonts.cormorantGaramond(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: 3,
      color: color,
    );
  }

  static TextStyle serif({double fontSize = 16, FontWeight weight = FontWeight.w600, Color color = AppColors.cream}) {
    return GoogleFonts.cormorantGaramond(fontSize: fontSize, fontWeight: weight, color: color);
  }
}
