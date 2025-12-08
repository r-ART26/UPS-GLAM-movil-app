import 'package:flutter/material.dart';
import '../../theme/typography.dart';
// Import correcto del gradiente según tu estructura:
import '../../widgets/effects/gradient_background.dart';

/// Pantalla principal (Feed) con diseño institucional UPSGlam.
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // No usamos const porque AppGradients.welcomeBackground no es const
      decoration: const BoxDecoration(
        gradient: AppGradients.welcomeBackground,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Feed', style: AppTypography.subtitle),
                  Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            /// LISTA DE POSTS (mock, sin PostCard por ahora)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _mockPosts.length,
                itemBuilder: (context, index) {
                  final post = _mockPosts[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Imagen del post
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: Image.network(
                              post['image'] as String,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        // Texto debajo
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post['username'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                post['desc'] as String,
                                style: const TextStyle(
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.favorite_border,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${post['likes']} me gusta',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
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

/// Datos temporales para pruebas (mock)
final List<Map<String, dynamic>> _mockPosts = [
  {
    'username': 'roberto.romero',
    'image': 'https://picsum.photos/id/10/800/600',
    'likes': 142,
    'desc': 'Tarde increíble en el campus UPS.',
  },
  {
    'username': 'daniela.garcia',
    'image': 'https://picsum.photos/id/27/800/600',
    'likes': 221,
    'desc': 'Nuevo proyecto de computación en marcha.',
  },
];
