import 'package:flutter/material.dart';

/// Colores institucionales y Premium para la nueva UI.
class AppColors {
  // === BRAND COLORS ===
  // Azul oscuro profundo (Casi negro, para fondos)
  static const Color darkBackground = Color(0xFF0F172A);

  // Azul UPS principal (Más vibrante)
  static const Color upsBlue = Color(0xFF003F87);

  // Azul secundario (Para gradientes)
  static const Color upsBlueLight = Color(0xFF0066CC);

  // Amarillo UPS (Dorado Premium)
  static const Color upsYellow = Color(0xFFFFD700);

  // === FUNCTIONAL COLORS ===
  static const Color error = Color(0xFFFF4848);
  static const Color success = Color(0xFF00E676);

  // === TEXT COLORS ===
  static const Color textWhite = Colors.white;
  static const Color textGray = Color(0xFFB0B0C0);
  static const Color textGrayLight = Color(0xFFE0E0E0);

  // === UI ELEMENTS ===
  static const Color glassWhite = Color(0x1AFFFFFF); // 10% White for glass
  static const Color glassBorder = Color(0x33FFFFFF); // 20% White for borders
}

/// Gradientes Globales
class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.upsBlue, AppColors.upsBlueLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkBackground = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient gold = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradiente radial para el fondo (Estilo antiguo conservado por si acaso o para Welcome)
  static const RadialGradient welcomeBackground = RadialGradient(
    center: Alignment(0, 0.4),
    radius: 1.2,
    colors: [
      AppColors.upsBlue,
      Color(
        0xFF002B5C,
      ), // Darker UPS Blue manually defined here or use darkBackground
    ],
  );
}
