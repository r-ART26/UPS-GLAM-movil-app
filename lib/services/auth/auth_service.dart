import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para gestionar la autenticación y el token JWT.
class AuthService {
  static const String _tokenKey = 'jwt_token';

  /// Guarda el token JWT.
  /// Retorna true si se guardó correctamente, false en caso contrario.
  static Future<bool> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_tokenKey, token);
    } catch (e) {
      return false;
    }
  }

  /// Obtiene el token JWT guardado.
  /// Retorna null si no hay token guardado.
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Elimina el token JWT.
  /// Retorna true si se eliminó correctamente.
  static Future<bool> deleteToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_tokenKey);
    } catch (e) {
      return false;
    }
  }

  /// Verifica si hay un token guardado.
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Verifica si el token es válido (existe y no está expirado).
  static Future<bool> isTokenValid() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return false;
    }
    return !isTokenExpired(token);
  }

  /// Verifica si el token JWT está expirado.
  /// Retorna true si está expirado o si no se puede decodificar.
  static bool isTokenExpired(String token) {
    try {
      // JWT tiene formato: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) {
        return true; // Token inválido
      }

      // Decodificar el payload (segunda parte)
      final payload = parts[1];
      
      // Agregar padding si es necesario para base64
      String normalizedPayload = payload;
      final remainder = payload.length % 4;
      if (remainder > 0) {
        normalizedPayload += '=' * (4 - remainder);
      }

      // Decodificar base64
      final decodedBytes = base64Url.decode(normalizedPayload);
      final decodedString = utf8.decode(decodedBytes);
      final payloadMap = jsonDecode(decodedString) as Map<String, dynamic>;

      // Obtener el campo 'exp' (expiración en segundos desde epoch)
      final exp = payloadMap['exp'];
      if (exp == null) {
        return true; // No tiene campo de expiración
      }

      // Convertir a milisegundos y comparar con el tiempo actual
      final expirationTime = (exp as int) * 1000;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      // Si el tiempo actual es mayor que el de expiración, está expirado
      return currentTime >= expirationTime;
    } catch (e) {
      // Si hay error al decodificar, considerar el token como expirado
      return true;
    }
  }

  /// Obtiene información del token (útil para debugging).
  /// Retorna un mapa con información del payload o null si no se puede decodificar.
  static Map<String, dynamic>? getTokenPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      final payload = parts[1];
      String normalizedPayload = payload;
      final remainder = payload.length % 4;
      if (remainder > 0) {
        normalizedPayload += '=' * (4 - remainder);
      }

      final decodedBytes = base64Url.decode(normalizedPayload);
      final decodedString = utf8.decode(decodedBytes);
      return jsonDecode(decodedString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}

