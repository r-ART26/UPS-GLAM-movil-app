import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

class GlamInput extends StatefulWidget {
  final String label;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  const GlamInput({
    super.key,
    required this.label,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.prefixIcon,
    this.errorText,
    this.onChanged,
    this.enabled = true,
    this.suffix,
  });

  final Widget? suffix;

  @override
  State<GlamInput> createState() => _GlamInputState();
}

class _GlamInputState extends State<GlamInput> {
  late final TextEditingController _controller;
  late final bool _usesExternalController;
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _usesExternalController = widget.controller != null;
    _controller = widget.controller ?? TextEditingController();
    _isObscured = widget.obscureText;
  }

  @override
  void dispose() {
    if (!_usesExternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _toggleObscure() {
    if (!widget.obscureText) return;
    setState(() {
      _isObscured = !_isObscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError =
        widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(
            widget.label,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
        ],

        Container(
          decoration: BoxDecoration(
            color: widget.enabled
                ? AppColors.glassWhite
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasError
                  ? AppColors.error
                  : (widget.enabled
                        ? AppColors.glassBorder
                        : Colors.transparent),
              width: hasError ? 1.5 : 1.0,
            ),
          ),
          child: TextField(
            controller: _controller,
            obscureText: _isObscured,
            keyboardType: widget.keyboardType,
            enabled: widget.enabled,
            style: AppTypography.body.copyWith(
              color: widget.enabled ? Colors.white : Colors.white54,
            ),
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: InputBorder.none,
              hintText: widget.hintText,
              hintStyle: AppTypography.body.copyWith(
                color: Colors.white.withOpacity(0.4),
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: widget.enabled ? Colors.white70 : Colors.white30,
                      size: 20,
                    )
                  : null,
              suffixIcon: widget.obscureText
                  ? IconButton(
                      onPressed: widget.enabled ? _toggleObscure : null,
                      icon: Icon(
                        _isObscured ? Icons.visibility_off : Icons.visibility,
                        color: widget.enabled ? Colors.white70 : Colors.white30,
                        size: 20,
                      ),
                    )
                  : widget.suffix,
            ),
          ),
        ),

        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.errorText!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
