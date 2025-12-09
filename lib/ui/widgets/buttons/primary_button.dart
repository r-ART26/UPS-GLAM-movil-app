import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// Variantes del botón primario.
enum ButtonVariant { primary, secondary, ghost }

/// Botón institucional reutilizable para UPStagram.
/// Soporta:
/// - Estados: loading, disabled
/// - Variantes: primary, secondary, ghost
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final ButtonVariant variant;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.variant = ButtonVariant.primary,
  });

  /// Definir colores según variante y estado
  Color _backgroundColor() {
    if (isDisabled) return Colors.grey.shade400;

    switch (variant) {
      case ButtonVariant.secondary:
        return AppColors.upsBlue;
      case ButtonVariant.ghost:
        return Colors.transparent;
      case ButtonVariant.primary:
        return AppColors.upsYellow;
    }
  }

  Color _textColor() {
    if (isDisabled) return Colors.black38;

    switch (variant) {
      case ButtonVariant.secondary:
        return Colors.white;
      case ButtonVariant.ghost:
        return Colors.white;
      case ButtonVariant.primary:
        return Colors.black87;
    }
  }

  BoxBorder? _border() {
    if (variant == ButtonVariant.ghost) {
      return Border.all(color: Colors.white, width: 1.4);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool canInteract = !isDisabled && !isLoading;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: _backgroundColor(),
        borderRadius: BorderRadius.circular(28),
        border: _border(),
        boxShadow: [
          if (variant != ButtonVariant.ghost)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: canInteract ? onPressed : null,
          child: Center(
            child: isLoading
                ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(_textColor()),
              ),
            )
                : Text(
              label,
              style: TextStyle(
                color: _textColor(),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
