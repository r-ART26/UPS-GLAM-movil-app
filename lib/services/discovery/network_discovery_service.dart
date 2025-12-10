import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import '../config/app_config_service.dart';

/// Servicio para descubrir servidores Spring Boot en la red local.
/// Versión optimizada que detecta múltiples interfaces de red y escanea en paralelo.
class NetworkDiscoveryService {
  static const int _port = 8080;
  static const Duration _timeout = Duration(seconds: 3); // Reducido porque usamos HEAD request
  static const int _maxConcurrent = 50; // Aumentado para mejor paralelismo

  /// Descubre servidores Spring Boot en la red local.
  /// Retorna una lista de IPs de servidores encontrados.
  static Future<List<String>> discoverServers() async {
    try {
      print('[DISCOVERY] Iniciando descubrimiento de servidores...');
      
      // Obtener IP guardada (si existe) para incluir su rango
      final savedIp = await AppConfigService.getServerIp();
      print('[DISCOVERY] IP guardada: $savedIp');
      
      // Obtener todas las IPs locales (múltiples interfaces)
      final localIps = await _getAllLocalIps();
      print('[DISCOVERY] IPs locales detectadas: $localIps');
      
      // Calcular todos los rangos de red únicos
      final networkRanges = <String, List<String>>{};
      
      // 1. Agregar rango de la IP guardada (si existe y es válida)
      if (savedIp.isNotEmpty && 
          savedIp != 'localhost' && 
          savedIp != '127.0.0.1' &&
          AppConfigService.isValidIp(savedIp)) {
        final savedRange = _calculateNetworkRange(savedIp);
        if (savedRange != null && savedRange.isNotEmpty) {
          final savedPrefix = _getNetworkPrefix(savedIp);
          if (savedPrefix != null) {
            networkRanges[savedPrefix] = savedRange;
            print('[DISCOVERY] Rango de IP guardada ($savedIp): ${savedPrefix}1-254 (${savedRange.length} IPs)');
          }
        }
      }
      
      // 2. Agregar rangos de IPs locales detectadas
      for (final localIp in localIps) {
        final range = _calculateNetworkRange(localIp);
        if (range != null && range.isNotEmpty) {
          final networkPrefix = _getNetworkPrefix(localIp);
          if (networkPrefix != null && !networkRanges.containsKey(networkPrefix)) {
            networkRanges[networkPrefix] = range;
            print('[DISCOVERY] Rango calculado para $localIp: ${networkPrefix}1-254 (${range.length} IPs)');
          }
        }
      }

      // 3. Agregar rangos comunes adicionales (solo si no están ya incluidos)
      final commonRanges = [
        '192.168.1.',
        '192.168.0.',
        '10.0.0.',
        '10.73.253.', // Rango específico del servidor mencionado
        '172.16.0.',
      ];
      
      for (final prefix in commonRanges) {
        if (!networkRanges.containsKey(prefix)) {
          final range = <String>[];
          // Para rangos comunes, escanear más IPs (1-100)
          for (int i = 1; i <= 100; i++) {
            range.add('$prefix$i');
          }
          networkRanges[prefix] = range;
          print('[DISCOVERY] Rango común agregado: ${prefix}1-100 (${range.length} IPs)');
        }
      }

      // Combinar todos los rangos en una sola lista (sin duplicados)
      final allIps = <String>{};
      for (final range in networkRanges.values) {
        allIps.addAll(range);
      }

      print('[DISCOVERY] Total de IPs a escanear: ${allIps.length}');
      print('[DISCOVERY] Rangos únicos: ${networkRanges.keys.toList()}');

      if (allIps.isEmpty) {
        print('[DISCOVERY] ERROR: No hay IPs para escanear');
        return [];
      }

      // Si hay una IP guardada válida, verificar primero esa IP específica (más rápido)
      if (savedIp.isNotEmpty && 
          savedIp != 'localhost' && 
          savedIp != '127.0.0.1' &&
          AppConfigService.isValidIp(savedIp) &&
          !savedIp.contains('localhost')) {
        print('[DISCOVERY] Verificando IP guardada primero: $savedIp');
        final isServer = await _checkServer(savedIp);
        if (isServer) {
          print('[DISCOVERY] ✓ Servidor encontrado en IP guardada: $savedIp');
          return [savedIp];
        }
        print('[DISCOVERY] IP guardada no responde, continuando con escaneo completo...');
      }

      print('[DISCOVERY] Iniciando escaneo de red...');
      // Escanear todos los rangos en paralelo con timeout total
      final servers = await _scanNetworkRangeOptimized(allIps.toList())
          .timeout(const Duration(seconds: 30), onTimeout: () {
        print('[DISCOVERY] TIMEOUT: El escaneo tardó más de 30 segundos');
        return <String>[];
      });
      
      print('[DISCOVERY] Escaneo completado. Servidores encontrados: ${servers.length}');
      if (servers.isNotEmpty) {
        print('[DISCOVERY] IPs de servidores: $servers');
      }
      
      return servers;
    } catch (e) {
      print('[DISCOVERY] ERROR durante descubrimiento: $e');
      return [];
    }
  }

