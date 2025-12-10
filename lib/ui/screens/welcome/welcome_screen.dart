import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/typography.dart';
import '../../theme/colors.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/effects/gradient_background.dart';
import '../../../services/config/app_config_service.dart';
import '../../../services/discovery/network_discovery_service.dart';

/// Pantalla de bienvenida institucional UPS.
/// Permite configurar la IP del servidor Spring Boot.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _ipController = TextEditingController();
  String? _ipError;
  bool _isSaving = false;
  List<String> _discoveredServers = [];
  bool _isScanning = false;
  String? _selectedServerIp;

  @override
  void initState() {
    super.initState();
    _loadSavedIp();
    _scanForServers();
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  /// Carga la IP guardada previamente.
  Future<void> _loadSavedIp() async {
    final savedIp = await AppConfigService.getServerIp();
    if (mounted) {
      setState(() {
        _ipController.text = savedIp;
        // No establecer _selectedServerIp aquí, esperar a que termine el escaneo
      });
    }
  }

  /// Escanea la red local en busca de servidores Spring Boot.
  Future<void> _scanForServers() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _discoveredServers = [];
    });

    try {
      final servers = await NetworkDiscoveryService.discoverServers()
          .timeout(const Duration(minutes: 2), onTimeout: () {
        // Si el escaneo tarda más de 2 minutos, retornar lista vacía
        return <String>[];
      });
      
      if (mounted) {
        final savedIp = _ipController.text.trim();
        
        setState(() {
          _discoveredServers = servers;
          _isScanning = false;
          
          // Si la IP guardada está en la lista de servidores descubiertos, seleccionarla
          if (savedIp.isNotEmpty && servers.contains(savedIp)) {
            _selectedServerIp = savedIp;
          } 
          // Si hay servidores encontrados pero la IP guardada no está en la lista, seleccionar el primero
          else if (servers.isNotEmpty && _selectedServerIp == null) {
            _selectedServerIp = servers.first;
            _ipController.text = servers.first;
          }
          // Si no hay servidores o la IP guardada no está en la lista, usar modo manual
          else if (savedIp.isNotEmpty && !servers.contains(savedIp)) {
            _selectedServerIp = null; // Modo manual
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _discoveredServers = [];
          // Si hay una IP guardada pero no se encontraron servidores, usar modo manual
          if (_ipController.text.trim().isNotEmpty) {
            _selectedServerIp = null;
          }
        });
      }
    }
  }

  /// Valida y guarda la IP del servidor.
  Future<void> _handleContinue() async {
    final ip = _ipController.text.trim();

    // Validar IP
    setState(() {
      _ipError = null;
    });

    if (ip.isEmpty) {
      setState(() {
        _ipError = 'Ingrese la dirección IP del servidor';
      });
      return;
    }

    if (!AppConfigService.isValidIp(ip)) {
      setState(() {
        _ipError = 'Ingrese una dirección IP válida (ej: 192.168.1.100)';
      });
      return;
    }

    // Guardar IP
    setState(() {
      _isSaving = true;
    });

    final saved = await AppConfigService.setServerIp(ip);
    
    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (!saved) {
      setState(() {
        _ipError = 'Error al guardar la configuración';
      });
      return;
    }

    // Navegar al login
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Si hay historial, hacer pop
          if (context.canPop()) {
            context.pop();
          }
          // Si no hay historial, no hacer nada (evitar que cierre la app)
        }
      },
      child: Scaffold(
        body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.welcomeBackground,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  
                  Row(
                    children: const [
                      Text('UPS', style: AppTypography.titleUPS),
                      SizedBox(width: 4),
                      Text('tagram', style: AppTypography.titleGlam),
                    ],
                  ),

                  const SizedBox(height: 8),
                  const Text('Bienvenido', style: AppTypography.subtitle),

                  const SizedBox(height: 24),
                  const Text(
                    'Explora, publica y comparte fotografías con la comunidad UPS.',
                    style: AppTypography.body,
                  ),

                  const SizedBox(height: 32),

                  /// Campo para configurar la IP del servidor con descubrimiento automático
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: const Text(
                              'Dirección IP del servidor',
                              style: TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (_isScanning)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                              ),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.white70),
                              onPressed: _scanForServers,
                              tooltip: 'Buscar servidores',
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _ipError != null
                                ? Colors.redAccent
                                : Colors.white.withValues(alpha: 0.25),
                            width: _ipError != null ? 1.6 : 1.0,
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedServerIp != null && 
                                 _discoveredServers.contains(_selectedServerIp)
                                 ? _selectedServerIp
                                 : null,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: InputBorder.none,
                            hintText: 'Selecciona o escribe la IP',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                            prefixIcon: const Icon(
                              Icons.dns_outlined,
                              color: Colors.white70,
                            ),
                            suffixIcon: _discoveredServers.isEmpty
                                ? null
                                : const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.white70,
                                  ),
                            errorText: _ipError,
                            errorStyle: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                              height: 1.2,
                            ),
                          ),
                          dropdownColor: AppColors.upsBlueDark,
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 16,
                          ),
                          iconEnabledColor: Colors.white70,
                          items: [
                            // Opción para escribir manualmente
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.white70, size: 18),
                                  SizedBox(width: 8),
                                  Text('Escribir manualmente'),
                                ],
                              ),
                            ),
                            // Servidores encontrados
                            ..._discoveredServers.map((ip) {
                              return DropdownMenuItem<String>(
                                value: ip,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.greenAccent,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(ip),
                                  ],
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedServerIp = value;
                              if (value != null) {
                                _ipController.text = value;
                              } else {
                                // Si selecciona "Escribir manualmente", limpiar y enfocar
                                _ipController.clear();
                              }
                              _ipError = null;
                            });
                          },
                        ),
                      ),
                      // Campo de texto para escribir manualmente (visible cuando se selecciona "Escribir manualmente" o cuando no hay servidores)
                      if (_selectedServerIp == null || _discoveredServers.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextField(
                            controller: _ipController,
                            keyboardType: TextInputType.text,
                            style: const TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _ipError != null
                                      ? Colors.redAccent
                                      : Colors.white.withValues(alpha: 0.25),
                                  width: _ipError != null ? 1.6 : 1.0,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _ipError != null
                                      ? Colors.redAccent
                                      : Colors.white.withValues(alpha: 0.25),
                                  width: _ipError != null ? 1.6 : 1.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _ipError != null
                                      ? Colors.redAccent
                                      : Colors.white.withValues(alpha: 0.5),
                                  width: _ipError != null ? 1.6 : 1.5,
                                ),
                              ),
                              hintText: 'Ej: 192.168.1.100 o localhost',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                              prefixIcon: const Icon(
                                Icons.edit,
                                color: Colors.white70,
                              ),
                            ),
                            onChanged: (value) {
                              if (_ipError != null) {
                                setState(() {
                                  _ipError = null;
                                });
                              }
                            },
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _isScanning
                                ? const Text(
                                    'Buscando servidores en la red...',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  )
                                : _discoveredServers.isEmpty
                                    ? const Text(
                                        'No se encontraron servidores. Escribe la IP manualmente.',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      )
                                    : Text(
                                        '${_discoveredServers.length} servidor(es) encontrado(s)',
                                        style: const TextStyle(
                                          color: Colors.greenAccent,
                                          fontSize: 12,
                                        ),
                                      ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),
                  
                  PrimaryButton(
                    label: 'Continuar',
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _handleContinue,
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
