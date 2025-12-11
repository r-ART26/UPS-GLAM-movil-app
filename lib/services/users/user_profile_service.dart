import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart'; // Para MediaType
import '../config/app_config_service.dart';
import '../auth/auth_service.dart';

class UserProfileService {
  static Future<String> get baseUrl => AppConfigService.getBaseUrl();

  static Future<Dio> _createDio() async {
    final dio = Dio();
    final base = await baseUrl;
    dio.options.baseUrl = base;
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);

    final token = await AuthService.getToken();
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
    return dio;
  }

  /// Actualiza el perfil coordinando las llamadas necesarias.
  static Future<void> updateProfile({
    required String name,
    required String bio,
    File? imageFile,
  }) async {
    // 1. Actualizar Biografía (y potentially nombre, pero lo estamos ignorando por ahora)
    // TODO: Si encontramos el endpoint de nombre, agregarlo aquí.
    await _updateBio(bio);

    // 2. Actualizar Foto (solo si se seleccionó una nueva)
    if (imageFile != null) {
      await _updatePhoto(imageFile);
    }
  }

  // --- Endpoints Específicos ---

  static Future<void> _updateBio(String bio) async {
    final dio = await _createDio();
    try {
      final response = await dio.patch(
        '/api/users/me/bio',
        data: {'usr_bio': bio},
        options: Options(contentType: Headers.jsonContentType),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Error al actualizar biografía: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      // Ignoramos si es un error menor, o lo rehusamos.
      throw Exception('Error actualizando biografía: ${e.message}');
    }
  }

  static Future<void> _updatePhoto(File imageFile) async {
    final dio = await _createDio();

    // Preparar archivo
    String fileName = imageFile.path.split('/').last;
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
        contentType: MediaType('image', 'jpeg'),
      ),
    });

    try {
      final response = await dio.patch(
        '/api/users/me/photo',
        data: formData,
        // Dio con FormData usa automáticamente multipart/form-data
      );

      if (response.statusCode != 200) {
        throw Exception('Error al actualizar foto: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Error actualizando foto: ${e.message}');
    }
  }
}