  /// Obtiene todas las IPs locales del dispositivo (múltiples interfaces).
  static Future<List<String>> _getAllLocalIps() async {
    final ips = <String>[];
    try {
      final networkInfo = NetworkInfo();
      
      // Obtener IP WiFi
      final wifiIp = await networkInfo.getWifiIP();
      if (wifiIp != null && wifiIp.isNotEmpty && wifiIp != '0.0.0.0' && wifiIp != '127.0.0.1') {
        ips.add(wifiIp);
      }
      
      return ips;
    } catch (e) {
      // Si hay error, retornar lista vacía (el código manejará esto)
      return ips;
    }
  }

  /// Obtiene el prefijo de red (primeros 3 octetos) de una IP.
  static String? _getNetworkPrefix(String ip) {
    try {
      final parts = ip.split('.');
      if (parts.length == 4) {
        return '${parts[0]}.${parts[1]}.${parts[2]}.';
      }
    } catch (e) {
      // Ignorar errores
    }
    return null;
  }

  /// Calcula el rango de red basado en la IP local.
  /// Retorna una lista de IPs a escanear (ej: 192.168.1.1-254).
  static List<String>? _calculateNetworkRange(String localIp) {
    try {
      final parts = localIp.split('.');
      if (parts.length != 4) {
        return null;
      }

      // Construir el prefijo de red (primeros 3 octetos)
      final networkPrefix = '${parts[0]}.${parts[1]}.${parts[2]}.';
      
      // Generar lista de IPs a escanear (1-254, excluyendo la IP local)
      final ips = <String>[];
      for (int i = 1; i <= 254; i++) {
        final ip = '$networkPrefix$i';
        // Excluir la IP local para evitar escanearse a sí mismo
        if (ip != localIp) {
          ips.add(ip);
        }
      }
      
      return ips;
    } catch (e) {
      return null;
    }
  }

