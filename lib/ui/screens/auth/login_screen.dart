import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/effects/gradient_background.dart';
import '../../widgets/inputs/text_input.dart';
import 'register_screen.dart';

/// Pantalla de inicio de sesión para la aplicación UPSGlam.
/// Mantiene coherencia con la línea gráfica institucional.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
                // Garantiza que el contenido tenga al menos el alto de la pantalla,
                // para que mainAxisAlignment.center funcione correctamente.
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.vertical -
                      48, // margen vertical aproximado
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Título principal de la vista
                    const Text(
                      'Iniciar sesión',
                      style: AppTypography.subtitle,
                    ),

                    const SizedBox(height: 24),

                    /// Campo de correo
                    TextInput(
                      label: 'Correo institucional',
                      hintText: 'usuario@est.ups.edu.ec',
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 16),

                    /// Campo de contraseña
                    TextInput(
                      label: 'Contraseña',
                      hintText: 'Ingrese su contraseña',
                      obscureText: true,
                    ),

                    const SizedBox(height: 32),

                    /// Botón para iniciar sesión
                    PrimaryButton(
                      label: 'Ingresar',
                      onPressed: () {
                        // TODO: Implementar lógica de autenticación
                      },
                    ),

                    const SizedBox(height: 20),

                    /// Enlace a pantalla de registro
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
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
