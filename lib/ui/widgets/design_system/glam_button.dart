import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

class GlamButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final double? width;
  final double height;
  final bool isGhost;
  final List<Color>? gradientColors;

  const GlamButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.isGhost = false,
    this.icon,
    this.width,
    this.height = 56.0,
    this.gradientColors,
  });

  @override
  State<GlamButton> createState() => _GlamButtonState();
}

class _GlamButtonState extends State<GlamButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!_canInteract) return;
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (!_canInteract) return;
    _controller.reverse();
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    if (!_canInteract) return;
    _controller.reverse();
  }

  bool get _canInteract =>
      !widget.isLoading && !widget.isDisabled && widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    // Definir colores basado en estado
    final currentGradient = (widget.isDisabled || widget.onPressed == null)
        ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade500])
        : (widget.isGhost
              ? const LinearGradient(
                  colors: [Colors.transparent, Colors.transparent],
                )
              : (widget.gradientColors != null
                    ? LinearGradient(colors: widget.gradientColors!)
                    : AppGradients.primary));

    final shadowColor =
        (widget.isDisabled || widget.onPressed == null || widget.isGhost)
        ? Colors.transparent
        : AppColors.upsBlue.withOpacity(0.4);

    final border = widget.isGhost
        ? Border.all(color: Colors.white, width: 1.5)
        : null;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: currentGradient,
            borderRadius: BorderRadius.circular(16),
            border: border,
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: AppTypography.button.copyWith(
                          color:
                              Colors.white, // Ensure white text for ghost too
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
