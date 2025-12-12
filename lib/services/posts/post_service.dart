import 'dart:io';
import 'package:dio/dio.dart';
import '../config/app_config_service.dart';
import '../auth/auth_service.dart';

/// Servicio para gestionar posts.
class PostService {
  /// Obtiene la URL base del servidor.
  static Future<String> get baseUrl => AppConfigService.getBaseUrl();

  /// Crea una instancia de Dio con configuración para multipart y autenticación.
  static Future<Dio> _createDio() async {
    final dio = Dio();
    final base = await baseUrl;
    dio.options.baseUrl = base;
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);

    // Agregar token JWT (requerido para crear posts)
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('No hay sesión activa. Por favor, inicia sesión.');
    }
    dio.options.headers['Authorization'] = 'Bearer $token';

    return dio;
  }

  /// Crea un nuevo post con imagen y descripción.
  /// 
  /// Parámetros:
  /// - [imageFile]: Archivo de imagen procesada a publicar
  /// - [caption]: Descripción del post
  /// 
  /// Retorna el mensaje de éxito del servidor.
  /// Lanza excepción si hay error.
  static Future<String> createPost(File imageFile, String caption) async {
    if (caption.trim().isEmpty) {
      throw Exception('La descripción no puede estar vacía.');
    }

    final dio = await _createDio();
    
    final formData = FormData.fromMap({
      'pos_image': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'post_image.jpg',
      ),
      'pos_caption': caption.trim(),
    });

    try {
      final response = await dio.post(
        '/api/posts',
        data: formData,
      );

      if (response.statusCode == 201) {
        return response.data.toString();
      } else {
        throw Exception('Error al crear el post: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        await AuthService.deleteToken();
        throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
      }
      throw Exception('Error al crear el post: ${e.message}');
    } catch (e) {
      throw Exception('Error al crear el post: $e');
    }
  }

  /// Elimina un post por ID (solo dueño).
  static Future<void> deletePost(String postId) async {
    final dio = await _createDio();

    try {
      final response = await dio.delete('/api/posts/$postId');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al eliminar el post: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        await AuthService.deleteToken();
        throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
      }
      throw Exception('Error al eliminar el post: ${e.message}');
    } catch (e) {
      throw Exception('Error al eliminar el post: $e');
    }
  }

  /// Actualiza solo la descripción/caption de un post (solo dueño).
  static Future<void> updateDescription(
    String postId,
    String newDescription,
  ) async {
    final trimmed = newDescription.trim();
    if (trimmed.isEmpty) {
      throw Exception('La descripción no puede estar vacía.');
    }

    final dio = await _createDio();

    try {
      final response = await dio.put(
        '/api/posts/$postId/description',
        data: {'pos_caption': trimmed},
      );

      if (response.statusCode != 200) {
        throw Exception('Error al actualizar la descripción: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        await AuthService.deleteToken();
        throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
      }
      throw Exception('Error al actualizar la descripción: ${e.message}');
    } catch (e) {
      throw Exception('Error al actualizar la descripción: $e');
    }
  }
}

