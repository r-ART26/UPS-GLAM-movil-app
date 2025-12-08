import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/typography.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/effects/gradient_background.dart';

/// Pantalla de bienvenida institucional UPS.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.welcomeBackground,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Text('UPS', style: AppTypography.titleUPS),
                    SizedBox(width: 4),
                    Text('Glam', style: AppTypography.titleGlam),
                  ],
                ),

                const SizedBox(height: 8),
                const Text('Bienvenido', style: AppTypography.subtitle),

                const SizedBox(height: 24),
                const Text(
                  'Explora, publica y comparte fotografías con la comunidad UPS.',
                  style: AppTypography.body,
                ),

                const SizedBox(height: 48),
                PrimaryButton(
                  label: 'Continuar',
                  onPressed: () {
                    context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
