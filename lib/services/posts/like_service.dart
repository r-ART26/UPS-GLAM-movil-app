import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../auth/auth_service.dart';
import '../../ui/widgets/dialogs/error_dialog.dart';

/// Servicio para gestionar likes en posts.
class LikeService {
  /// Toggle like en un post (crea si no existe, elimina si existe).
  /// 
  /// Parámetros:
  /// - [postId]: ID del post
  /// - [context]: BuildContext para mostrar diálogos de error si es necesario
  /// 
  /// Retorna true si la operación fue exitosa, false en caso contrario.
  static Future<bool> toggleLike(String postId, BuildContext? context) async {
    try {
      final response = await ApiService.post(
        '/api/posts/$postId/likes',
        {},
        requireAuth: true,
      );

      if (response.statusCode == 201) {
        // Like creado o eliminado exitosamente
        return true;
      } else if (response.statusCode == 409) {
        // Ya existe el like (aunque esto no debería pasar con toggle)
        if (context != null && context.mounted) {
          await ErrorDialog.show(
            context,
            title: 'Error',
            message: 'Ya has dado like a esta publicación.',
          );
        }
        return false;
      } else {
        // Error del servidor
        if (context != null && context.mounted) {
          await ErrorDialog.show(
            context,
            title: 'Error',
            message: 'Error al procesar el like. Por favor, intenta nuevamente.',
          );
        }
        return false;
      }
    } catch (e) {
      if (context != null && context.mounted) {
        await ErrorDialog.show(
          context,
          title: 'Error de conexión',
          message: 'No se pudo procesar el like. Verifica tu conexión a internet.',
        );
      }
      return false;
    }
  }

  /// Verifica si el usuario actual ha dado like a un post.
  /// 
  /// Parámetros:
  /// - [postId]: ID del post
  /// 
  /// Retorna true si el usuario dio like, false en caso contrario.
  static Future<bool> hasUserLiked(String postId) async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) return false;

      // Consultar Firestore directamente para verificar si existe el like
      // Esto es más eficiente que hacer una petición HTTP
      final likeDoc = await FirebaseFirestore.instance
          .collection('Posts')
          .doc(postId)
          .collection('Likes')
          .doc(userId)
          .get();

      return likeDoc.exists;
    } catch (e) {
      return false;
    }
  }
}

