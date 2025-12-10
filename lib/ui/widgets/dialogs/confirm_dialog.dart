import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// Widget de diálogo para confirmaciones de forma elegante y consistente.
/// 
/// Características:
/// - Diseño moderno y bonito
/// - Botones de cancelar y confirmar
/// - Tamaño dinámico según la longitud del mensaje
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirmar',
    this.cancelText = 'Cancelar',
    this.confirmColor,
  });

  /// Muestra el diálogo de confirmación de forma estática desde cualquier contexto
  /// Retorna true si el usuario confirmó, false si canceló
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (BuildContext dialogContext) {
        return ConfirmDialog(
          title: title,
          message: message,
          confirmText: confirmText ?? 'Confirmar',
          cancelText: cancelText ?? 'Cancelar',
          confirmColor: confirmColor,
        );
      },
    );
    return result ?? false;
  }

  /// Calcula el tamaño del diálogo según la longitud del mensaje
  double _calculateMaxHeight(String message) {
    final length = message.length;
    if (length < 100) {
      return 300.0; // Mensaje corto
    } else if (length < 200) {
      return 360.0; // Mensaje medio
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
    final minHeight = messageLength < 100 ? 260.0 : 300.0;
    final confirmBtnColor = confirmColor ?? Colors.redAccent;

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
              AppColors.upsBlueDark,
              AppColors.upsBlueDark.withOpacity(0.95),
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
              color: confirmBtnColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
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
                    confirmBtnColor.withOpacity(0.2),
                    confirmBtnColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Icono de advertencia con efecto mejorado
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          confirmBtnColor.withOpacity(0.3),
                          confirmBtnColor.withOpacity(0.15),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: confirmBtnColor.withOpacity(0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: confirmBtnColor.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: confirmBtnColor,
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

            // Botones de acción
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  // Botón Cancelar
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          cancelText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Botón Confirmar
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: confirmBtnColor.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: confirmBtnColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            fontSize: 16,
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
          ],
        ),
      ),
    );
  }
}

