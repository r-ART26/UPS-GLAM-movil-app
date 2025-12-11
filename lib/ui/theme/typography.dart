import 'package:flutter/material.dart';
import 'colors.dart';

/// Estilos tipográficos modernos y elegantes.
class AppTypography {
  // Título Grande (Ej: UPS Tagram)
  static const TextStyle titleUPS = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.0,
    color: AppColors.upsYellow,
    fontFamily: 'Roboto', // Fallback
  );

  static const TextStyle titleGlam = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w300, // Light para contraste elegante
    letterSpacing: 1.5,
    color: AppColors.textWhite,
  );

  // Headlines
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );

  // Body
  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.textGrayLight,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    color: AppColors.textGray,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textGray,
    height: 1.4,
  );

  // Buttons
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
    letterSpacing: 0.5,
  );
}
