import '../auth/auth_service.dart';

/// Middleware para verificar autenticación antes de acceder a rutas protegidas.
class AuthMiddleware {
  /// Verifica si el usuario está autenticado (tiene token válido).
  /// Retorna true si está autenticado, false en caso contrario.
  static Future<bool> isAuthenticated() async {
    return await AuthService.isTokenValid();
  }

  /// Verifica si una ruta requiere autenticación.
  /// Las rutas bajo `/home/*` requieren autenticación.
  static bool requiresAuth(String location) {
    return location.startsWith('/home/');
  }

  /// Función de redirección para GoRouter.
  /// Si la ruta requiere autenticación y el usuario no está autenticado,
  /// redirige a `/login`.
  static Future<String?> redirect(String location) async {
    // Si la ruta requiere autenticación
    if (requiresAuth(location)) {
      // Verificar si el usuario está autenticado
      final isAuth = await isAuthenticated();
      if (!isAuth) {
        // Redirigir al login si no está autenticado
        return '/login';
      }
    }
    
    // Si está en login/register y ya está autenticado, redirigir al feed
    if ((location == '/login' || location == '/register' || location == '/welcome')) {
      final isAuth = await isAuthenticated();
      if (isAuth) {
        return '/home/feed';
      }
    }
    
    // No redirigir, permitir acceso
    return null;
  }
}

