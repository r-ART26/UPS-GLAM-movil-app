import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// Gradientes reutilizables en la app.
class AppGradients {
  static const RadialGradient welcomeBackground = RadialGradient(
    center: Alignment(0, 0.4),
    radius: 1.2,
    colors: [
      AppColors.upsBlue,
      AppColors.upsBlueDark,
    ],
  );
}
