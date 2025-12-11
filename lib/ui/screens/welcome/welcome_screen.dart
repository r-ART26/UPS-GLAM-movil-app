import 'dart:ui'; // For image filter
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/typography.dart';
import '../../theme/colors.dart';
import '../../widgets/design_system/glam_button.dart';

import '../../../services/config/app_config_service.dart';
import '../../../services/discovery/network_discovery_service.dart';

/// Pantalla de bienvenida institucional UPS.
/// Permite configurar la IP del servidor Spring Boot.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _ipController = TextEditingController();

  // Animation state
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String? _ipError;
  bool _isSaving = false;
  List<String> _discoveredServers = [];
  bool _isScanning = false;
  String? _selectedServerIp;

  @override
  void initState() {
    super.initState();

    // Setup Animations
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
          ),
        );

    // Start animation
    _animController.forward();

    _loadSavedIp();
    _scanForServers();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _animController.dispose();
    super.dispose();
  }

  /// Carga la IP guardada previamente.
  Future<void> _loadSavedIp() async {
    final savedIp = await AppConfigService.getServerIp();
    if (mounted) {
      setState(() {
        _ipController.text = savedIp;
      });
    }
  }

  /// Escanea la red local en busca de servidores Spring Boot.
  Future<void> _scanForServers() async {
    if (_isScanning) return;

    final currentSelectedIp = _selectedServerIp;
    final currentText = _ipController.text.trim();

    setState(() {
      _isScanning = true;
      _discoveredServers = [];
      _selectedServerIp = null;
    });

    try {
      final servers = await NetworkDiscoveryService.discoverServers().timeout(
        const Duration(minutes: 2),
        onTimeout: () => <String>[],
      );

      if (mounted) {
        final savedIp = _ipController.text.trim().isNotEmpty
            ? _ipController.text.trim()
            : currentText;

        setState(() {
          _discoveredServers = servers;
          _isScanning = false;

          if (servers.isNotEmpty) {
            if (savedIp.isNotEmpty && servers.contains(savedIp)) {
              _selectedServerIp = savedIp;
              _ipController.text = savedIp;
            } else if (currentSelectedIp != null &&
                servers.contains(currentSelectedIp)) {
              _selectedServerIp = currentSelectedIp;
              _ipController.text = currentSelectedIp;
            } else {
              _selectedServerIp = servers.first;
              _ipController.text = servers.first;
            }
          } else if (savedIp.isNotEmpty) {
            _selectedServerIp = null;
            _ipController.text = savedIp;
          } else {
            _selectedServerIp = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _discoveredServers = [];
          if (_ipController.text.trim().isNotEmpty) {
            _selectedServerIp = null;
          }
        });
      }
    }
  }

  /// Valida y guarda la IP del servidor.
  Future<void> _handleContinue() async {
    String ip = _selectedServerIp ?? _ipController.text.trim();

    if (_selectedServerIp != null && _selectedServerIp!.isNotEmpty) {
      _ipController.text = _selectedServerIp!;
      ip = _selectedServerIp!;
    }

    setState(() {
      _ipError = null;
    });

    if (ip.isEmpty) {
      setState(() => _ipError = 'Ingrese la dirección IP del servidor');
      return;
    }

    if (!AppConfigService.isValidIp(ip)) {
      setState(() => _ipError = 'Ingrese una dirección IP válida');
      return;
    }

    setState(() => _isSaving = true);

    final saved = await AppConfigService.setServerIp(ip);

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (!saved) {
      setState(() => _ipError = 'Error al guardar la configuración');
      return;
    }

    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          }
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.darkBackground,
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Text('UPS', style: AppTypography.titleUPS),
                            const SizedBox(width: 6),
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppGradients.gold.createShader(bounds),
                              child: const Text(
                                'tagram',
                                style: AppTypography.titleGlam,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        Container(
                          width: 60,
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: AppGradients.gold,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),

                        const SizedBox(height: 32),
                        const Text('Bienvenido', style: AppTypography.h2),
                        const SizedBox(height: 16),
                        Text(
                          'Explora, publica y comparte fotografías con la comunidad universitaria de la UPS.',
                          style: AppTypography.body.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 48),

                        // SERVER CONFIG CARD (Glassmorphism)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.glassWhite,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.glassBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.dns_rounded,
                                    color: AppColors.upsYellow,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Conexión al Servidor',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_isScanning)
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white70,
                                            ),
                                      ),
                                    )
                                  else
                                    IconButton(
                                      icon: const Icon(
                                        Icons.refresh_rounded,
                                        color: Colors.white70,
                                      ),
                                      onPressed: _scanForServers,
                                      tooltip: 'Buscar servidores',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Select or Type
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _ipError != null
                                        ? AppColors.error
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_discoveredServers.isNotEmpty)
                                      DropdownButtonFormField<String>(
                                        value:
                                            _selectedServerIp != null &&
                                                (_discoveredServers.contains(
                                                      _selectedServerIp,
                                                    ) ||
                                                    _ipController.text.trim() ==
                                                        _selectedServerIp)
                                            ? _selectedServerIp
                                            : null,
                                        decoration: InputDecoration(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                          border: InputBorder.none,
                                          prefixIcon: const Icon(
                                            Icons.wifi_tethering,
                                            color: Colors.white54,
                                          ),
                                        ),
                                        dropdownColor: AppColors.darkBackground,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        iconEnabledColor: Colors.white70,
                                        hint: Text(
                                          'Seleccionar servidor',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.5,
                                            ),
                                          ),
                                        ),
                                        items: [
                                          const DropdownMenuItem<String>(
                                            value: null,
                                            child: Text(
                                              'Escribir manualmente...',
                                            ),
                                          ),
                                          ..._discoveredServers.map(
                                            (ip) => DropdownMenuItem(
                                              value: ip,
                                              child: Text(ip),
                                            ),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedServerIp = value;
                                            if (value != null) {
                                              _ipController.text = value;
                                            } else {
                                              _ipController.clear();
                                            }
                                            _ipError = null;
                                          });
                                        },
                                      ),

                                    if (_selectedServerIp == null ||
                                        _discoveredServers.isEmpty)
                                      TextField(
                                        controller: _ipController,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Ej: 192.168.1.100',
                                          hintStyle: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.3,
                                            ),
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 14,
                                              ),
                                          prefixIcon: const Icon(
                                            Icons.edit_rounded,
                                            color: Colors.white54,
                                            size: 20,
                                          ),
                                        ),
                                        onChanged: (val) {
                                          if (_selectedServerIp != null &&
                                              val != _selectedServerIp) {
                                            setState(
                                              () => _selectedServerIp = null,
                                            );
                                          }
                                          if (_ipError != null)
                                            setState(() => _ipError = null);
                                        },
                                      ),
                                  ],
                                ),
                              ),

                              if (_ipError != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    left: 4,
                                  ),
                                  child: Text(
                                    _ipError!,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 8),

                              // Status Text
                              if (!_isScanning && _discoveredServers.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Text(
                                    'ℹ️ No se encontraron servidores locales. Ingresa la IP manualmente.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 48),

                        GlamButton(
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
        ),
      ),
    );
  }
}
