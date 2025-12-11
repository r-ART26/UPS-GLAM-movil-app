import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

/// Tema global actualizado para Flutter 3.19+
/// Usando surface/onSurface y WidgetStateProperty.
class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.upsYellow,
      onPrimary: Colors.black,
      secondary: AppColors.upsBlue,
      onSecondary: Colors.white,
      error: Colors.redAccent,
      onError: Colors.white,

      // Reemplazo moderno de background/onBackground
      surface: AppColors.darkBackground,
      onSurface: Colors.white,

      // Para compatibilidad, Flutter genera automáticamente:
      // background / onBackground basados en surface / onSurface
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      // Ahora se usa surface como fondo de Scaffold
      scaffoldBackgroundColor: colorScheme.surface,

      textTheme: TextTheme(
        headlineLarge: AppTypography.titleUPS,
        headlineMedium: AppTypography.titleGlam,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.h2,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.upsYellow, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
        ),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
        labelStyle: const TextStyle(color: Colors.white),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size.fromHeight(56)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
