import 'package:flutter/material.dart';
import '../../theme/typography.dart';
import '../../widgets/effects/gradient_background.dart';

/// Pantalla principal (Feed) con diseño institucional UPStagram.
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppGradients.welcomeBackground,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER SUPERIOR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Marca UPStagram
                  Row(
                    children: const [
                      Text('UPS', style: AppTypography.titleUPS),
                      SizedBox(width: 4),
                      Text('tagram', style: AppTypography.titleGlam),
                    ],
                  ),

                  // Icono de cámara (para futuro: crear post desde aquí)
                  IconButton(
                    onPressed: () {
                      // TODO: Navegar a /home/post/new si quieres
                      // context.go('/home/post/new');
                    },
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),

            /// SUBTÍTULO
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Explora las fotos de la comunidad UPS',
                style: AppTypography.body,
              ),
            ),

            const SizedBox(height: 12),

            /// LISTA DE POSTS
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _mockPosts.length,
                itemBuilder: (context, index) {
                  final post = _mockPosts[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Imagen del post
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18),
                          ),
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: Image.network(
                              post['image'] as String,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        // Contenido textual
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Usuario + fecha
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    post['username'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    post['time'] as String,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              // Descripción
                              Text(
                                post['desc'] as String,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Likes / acciones
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
    'time': 'Hace 2 h',
    'desc': 'Tarde increíble en el campus UPS.',
  },
  {
    'username': 'daniela.garcia',
    'image': 'https://picsum.photos/id/27/800/600',
    'likes': 221,
    'time': 'Hace 5 h',
    'desc': 'Nuevo proyecto de computación en marcha.',
  },
  {
    'username': 'javier.malo',
    'image': 'https://picsum.photos/id/33/800/600',
    'likes': 89,
    'time': 'Ayer',
    'desc': 'Preparando la demo de UPStagram 2.0.',
  },
];
