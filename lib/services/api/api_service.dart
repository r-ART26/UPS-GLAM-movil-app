import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config_service.dart';
import '../auth/auth_service.dart';

/// Excepción lanzada cuando el token JWT está expirado o es inválido.
class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException(this.message);
  
  @override
  String toString() => message;
}

/// Servicio base para realizar peticiones HTTP al servidor Spring Boot.
/// Utiliza la IP configurada en AppConfigService.
class ApiService {
  /// Obtiene la URL base del servidor.
  static Future<String> get baseUrl => AppConfigService.getBaseUrl();

  /// Realiza una petición GET.
  /// 
  /// [endpoint] debe ser la ruta relativa (ej: '/api/posts')
  /// [requireAuth] indica si la petición requiere autenticación (default: auto-detecta)
  /// Retorna la respuesta HTTP o lanza una excepción.
  static Future<http.Response> get(
    String endpoint, {
    bool? requireAuth,
  }) async {
    final needsAuth = requireAuth ?? _requiresAuth(endpoint);
    final url = await _buildUrl(endpoint);
    final headers = await _buildHeaders(requireAuth: needsAuth);
    final response = await http.get(url, headers: headers);
    // Solo manejar errores de autenticación si la petición requiere auth
    if (needsAuth) {
      await handleAuthError(response);
    }
    return response;
  }

  /// Realiza una petición POST.
  /// 
  /// [endpoint] debe ser la ruta relativa (ej: '/api/auth/login')
  /// [body] es el cuerpo de la petición (será convertido a JSON)
  /// [requireAuth] indica si la petición requiere autenticación (default: auto-detecta)
  /// Retorna la respuesta HTTP o lanza una excepción.
  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool? requireAuth,
  }) async {
    final needsAuth = requireAuth ?? _requiresAuth(endpoint);
    final url = await _buildUrl(endpoint);
    final headers = await _buildHeaders(requireAuth: needsAuth);
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    // Solo manejar errores de autenticación si la petición requiere auth
    // Los endpoints de auth (/api/auth/*) pueden retornar 401 por credenciales inválidas
    if (needsAuth) {
      await handleAuthError(response);
    }
    return response;
  }

  /// Realiza una petición PUT.
  /// 
  /// [endpoint] debe ser la ruta relativa
  /// [body] es el cuerpo de la petición (será convertido a JSON)
  /// [requireAuth] indica si la petición requiere autenticación (default: auto-detecta)
  /// Retorna la respuesta HTTP o lanza una excepción.
  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool? requireAuth,
  }) async {
    final needsAuth = requireAuth ?? _requiresAuth(endpoint);
    final url = await _buildUrl(endpoint);
    final headers = await _buildHeaders(requireAuth: needsAuth);
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    // Solo manejar errores de autenticación si la petición requiere auth
    if (needsAuth) {
      await handleAuthError(response);
    }
    return response;
  }

  /// Realiza una petición DELETE.
  /// 
  /// [endpoint] debe ser la ruta relativa
  /// [requireAuth] indica si la petición requiere autenticación (default: auto-detecta)
  /// Retorna la respuesta HTTP o lanza una excepción.
  static Future<http.Response> delete(
    String endpoint, {
    bool? requireAuth,
  }) async {
    final needsAuth = requireAuth ?? _requiresAuth(endpoint);
    final url = await _buildUrl(endpoint);
    final headers = await _buildHeaders(requireAuth: needsAuth);
    final response = await http.delete(url, headers: headers);
    // Solo manejar errores de autenticación si la petición requiere auth
    if (needsAuth) {
      await handleAuthError(response);
    }
    return response;
  }

  /// Construye la URL completa a partir del endpoint.
  static Future<Uri> _buildUrl(String endpoint) async {
    final base = await baseUrl;
    // Asegurar que el endpoint comience con /
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('$base$path');
  }

  /// Construye los headers para las peticiones HTTP.
  /// Incluye el token JWT si [requireAuth] es true y el endpoint no es de autenticación.
  static Future<Map<String, String>> _buildHeaders({
    required bool requireAuth,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    // Si requiere autenticación, agregar token JWT
    if (requireAuth) {
      // Verificar si el token es válido antes de agregarlo
      final isValid = await AuthService.isTokenValid();
      if (!isValid) {
        final token = await AuthService.getToken();
        if (token != null && AuthService.isTokenExpired(token)) {
          // Token expirado
          await AuthService.deleteToken();
          throw TokenExpiredException('Token expirado. Por favor, inicia sesión nuevamente.');
        } else if (token == null) {
          // No hay token
          throw TokenExpiredException('No hay sesión activa. Por favor, inicia sesión.');
        }
      }

      final token = await AuthService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Maneja errores de autenticación en las respuestas.
  /// Si la respuesta es 401 o 403, elimina el token y lanza excepción.
  static Future<void> handleAuthError(http.Response response) async {
    if (response.statusCode == 401 || response.statusCode == 403) {
      await AuthService.deleteToken();
      throw TokenExpiredException('Sesión expirada. Por favor, inicia sesión nuevamente.');
    }
  }

  /// Verifica la conectividad con el servidor.
  /// Retorna true si el servidor responde, false en caso contrario.
  static Future<bool> checkConnection() async {
    try {
      final url = await baseUrl;
      
      // Intentar con el endpoint de health primero
      try {
        final response = await http
            .get(Uri.parse('$url/actuator/health'))
            .timeout(const Duration(seconds: 3));
        if (response.statusCode == 200) return true;
      } catch (e) {
        // Si falla, continuar con otros intentos
      }
      
      // Si no hay endpoint de health, intentar con raíz
      try {
        final response = await http
            .get(Uri.parse('$url/'))
            .timeout(const Duration(seconds: 3));
        // Cualquier respuesta < 500 indica que el servidor está activo
        return response.statusCode < 500;
      } catch (e) {
        // Si también falla, intentar con un endpoint de API conocido
        try {
          final response = await http
              .get(Uri.parse('$url/api/auth/login'))
              .timeout(const Duration(seconds: 3));
          // 405 Method Not Allowed o 400 Bad Request significa que el servidor está activo
          return response.statusCode == 405 || response.statusCode == 400;
        } catch (e) {
          return false;
        }
      }
    } catch (e) {
      return false;
    }
  }

  /// Verifica si un endpoint requiere autenticación.
  /// Los endpoints de autenticación (/api/auth/*) no requieren token.
  static bool _requiresAuth(String endpoint) {
    return !endpoint.startsWith('/api/auth/');
  }
}

