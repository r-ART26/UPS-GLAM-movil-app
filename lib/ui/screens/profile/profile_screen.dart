import 'package:flutter/material.dart';
import '../../theme/typography.dart';
import '../../widgets/effects/gradient_background.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppGradients.welcomeBackground,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mi Perfil',
                style: AppTypography.subtitle,
              ),

              const SizedBox(height: 24),

              /// FOTO + NOMBRE
              Row(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(
                      'https://picsum.photos/200',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Roberto Romero', style: AppTypography.body),
                      SizedBox(height: 4),
                      Text(
                        'roberto@est.ups.edu.ec',
                        style: AppTypography.body,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),

              const Text(
                'Mis publicaciones',
                style: AppTypography.body,
              ),

              const SizedBox(height: 16),

              /// GRID DE POSTS
              Expanded(
                child: GridView.builder(
                  itemCount: 6,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemBuilder: (_, i) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(
                              'https://picsum.photos/id/${i + 30}/400/400'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
