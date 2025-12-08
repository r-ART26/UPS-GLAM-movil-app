import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/effects/gradient_background.dart';
import '../../widgets/inputs/text_input.dart';

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
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Variables de error
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  // Estado del botón
  bool _isLoading = false;

  /// Validación del nombre completo
  bool _isValidName(String value) {
    final parts = value.trim().split(' ');
    return parts.length >= 2 && parts.every((p) => p.length >= 2);
  }

  /// Validación de correo institucional
  bool _isValidEmail(String value) {
    if (!value.contains('@')) return false;
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
        _passwordController.text.trim() == _confirmPasswordController.text.trim();
  }

  void _handleRegister() {
    if (_isLoading) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;

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

    if (_nameError != null ||
        _emailError != null ||
        _passwordError != null ||
        _confirmPasswordError != null) {
      return;
    }

    // Simulación de proceso de registro
    setState(() => _isLoading = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _isLoading = false);

      debugPrint('REGISTER OK → $name, $email');
      // Aquí más adelante se llamará a Firebase Auth
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
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
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
                    /// Título
                    const Text(
                      'Crear cuenta',
                      style: AppTypography.subtitle,
                    ),

                    const SizedBox(height: 24),

                    /// Nombre completo
                    TextInput(
                      label: 'Nombre completo',
                      hintText: 'Ej. Juan Pérez',
                      controller: _nameController,
                      prefixIcon: Icons.person_outline,
                      errorText: _nameError,
                      onChanged: (_) {
                        if (_nameError != null) {
                          setState(() => _nameError = null);
                        } else {
                          setState(() {});
                        }
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
                        if (_emailError != null) {
                          setState(() => _emailError = null);
                        } else {
                          setState(() {});
                        }
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
                        if (_passwordError != null) {
                          setState(() => _passwordError = null);
                        } else {
                          setState(() {});
                        }
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
                        if (_confirmPasswordError != null) {
                          setState(() => _confirmPasswordError = null);
                        } else {
                          setState(() {});
                        }
                      },
                    ),

                    const SizedBox(height: 32),

                    /// Botón para registrar
                    PrimaryButton(
                      label: _isLoading ? 'Registrando...' : 'Registrarme',
                      isLoading: _isLoading,
                      isDisabled: !_isFormValid || _isLoading,
                      onPressed: _handleRegister,
                    ),

                    const SizedBox(height: 20),

                    /// Enlace a login
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
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
    );
  }
}
