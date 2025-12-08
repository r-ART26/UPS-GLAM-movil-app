import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/effects/gradient_background.dart';
import '../../widgets/inputs/text_input.dart';
import 'package:go_router/go_router.dart';


/// Pantalla de inicio de sesión para la aplicación UPSGlam.
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

  // Variables para mostrar los errores en pantalla
  String? _emailError;
  String? _passwordError;

  // Estado de carga del botón
  bool _isLoading = false;

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

  void _handleLogin() {
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

    // Simular login en progreso (por ahora solo delay)
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      debugPrint('LOGIN OK → correo: $email');
      // Aquí más adelante se navegará al feed tras login correcto
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

                    const SizedBox(height: 32),

                    /// Botón para iniciar sesión
                    PrimaryButton(
                      label: _isLoading ? 'Ingresando...' : 'Ingresar',
                      isLoading: _isLoading,
                      isDisabled: !_isFormValid || _isLoading,
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
    );
  }
}
