import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Servicio para gestionar la imagen original temporalmente.
/// Guarda la imagen en el directorio temporal del dispositivo.
class TempImageService {
  static const String _tempFileName = 'temp_original_image.jpg';
  static File? _cachedTempFile;

  /// Guarda la imagen original en el directorio temporal.
  /// Retorna el File guardado o null si hay error.
  static Future<File?> saveOriginalImage(File imageFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = path.join(tempDir.path, _tempFileName);
      
      // Copiar la imagen al directorio temporal
      final tempFile = await imageFile.copy(tempPath);
      _cachedTempFile = tempFile;
      
      return tempFile;
    } catch (e) {
      return null;
    }
  }

  /// Obtiene la imagen original guardada temporalmente.
  /// Retorna el File o null si no existe.
  static Future<File?> getOriginalImage() async {
    try {
      // Si ya tenemos el archivo en caché y existe, retornarlo
      if (_cachedTempFile != null && await _cachedTempFile!.exists()) {
        return _cachedTempFile;
      }

      final tempDir = await getTemporaryDirectory();
      final tempPath = path.join(tempDir.path, _tempFileName);
      final tempFile = File(tempPath);

      if (await tempFile.exists()) {
        _cachedTempFile = tempFile;
        return tempFile;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Elimina la imagen temporal guardada.
  /// Retorna true si se eliminó correctamente o no existía.
  static Future<bool> clearTempImage() async {
    try {
      // Limpiar caché
      _cachedTempFile = null;

      final tempDir = await getTemporaryDirectory();
      final tempPath = path.join(tempDir.path, _tempFileName);
      final tempFile = File(tempPath);

      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Verifica si existe una imagen temporal guardada.
  static Future<bool> hasTempImage() async {
    final image = await getOriginalImage();
    return image != null;
  }
}

