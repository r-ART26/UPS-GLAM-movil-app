import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// Campo de texto reutilizable para la aplicación.
///
/// Mejoras implementadas:
/// - Controlador interno si no se proporciona uno externo.
/// - Icono opcional a la izquierda (prefixIcon).
/// - Botón para mostrar/ocultar contraseña.
/// - Soporte para mostrar mensaje de error.
/// - Mantiene el estilo visual UPS ya definido.
///
/// NOTA:
/// Más adelante (Fase 1.3) el estilo se moverá al Theme global.
class TextInput extends StatefulWidget {
  final String label;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final String? errorText;

  const TextInput({
    super.key,
    required this.label,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.prefixIcon,
    this.errorText,
  });

  @override
  State<TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<TextInput> {
  late final TextEditingController _controller;
  late final bool _usesExternalController;
  late bool _isObscured;

  @override
  void initState() {
    super.initState();

    _usesExternalController = widget.controller != null;
    _controller = widget.controller ?? TextEditingController();

    // Si es contraseña → iniciar oculto
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
    final bool hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Etiqueta superior del campo
        Text(
          widget.label,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 6),

        /// Contenedor del campo con bordes dinámicos según error
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError
                  ? Colors.redAccent
                  : Colors.white.withValues(alpha: 0.25),
              width: hasError ? 1.6 : 1.0,
            ),
          ),
          child: TextField(
            controller: _controller,
            obscureText: _isObscured,
            keyboardType: widget.keyboardType,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

              border: InputBorder.none,

              /// HINT
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
              ),

              /// PREFIX ICON
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, color: Colors.white70)
                  : null,

              /// SUFFIX ICON (solo si es contraseña)
              suffixIcon: widget.obscureText
                  ? IconButton(
                onPressed: _toggleObscure,
                icon: Icon(
                  _isObscured ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                ),
              )
                  : null,

              /// Mostrar texto de error si existe
              errorText: widget.errorText,
              errorStyle: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                height: 1.2,
              ),
            ),
          ),
        ),

        /// Espaciado si hay error
        if (hasError) const SizedBox(height: 4),
      ],
    );
  }
}
