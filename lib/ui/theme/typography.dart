import 'package:flutter/material.dart';
import 'colors.dart';

/// Estilos tipográficos reutilizables.
class AppTypography {
  static const TextStyle titleUPS = TextStyle(
    fontSize: 38,
    fontWeight: FontWeight.bold,
    color: AppColors.upsYellow,
  );

  static const TextStyle titleGlam = TextStyle(
    fontSize: 38,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w400,
    color: AppColors.textWhite,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    height: 1.4,
    color: AppColors.textGrayLight,
  );
}
