import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/typography.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/text_input.dart';
import '../../widgets/effects/gradient_background.dart';
import '../../../services/config/app_config_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSavedIp();
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
      });
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

                  /// Campo para configurar la IP del servidor
                  TextInput(
                    label: 'Dirección IP del servidor',
                    hintText: 'Ej: 192.168.1.100 o localhost',
                    keyboardType: TextInputType.text,
                    controller: _ipController,
                    prefixIcon: Icons.dns_outlined,
                    errorText: _ipError,
                    onChanged: (value) {
                      // Limpiar error cuando el usuario empiece a escribir
                      if (_ipError != null) {
                        setState(() {
                          _ipError = null;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'Ingresa la IP de tu servidor Spring Boot en la red local',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
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
