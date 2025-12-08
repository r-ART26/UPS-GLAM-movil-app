import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/effects/gradient_background.dart';
import '../../widgets/inputs/text_input.dart';

/// Pantalla de registro para UPSGlam.
/// Reutiliza la línea gráfica y componentes establecidos en la app.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

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

                    /// Campo: nombre completo
                    TextInput(
                      label: 'Nombre completo',
                      hintText: 'Ej. Juan Pérez',
                    ),

                    const SizedBox(height: 16),

                    /// Campo: correo institucional
                    TextInput(
                      label: 'Correo institucional',
                      hintText: 'usuario@est.ups.edu.ec',
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 16),

                    /// Campo: contraseña
                    TextInput(
                      label: 'Contraseña',
                      hintText: 'Ingrese su contraseña',
                      obscureText: true,
                    ),

                    const SizedBox(height: 16),

                    /// Campo: confirmar contraseña
                    TextInput(
                      label: 'Confirmar contraseña',
                      hintText: 'Repita su contraseña',
                      obscureText: true,
                    ),

                    const SizedBox(height: 32),

                    /// Botón para registrar
                    PrimaryButton(
                      label: 'Registrarme',
                      onPressed: () {
                        // TODO: Implementar lógica de registro con Firebase Auth
                      },
                    ),

                    const SizedBox(height: 20),

                    /// Enlace a login
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context); // vuelve al login
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
    );
  }
}
