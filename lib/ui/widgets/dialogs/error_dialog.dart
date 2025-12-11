import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// Widget de diálogo para mostrar errores de forma elegante y consistente.
///
/// Características:
/// - Diseño moderno y bonito
/// - Botón de aceptar para cerrar
/// - Scroll automático si el mensaje es muy largo
/// - Tamaño dinámico según la longitud del mensaje
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;

  const ErrorDialog({super.key, required this.title, required this.message});

  /// Muestra el diálogo de error de forma estática desde cualquier contexto
  static Future<void> show(
    BuildContext context, {
    String? title,
    required String message,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (BuildContext dialogContext) {
        return ErrorDialog(title: title ?? 'Error', message: message);
      },
    );
  }

  /// Calcula el tamaño del diálogo según la longitud del mensaje
  double _calculateMaxHeight(String message) {
    final length = message.length;
    if (length < 100) {
      return 280.0; // Mensaje corto
    } else if (length < 200) {
      return 350.0; // Mensaje medio
    } else if (length < 400) {
      return 450.0; // Mensaje largo
    } else {
      return 550.0; // Mensaje muy largo
    }
  }

  @override
  Widget build(BuildContext context) {
    final messageLength = message.length;
    final isLongMessage = messageLength > 150;
    final maxHeight = _calculateMaxHeight(message);
    final minHeight = messageLength < 100 ? 240.0 : 280.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          minHeight: minHeight,
          maxWidth: 400,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.darkBackground,
              AppColors.darkBackground.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 30,
              offset: const Offset(0, 15),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.redAccent.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con icono y título
            Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.redAccent.withOpacity(0.2),
                    Colors.redAccent.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Icono de error con efecto mejorado
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.redAccent.withOpacity(0.3),
                          Colors.redAccent.withOpacity(0.15),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Título
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Contenido con scroll si es necesario
            Flexible(
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  24,
                  isLongMessage ? 20 : 24,
                  24,
                  isLongMessage ? 20 : 24,
                ),
                child: isLongMessage
                    ? Scrollbar(
                        thumbVisibility: true,
                        thickness: 4,
                        radius: const Radius.circular(2),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            message,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 15.5,
                              height: 1.6,
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          message,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 15.5,
                            height: 1.6,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
              ),
            ),

            // Botón de aceptar mejorado
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Aceptar',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
