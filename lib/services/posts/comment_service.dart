import '../api/api_service.dart';
import '../../ui/widgets/dialogs/error_dialog.dart';
import 'package:flutter/material.dart';

/// Servicio para gestionar comentarios en posts.
class CommentService {
  /// Crea un comentario en un post.
  /// 
  /// Parámetros:
  /// - [postId]: ID del post
  /// - [text]: Texto del comentario
  /// - [context]: BuildContext para mostrar diálogos de error si es necesario
  /// 
  /// Retorna true si el comentario fue creado exitosamente, false en caso contrario.
  static Future<bool> createComment(
    String postId,
    String text,
    BuildContext? context,
  ) async {
    if (text.trim().isEmpty) {
      if (context != null && context.mounted) {
        await ErrorDialog.show(
          context,
          title: 'Comentario vacío',
          message: 'El comentario no puede estar vacío.',
        );
      }
      return false;
    }

    try {
      final response = await ApiService.post(
        '/api/posts/$postId/comments',
        {
          'com_text': text.trim(),
        },
        requireAuth: true,
      );

      if (response.statusCode == 201) {
        // Comentario creado exitosamente
        return true;
      } else {
        // Error del servidor
        if (context != null && context.mounted) {
          await ErrorDialog.show(
            context,
            title: 'Error',
            message: 'Error al crear el comentario. Por favor, intenta nuevamente.',
          );
        }
        return false;
      }
    } catch (e) {
      if (context != null && context.mounted) {
        await ErrorDialog.show(
          context,
          title: 'Error de conexión',
          message: 'No se pudo crear el comentario. Verifica tu conexión a internet.',
        );
      }
      return false;
    }
  }

  /// Elimina un comentario de un post.
  /// Solo el autor del comentario puede eliminarlo.
  /// 
  /// Parámetros:
  /// - [postId]: ID del post
  /// - [commentId]: ID del comentario
  /// - [context]: BuildContext para mostrar diálogos de error si es necesario
  /// 
  /// Retorna true si el comentario fue eliminado exitosamente, false en caso contrario.
  static Future<bool> deleteComment(
    String postId,
    String commentId,
    BuildContext? context,
  ) async {
    try {
      final response = await ApiService.delete(
        '/api/posts/$postId/comments/$commentId',
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        // Comentario eliminado exitosamente
        return true;
      } else if (response.statusCode == 403) {
        // No tienes permiso para eliminar este comentario
        if (context != null && context.mounted) {
          await ErrorDialog.show(
            context,
            title: 'Permiso denegado',
            message: 'No tienes permiso para eliminar este comentario.',
          );
        }
        return false;
      } else if (response.statusCode == 404) {
        // Comentario no encontrado
        if (context != null && context.mounted) {
          await ErrorDialog.show(
            context,
            title: 'Comentario no encontrado',
            message: 'El comentario que intentas eliminar no existe.',
          );
        }
        return false;
      } else {
        // Error del servidor
        if (context != null && context.mounted) {
          await ErrorDialog.show(
            context,
            title: 'Error',
            message: 'Error al eliminar el comentario. Por favor, intenta nuevamente.',
          );
        }
        return false;
      }
    } catch (e) {
      if (context != null && context.mounted) {
        await ErrorDialog.show(
          context,
          title: 'Error de conexión',
          message: 'No se pudo eliminar el comentario. Verifica tu conexión a internet.',
        );
      }
      return false;
    }
  }
}

