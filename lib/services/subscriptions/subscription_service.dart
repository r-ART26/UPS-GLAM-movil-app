import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../../models/user_model.dart';
import '../../ui/widgets/dialogs/error_dialog.dart';

/// Servicio para gestionar suscripciones (seguir/dejar de seguir).
/// Las acciones (POST/DELETE) van al backend, las lecturas (GET) son reactivas desde Firestore.
class SubscriptionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Suscribe al usuario actual a otro usuario (POST al backend).
  /// 
  /// Parámetros:
  /// - [userId]: ID del usuario al que se quiere seguir
  /// - [context]: BuildContext para mostrar diálogos de error
  /// 
  /// Retorna true si la operación fue exitosa, false en caso contrario.
  static Future<bool> subscribe(String userId, BuildContext? context) async {
    try {
      final response = await ApiService.post(
        '/api/users/$userId/subscribe',
        {},
        requireAuth: true,
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        if (context != null && context.mounted) {
          await ErrorDialog.show(
            context,
            title: 'Error',
            message: 'Error al seguir al usuario. Por favor, intenta nuevamente.',
          );
        }
        return false;
      }
    } catch (e) {
      if (context != null && context.mounted) {
        await ErrorDialog.show(
          context,
          title: 'Error de conexión',
          message: 'No se pudo seguir al usuario. Verifica tu conexión a internet.',
        );
      }
      return false;
    }
  }

  /// Desuscribe al usuario actual de otro usuario (DELETE al backend).
  /// 
  /// Parámetros:
  /// - [userId]: ID del usuario al que se quiere dejar de seguir
  /// - [context]: BuildContext para mostrar diálogos de error
  /// 
  /// Retorna true si la operación fue exitosa, false en caso contrario.
  static Future<bool> unsubscribe(String userId, BuildContext? context) async {
    try {
      final response = await ApiService.delete(
        '/api/users/$userId/subscribe',
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        if (context != null && context.mounted) {
          await ErrorDialog.show(
            context,
            title: 'Error',
            message: 'Error al dejar de seguir al usuario. Por favor, intenta nuevamente.',
          );
        }
        return false;
      }
    } catch (e) {
      if (context != null && context.mounted) {
        await ErrorDialog.show(
          context,
          title: 'Error de conexión',
          message: 'No se pudo dejar de seguir al usuario. Verifica tu conexión a internet.',
        );
      }
      return false;
    }
  }

  /// Stream reactivo para verificar si el usuario actual sigue a otro usuario.
  /// 
  /// Parámetros:
  /// - [currentUserId]: ID del usuario actual
  /// - [targetUserId]: ID del usuario objetivo
  /// 
  /// Retorna un Stream<bool> que indica si está suscrito.
  static Stream<bool> isSubscribedStream(String currentUserId, String targetUserId) {
    return _firestore
        .collection('Users')
        .doc(currentUserId)
        .collection('Following')
        .doc(targetUserId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Stream reactivo de usuarios que el usuario actual está siguiendo.
  /// 
  /// Parámetros:
  /// - [userId]: ID del usuario
  /// 
  /// Retorna un Stream<List<UserModel>> con los usuarios que sigue.
  static Stream<List<UserModel>> getFollowingStream(String userId) {
    return _firestore
        .collection('Users')
        .doc(userId)
        .collection('Following')
        .snapshots()
        .asyncMap((followingSnapshot) async {
      List<UserModel> followingUsers = [];

      for (var doc in followingSnapshot.docs) {
        String followingId = doc.id;

        // Obtener datos del usuario
        var userDoc = await _firestore
            .collection('Users')
            .doc(followingId)
            .get();

        if (userDoc.exists) {
          followingUsers.add(UserModel.fromFirestore(userDoc));
        }
      }

      return followingUsers;
    });
  }

  /// Stream reactivo de usuarios que siguen al usuario especificado.
  /// 
  /// Parámetros:
  /// - [userId]: ID del usuario
  /// 
  /// Retorna un Stream<List<UserModel>> con los seguidores.
  static Stream<List<UserModel>> getFollowersStream(String userId) {
    return _firestore
        .collection('Users')
        .doc(userId)
        .collection('Followers')
        .snapshots()
        .asyncMap((followersSnapshot) async {
      List<UserModel> followers = [];

      for (var doc in followersSnapshot.docs) {
        String followerId = doc.id;

        // Obtener datos del usuario
        var userDoc = await _firestore
            .collection('Users')
            .doc(followerId)
            .get();

        if (userDoc.exists) {
          followers.add(UserModel.fromFirestore(userDoc));
        }
      }

      return followers;
    });
  }

  /// Stream reactivo del contador de usuarios que el usuario está siguiendo.
  /// 
  /// Parámetros:
  /// - [userId]: ID del usuario
  /// 
  /// Retorna un Stream<int> con el contador.
  static Stream<int> getFollowingCountStream(String userId) {
    return _firestore
        .collection('Users')
        .doc(userId)
        .collection('Following')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Stream reactivo del contador de seguidores del usuario.
  /// 
  /// Parámetros:
  /// - [userId]: ID del usuario
  /// 
  /// Retorna un Stream<int> con el contador.
  static Stream<int> getFollowersCountStream(String userId) {
    return _firestore
        .collection('Users')
        .doc(userId)
        .collection('Followers')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}

