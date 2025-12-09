import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../config/app_config_service.dart';
import '../auth/auth_service.dart';

/// Servicio para aplicar filtros de procesamiento de imágenes.
/// Todos los filtros se aplican sobre la imagen original.
class ImageProcessingService {
  /// Obtiene la URL base del servidor.
  static Future<String> get baseUrl => AppConfigService.getBaseUrl();

  /// Crea una instancia de Dio con configuración para multipart.
  static Future<Dio> _createDio() async {
    final dio = Dio();
    final base = await baseUrl;
    dio.options.baseUrl = base;
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);

    // Agregar token JWT si existe
    final token = await AuthService.getToken();
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }

    return dio;
  }

  /// Aplica el filtro Canny (detección de bordes).
  /// 
  /// Parámetros:
  /// - [imageFile]: Archivo de imagen original
  /// - [kernelSize]: Tamaño del kernel (default: 5)
  /// - [sigma]: Valor sigma (default: 1.4)
  /// - [lowThreshold]: Umbral bajo (opcional)
  /// - [highThreshold]: Umbral alto (opcional)
  /// - [useAuto]: Usar valores automáticos (default: false)
  /// 
  /// Retorna Uint8List con la imagen procesada en PNG.
  static Future<Uint8List> applyCanny(
    File imageFile, {
    int? kernelSize,
    double? sigma,
    String? lowThreshold,
    String? highThreshold,
    bool? useAuto,
  }) async {
    final dio = await _createDio();
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imageFile.path),
      if (kernelSize != null) 'kernel_size': kernelSize.toString(),
      if (sigma != null) 'sigma': sigma.toString(),
      if (lowThreshold != null) 'low_threshold': lowThreshold,
      if (highThreshold != null) 'high_threshold': highThreshold,
      if (useAuto != null) 'use_auto': useAuto.toString(),
    });

    final response = await dio.post(
      '/api/process/canny',
      data: formData,
      options: Options(responseType: ResponseType.bytes),
    );

    return Uint8List.fromList(response.data);
  }

  /// Aplica el filtro Gaussian (desenfoque gaussiano).
  static Future<Uint8List> applyGaussian(
    File imageFile, {
    int? kernelSize,
    double? sigma,
    bool? useAuto,
  }) async {
    final dio = await _createDio();
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imageFile.path),
      if (kernelSize != null) 'kernel_size': kernelSize.toString(),
      if (sigma != null) 'sigma': sigma.toString(),
      if (useAuto != null) 'use_auto': useAuto.toString(),
    });

    final response = await dio.post(
      '/api/process/gaussian',
      data: formData,
      options: Options(responseType: ResponseType.bytes),
    );

    return Uint8List.fromList(response.data);
  }

  /// Aplica el filtro Negative (negativo).
  static Future<Uint8List> applyNegative(File imageFile) async {
    final dio = await _createDio();
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imageFile.path),
    });

    final response = await dio.post(
      '/api/process/negative',
      data: formData,
      options: Options(responseType: ResponseType.bytes),
    );

    return Uint8List.fromList(response.data);
  }

  /// Aplica el filtro Emboss (relieve).
  static Future<Uint8List> applyEmboss(
    File imageFile, {
    int? kernelSize,
    int? biasValue,
    bool? useAuto,
  }) async {
    final dio = await _createDio();
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imageFile.path),
      if (kernelSize != null) 'kernel_size': kernelSize.toString(),
      if (biasValue != null) 'bias_value': biasValue.toString(),
      if (useAuto != null) 'use_auto': useAuto.toString(),
    });

    final response = await dio.post(
      '/api/process/emboss',
      data: formData,
      options: Options(responseType: ResponseType.bytes),
    );

    return Uint8List.fromList(response.data);
  }

  /// Aplica el filtro Watermark (marca de agua).
  static Future<Uint8List> applyWatermark(
    File imageFile, {
    double? scale,
    double? transparency,
    double? spacing,
  }) async {
    final dio = await _createDio();
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imageFile.path),
      if (scale != null) 'scale': scale.toString(),
      if (transparency != null) 'transparency': transparency.toString(),
      if (spacing != null) 'spacing': spacing.toString(),
    });

    final response = await dio.post(
      '/api/process/watermark',
      data: formData,
      options: Options(responseType: ResponseType.bytes),
    );

    return Uint8List.fromList(response.data);
  }

  /// Aplica el filtro Ripple (efecto ripple).
  static Future<Uint8List> applyRipple(
    File imageFile, {
    double? edgeThreshold,
    int? colorLevels,
    double? saturation,
  }) async {
    final dio = await _createDio();
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imageFile.path),
      if (edgeThreshold != null) 'edge_threshold': edgeThreshold.toString(),
      if (colorLevels != null) 'color_levels': colorLevels.toString(),
      if (saturation != null) 'saturation': saturation.toString(),
    });

    final response = await dio.post(
      '/api/process/ripple',
      data: formData,
      options: Options(responseType: ResponseType.bytes),
    );

    return Uint8List.fromList(response.data);
  }

  /// Aplica el filtro Collage.
  static Future<Uint8List> applyCollage(File imageFile) async {
    final dio = await _createDio();
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imageFile.path),
    });

    final response = await dio.post(
      '/api/process/collage',
      data: formData,
      options: Options(responseType: ResponseType.bytes),
    );

    return Uint8List.fromList(response.data);
  }
}