  /// Escanea el rango de red en busca de servidores de forma optimizada.
  /// Usa escaneo paralelo masivo con límite de concurrencia.
  static Future<List<String>> _scanNetworkRangeOptimized(List<String> ips) async {
    final servers = <String>{};
    int checked = 0;
    int found = 0;

    print('[SCAN] Iniciando escaneo de ${ips.length} IPs en lotes de $_maxConcurrent');

    // Dividir en lotes y procesar en paralelo
    final batches = <List<String>>[];
    for (int i = 0; i < ips.length; i += _maxConcurrent) {
      batches.add(ips.skip(i).take(_maxConcurrent).toList());
    }

    print('[SCAN] Total de lotes: ${batches.length}');

    // Procesar lotes en paralelo (todos a la vez para máxima velocidad)
    // Cada lote tiene máximo _maxConcurrent IPs, y procesamos múltiples lotes simultáneamente
    final results = await Future.wait(
      batches.asMap().entries.map((entry) async {
        final batchIndex = entry.key;
        final batch = entry.value;
        
        print('[SCAN] Procesando lote ${batchIndex + 1}/${batches.length} (${batch.length} IPs)');
        
        final batchResults = await Future.wait(
          batch.map((ip) async {
            checked++;
            final isServer = await _checkServer(ip);
            if (isServer) {
              found++;
              print('[SCAN] ✓ Servidor encontrado: $ip');
              return ip;
            } else {
              if (checked % 20 == 0) {
                print('[SCAN] Progreso: $checked/${ips.length} IPs verificadas, $found servidor(es) encontrado(s)');
              }
              return null;
            }
          }),
        );
        
        final foundInBatch = batchResults.where((ip) => ip != null).cast<String>().toList();
        if (foundInBatch.isNotEmpty) {
          print('[SCAN] Lote ${batchIndex + 1} completado: ${foundInBatch.length} servidor(es) encontrado(s)');
        }
        
        return foundInBatch;
      }),
    );

    // Combinar todos los resultados
    for (final batchResults in results) {
      servers.addAll(batchResults);
    }

    print('[SCAN] Escaneo finalizado: $checked IPs verificadas, ${servers.length} servidor(es) encontrado(s)');
    return servers.toList();
  }

  /// Verifica si una IP es un servidor Spring Boot válido.
  /// Usa HEAD request primero (más rápido) y luego GET si es necesario.
  static Future<bool> _checkServer(String ip) async {
    final baseUrl = 'http://$ip:$_port';

    // Estrategia optimizada: usar endpoints específicos de descubrimiento primero
    // Luego intentar endpoints alternativos si los específicos no funcionan

    // 1. Intentar HEAD en /discovery (endpoint específico, más rápido y confiable)
    try {
      final response = await http
          .head(Uri.parse('$baseUrl/discovery'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        print('[CHECK] $ip: ✓ Responde en /discovery (HEAD)');
        return true;
      }
    } catch (e) {
      // Continuar con otros métodos
    }

    // 2. Intentar GET en /discovery (para verificar que es nuestro servidor)
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/discovery'))
          .timeout(_timeout);
      if (response.statusCode == 200 && 
          response.body.contains('UPSGlam-Server')) {
        print('[CHECK] $ip: ✓ Responde en /discovery (GET) - UPSGlam-Server confirmado');
        return true;
      }
    } catch (e) {
      // Continuar con otros métodos
    }

    // 3. Intentar HEAD en /actuator/health (endpoint estándar de Spring Boot)
    try {
      final response = await http
          .head(Uri.parse('$baseUrl/actuator/health'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        print('[CHECK] $ip: ✓ Responde en /actuator/health (HEAD)');
        return true;
      }
    } catch (e) {
      // Continuar con otros métodos
    }

    // 4. Intentar GET en /actuator/health (más confiable pero más lento)
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/actuator/health'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        print('[CHECK] $ip: ✓ Responde en /actuator/health (GET)');
        return true;
      }
    } catch (e) {
      // Continuar con otros endpoints
    }

    // 5. Intentar HEAD en /api/auth/login (endpoint conocido como fallback)
    try {
      final response = await http
          .head(Uri.parse('$baseUrl/api/auth/login'))
          .timeout(_timeout);
      // 405 Method Not Allowed, 400 Bad Request, o cualquier respuesta < 500 indica servidor activo
      if (response.statusCode == 405 || 
          response.statusCode == 400 || 
          (response.statusCode < 500 && response.statusCode != 404)) {
        print('[CHECK] $ip: ✓ Responde en /api/auth/login (HEAD) - Status: ${response.statusCode}');
        return true;
      }
    } catch (e) {
      // No es un servidor válido
    }

    return false;
  }
}

