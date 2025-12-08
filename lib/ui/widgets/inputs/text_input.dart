import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// Campo de texto reutilizable para la aplicación.
/// Admite etiqueta, texto de ayuda, ocultar texto (contraseña)
/// y diferentes tipos de teclado.
class TextInput extends StatelessWidget {
  final String label;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextEditingController? controller;

  const TextInput({
    super.key,
    required this.label,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Etiqueta superior del campo
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 6),

        /// Campo de texto visualmente integrado con el estilo UPS
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.45),
              ),
            ),
          ),
        ),
      ],
    );
  }
}