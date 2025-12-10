import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/effects/gradient_background.dart';
import '../../widgets/inputs/text_input.dart';
import '../../widgets/dialogs/error_dialog.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api/api_service.dart';
import '../../../services/config/app_config_service.dart';
import '../../../services/auth/auth_service.dart';


/// Pantalla de inicio de sesión para la aplicación UPStagram.
/// Con validación real usando el nuevo TextInput y PrimaryButton.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para obtener los valores
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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

  // Variables para mostrar los errores en pantalla
  String? _emailError;
  String? _passwordError;

  // Estado de carga del botón
  bool _isLoading = false;
  bool _isCheckingConnection = false;
  bool? _isConnected;

  /// Validación de correo institucional UPS
  bool _isValidEmail(String value) {
    if (!value.contains('@')) return false;
    return value.endsWith('@ups.edu.ec') || value.endsWith('@est.ups.edu.ec');
  }

  /// Validación básica de contraseña
  bool _isValidPassword(String value) {
    return value.length >= 6;
  }

  /// Form válido según las reglas actuales
  bool get _isFormValid {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    return _isValidEmail(email) && _isValidPassword(password);
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      // Reset errores
      _emailError = null;
      _passwordError = null;

      // Validación de correo
      if (!_isValidEmail(email)) {
        _emailError = 'Ingrese un correo institucional válido';
      }

      // Validación de contraseña
      if (!_isValidPassword(password)) {
        _passwordError = 'La contraseña debe tener al menos 6 caracteres';
      }
    });

    // Si hay errores → no continuar
    if (_emailError != null || _passwordError != null) return;

    // Verificar conexión antes de intentar login
    if (_isConnected == false) {
      if (mounted) {
        await ErrorDialog.show(
          context,
          title: 'Error de conexión',
          message: 'No se puede conectar al servidor. Verifica la IP configurada.',
        );
      }
      return;
    }

    // Iniciar login
    setState(() {
      _isLoading = true;
    });

    try {
      // Hacer petición al backend
      final response = await ApiService.post(
        '/api/auth/login',
        {
          'email': email,
          'password': password,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Login exitoso
        final token = response.body; // El servidor retorna el token como String
        debugPrint('Login exitoso. Token: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
        
        // Guardar el token para futuras peticiones autenticadas
        final saved = await AuthService.saveToken(token);
        if (!saved) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            await ErrorDialog.show(
              context,
              title: 'Error',
              message: 'Error al guardar la sesión. Intenta nuevamente.',
            );
          }
          return;
        }
        
        // Navegar al feed
        if (mounted) {
          context.go('/home/feed');
        }
      } else if (response.statusCode == 401) {
        // Credenciales inválidas
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          await ErrorDialog.show(
            context,
            title: 'Error de autenticación',
            message: 'Credenciales incorrectas. Verifica tu correo y contraseña.',
          );
        }
      } else {
        // Error del servidor
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          await ErrorDialog.show(
            context,
            title: 'Error del servidor',
            message: 'Ocurrió un error al intentar iniciar sesión. Por favor, intenta nuevamente.',
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      
      debugPrint('Error en login: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Detectar tipo de error
      String errorMessage;
      String errorTitle;
      if (e.toString().contains('Failed host lookup') || 
          e.toString().contains('Connection refused') ||
          e.toString().contains('SocketException')) {
        errorTitle = 'Error de conexión';
        errorMessage = 'No se puede conectar al servidor. Verifica que esté corriendo y la IP sea correcta.';
        _isConnected = false;
      } else {
        errorTitle = 'Error de conexión';
        errorMessage = 'Error de conexión. Verifica tu conexión a internet.';
      }
      
      await ErrorDialog.show(
        context,
        title: errorTitle,
        message: errorMessage,
      );
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
            // Si no hay historial, ir a welcome
            context.go('/welcome');
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
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 24.0,
              ),
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
                    /// Título principal
                    const Text(
                      'Iniciar sesión',
                      style: AppTypography.subtitle,
                    ),

                    const SizedBox(height: 16),

                    /// Indicador de estado de conexión
                    _buildConnectionStatus(),

                    const SizedBox(height: 24),

                    /// Campo de correo
                    TextInput(
                      label: 'Correo institucional',
                      hintText: 'usuario@est.ups.edu.ec',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                      errorText: _emailError,
                      onChanged: (_) {
                        // Limpiar error mientras el usuario corrige
                        if (_emailError != null) {
                          setState(() {
                            _emailError = null;
                          });
                        } else {
                          setState(() {});
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    /// Campo de contraseña
                    TextInput(
                      label: 'Contraseña',
                      hintText: 'Ingrese su contraseña',
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                      controller: _passwordController,
                      errorText: _passwordError,
                      onChanged: (_) {
                        if (_passwordError != null) {
                          setState(() {
                            _passwordError = null;
                          });
                        } else {
                          setState(() {});
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    /// Botón para iniciar sesión
                    PrimaryButton(
                      label: _isLoading ? 'Ingresando...' : 'Ingresar',
                      isLoading: _isLoading,
                      isDisabled: !_isFormValid || _isLoading || _isConnected == false,
                      onPressed: _handleLogin,
                    ),

                    const SizedBox(height: 20),

                    /// Enlace a pantalla de registro
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          context.push('/register');
                        },
                        child: const Text(
                          '¿No tienes cuenta? Regístrate aquí',
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
