import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para gestionar la configuración de la aplicación.
/// Maneja el almacenamiento y recuperación de la IP del servidor.
class AppConfigService {
  static const String _serverIpKey = 'server_ip';
  static const String _defaultServerIp = 'localhost';

  /// Obtiene la IP del servidor guardada.
  /// Retorna 'localhost' si no hay ninguna IP configurada.
  static Future<String> getServerIp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_serverIpKey) ?? _defaultServerIp;
    } catch (e) {
      return _defaultServerIp;
    }
  }

  /// Guarda la IP del servidor.
  /// Retorna true si se guardó correctamente, false en caso contrario.
  static Future<bool> setServerIp(String ip) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_serverIpKey, ip.trim());
    } catch (e) {
      return false;
    }
  }

  /// Obtiene la URL base completa del servidor (http://IP:8080).
  static Future<String> getBaseUrl() async {
    final ip = await getServerIp();
    // Si es localhost, mantenerlo así; si es una IP, usar http://
    if (ip == 'localhost' || ip == '127.0.0.1') {
      return 'http://localhost:8080';
    }
    return 'http://$ip:8080';
  }

  /// Valida si una IP tiene un formato válido.
  /// Acepta: localhost, 127.0.0.1, o formato IPv4 (xxx.xxx.xxx.xxx)
  static bool isValidIp(String ip) {
    if (ip.isEmpty) return false;
    
    final trimmedIp = ip.trim();
    
    // Permitir localhost
    if (trimmedIp.toLowerCase() == 'localhost') return true;
    
    // Permitir 127.0.0.1
    if (trimmedIp == '127.0.0.1') return true;
    
    // Validar formato IPv4 básico
    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (!ipRegex.hasMatch(trimmedIp)) return false;
    
    // Validar que cada octeto esté entre 0 y 255
    final parts = trimmedIp.split('.');
    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) {
        return false;
      }
    }
    
    return true;
  }
}

