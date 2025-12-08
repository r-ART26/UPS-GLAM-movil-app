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
        child: Column(
          children: [
            // ===========================
            // HEADER SUPERIOR
            // ===========================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Text('UPS', style: AppTypography.titleUPS),
                      SizedBox(width: 4),
                      Text('Glam', style: AppTypography.titleGlam),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: abrir configuración
                    },
                    icon: const Icon(Icons.settings_outlined,
                        color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),

            // ===========================
            // INFO DEL USUARIO
            // ===========================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 46,
                    backgroundImage: NetworkImage(
                      'https://picsum.photos/200',
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Roberto Romero',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'roberto@est.ups.edu.ec',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ===========================
                  // ESTADÍSTICAS
                  // ===========================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatItem(label: 'Posts', value: '12'),
                      const SizedBox(width: 32),
                      _StatItem(label: 'Seguidores', value: '158'),
                      const SizedBox(width: 32),
                      _StatItem(label: 'Siguiendo', value: '89'),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ===========================
                  // BOTÓN EDITAR PERFIL
                  // ===========================
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Navegar a "editar perfil"
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Editar perfil',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // ===========================
            // GRID DE PUBLICACIONES
            // ===========================
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mis publicaciones',
                  style: AppTypography.body,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemBuilder: (context, i) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      'https://picsum.photos/id/${i + 40}/400/400',
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget pequeño para estadísticas
class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
