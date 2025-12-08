import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/effects/gradient_background.dart';
import '../../widgets/inputs/text_input.dart';
import '../../../services/api/api_service.dart';
import '../../../services/config/app_config_service.dart';

/// Pantalla de registro para UPSGlam.
/// Con validación completa y feedback visual en tiempo real.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controladores
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  @override
  void initState() {
    super.initState();
    // Verificar conexión al cargar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkServerConnection();
    });
  }

  /// Verifica la conexión con el servidor
  Future<void> checkServerConnection() async {
    setState(() {
      _isCheckingConnection = true;
    });

    try {
      final isConnected = await ApiService.checkConnection();
      if (mounted) {
        setState(() {
          _isConnected = isConnected;
          _isCheckingConnection = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isCheckingConnection = false;
        });
      }
    }
  }

  // Variables de error
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _generalError;

  // Estado del botón
  bool _isLoading = false;
  bool _isCheckingConnection = false;
  bool? _isConnected;

  /// Validación del nombre completo
  bool _isValidName(String value) {
    final parts = value.trim().split(' ');
    return parts.length >= 2 && parts.every((p) => p.length >= 2);
  }

  /// Validación de correo institucional
  bool _isValidEmail(String value) {
    if (!value.contains('@')) {
      return false;
    }
    return value.endsWith('@ups.edu.ec') || value.endsWith('@est.ups.edu.ec');
  }

  /// Validación de contraseña
  bool _isValidPassword(String value) {
    return value.length >= 6;
  }

  /// El formulario es válido cuando todos los campos pasan validación
  bool get _isFormValid {
    return _isValidName(_nameController.text.trim()) &&
        _isValidEmail(_emailController.text.trim()) &&
        _isValidPassword(_passwordController.text.trim()) &&
        _passwordController.text.trim() ==
            _confirmPasswordController.text.trim();
  }

  Future<void> _handleRegister() async {
    if (_isLoading) {
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _generalError = null;

      if (!_isValidName(name)) {
        _nameError = 'Ingrese nombre y apellido válidos';
      }
      if (!_isValidEmail(email)) {
        _emailError = 'Ingrese un correo institucional válido';
      }
      if (!_isValidPassword(password)) {
        _passwordError = 'La contraseña debe tener mínimo 6 caracteres';
      }
      if (password != confirmPassword) {
        _confirmPasswordError = 'Las contraseñas no coinciden';
      }
    });

    // Si existe al menos un error, no continuar
    if (_nameError != null ||
        _emailError != null ||
        _passwordError != null ||
        _confirmPasswordError != null) {
      return;
    }

    // Verificar conexión antes de intentar registro
    if (_isConnected == false) {
      setState(() {
        _generalError = 'No se puede conectar al servidor. Verifica la IP configurada.';
      });
      return;
    }

    // Iniciar registro
    setState(() {
      _isLoading = true;
    });

    try {
      // Hacer petición al backend
      final response = await ApiService.post(
        '/api/auth/register',
        {
          'usr_username': name,
          'usr_email': email,
          'usr_password': password,
          'usr_confirmPassword': confirmPassword,
          'usr_bio': 'Hola, bienvenido a mi perfil',
        },
        requireAuth: false, // El registro no requiere autenticación
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        // Registro exitoso
        debugPrint('Registro exitoso para: $email');

        // Redirigir automáticamente al login cuando finaliza registro
        if (mounted) {
          context.go('/login');
        }
      } else if (response.statusCode == 409) {
        // Email ya existe
        setState(() {
          _generalError = 'Este correo ya está registrado. Intenta iniciar sesión.';
          _isLoading = false;
        });
      } else {
        // Error del servidor
        setState(() {
          _generalError = 'Error del servidor. Intenta nuevamente.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('Error en registro: $e');
      setState(() {
        _isLoading = false;

        // Detectar tipo de error
        if (e.toString().contains('Failed host lookup') ||
            e.toString().contains('Connection refused') ||
            e.toString().contains('SocketException')) {
          _generalError = 'No se puede conectar al servidor. Verifica que esté corriendo y la IP sea correcta.';
          _isConnected = false;
        } else {
          _generalError = 'Error de conexión. Verifica tu conexión a internet.';
        }
      });
    }
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
          } else {
            // Si no hay historial, ir a login
            context.go('/login');
          }
        }
      },
      child: Scaffold(
        body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.welcomeBackground,
        ),
        child: SafeArea(
          child: SizedBox.expand(
            child: SingleChildScrollView(
              padding:
              const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.vertical -
                      48,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Crear cuenta',
                      style: AppTypography.subtitle,
                    ),

                    const SizedBox(height: 16),

                    /// Indicador de estado de conexión
                    _buildConnectionStatus(),

                    const SizedBox(height: 24),

                    /// Nombre completo
                    TextInput(
                      label: 'Nombre completo',
                      hintText: 'Ej. Juan Pérez',
                      controller: _nameController,
                      prefixIcon: Icons.person_outline,
                      errorText: _nameError,
                      onChanged: (_) {
                        setState(() {
                          _nameError = null;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    /// Correo institucional
                    TextInput(
                      label: 'Correo institucional',
                      hintText: 'usuario@est.ups.edu.ec',
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                      prefixIcon: Icons.email_outlined,
                      errorText: _emailError,
                      onChanged: (_) {
                        setState(() {
                          _emailError = null;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    /// Contraseña
                    TextInput(
                      label: 'Contraseña',
                      hintText: 'Ingrese su contraseña',
                      obscureText: true,
                      controller: _passwordController,
                      prefixIcon: Icons.lock_outline,
                      errorText: _passwordError,
                      onChanged: (_) {
                        setState(() {
                          _passwordError = null;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    /// Confirmar contraseña
                    TextInput(
                      label: 'Confirmar contraseña',
                      hintText: 'Repita su contraseña',
                      obscureText: true,
                      controller: _confirmPasswordController,
                      prefixIcon: Icons.lock_outline,
                      errorText: _confirmPasswordError,
                      onChanged: (_) {
                        setState(() {
                          _confirmPasswordError = null;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    /// Mensaje de error general
                    if (_generalError != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _generalError!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_generalError != null) const SizedBox(height: 16),

                    /// Botón para registrar
                    PrimaryButton(
                      label: _isLoading ? 'Registrando...' : 'Registrarme',
                      isLoading: _isLoading,
                      isDisabled: !_isFormValid || _isLoading || _isConnected == false,
                      onPressed: _handleRegister,
                    ),

                    const SizedBox(height: 20),

                    /// Enlace a login
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          context.go('/login');
                        },
                        child: const Text(
                          '¿Ya tienes cuenta? Inicia sesión',
                          style: TextStyle(
                            color: AppColors.upsYellow,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  /// Widget para mostrar el estado de conexión al servidor
  Widget _buildConnectionStatus() {
    if (_isCheckingConnection) {
      return Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Verificando conexión...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    if (_isConnected == true) {
      return Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          FutureBuilder<String>(
            future: AppConfigService.getBaseUrl(),
            builder: (context, snapshot) {
              final serverUrl = snapshot.data ?? 'Servidor';
              return Text(
                'Conectado a $serverUrl',
                style: TextStyle(
                  color: Colors.green.shade300,
                  fontSize: 12,
                ),
              );
            },
          ),
        ],
      );
    }

    if (_isConnected == false) {
      return Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No se puede conectar al servidor',
              style: TextStyle(
                color: Colors.red.shade300,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: checkServerConnection,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Reintentar',
              style: TextStyle(
                color: AppColors.upsYellow,
                fontSize: 12,
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
