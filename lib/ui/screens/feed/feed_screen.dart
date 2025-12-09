import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/typography.dart';
import '../../widgets/effects/gradient_background.dart';
import '../../../services/posts/feed_service.dart';

/// Pantalla principal (Feed) con integración a Firestore en Tiempo Real.
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.welcomeBackground),
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

                  // Botón de recargar manual (útil si hay error de red)
                  // Opcional, ya que es realtime
                  IconButton(
                    onPressed: () {
                      // Acción futura: Scroll to top
                    },
                    icon: const Icon(
                      Icons.camera_alt_outlined, // Placeholder para cámara
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

            /// LISTA DE POSTS (STREAM REALTIME)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FeedService.getPostsStream(),
                builder: (context, snapshot) {
                  // 1. Cargando
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  // 2. Error
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error al cargar posts: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  // 3. Datos vacíos
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay publicaciones aún.\n¡Sé el primero en postear!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return _buildPostCard(data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    // Extracción segura de datos (campos pos_*)
    final imageUrl =
        post['pos_imageUrl'] as String? ??
        'https://via.placeholder.com/800x600?text=No+Image';
    // Nota: La DB parece no tener username plano, usa authorUid.
    // Por ahora pondremos un placeholder o el ID hasta resolver cómo traer el nombre.
    final username = post['pos_authorUid'] as String? ?? 'Usuario UPS';
    final caption = post['pos_caption'] as String? ?? '';
    final likes = post['pos_likesCount'] as int? ?? 0;

    // Manejo de Timestamp
    String timeAgo = 'Reciente';
    if (post['pos_timestamp'] != null) {
      final timestamp = post['pos_timestamp'] as Timestamp;
      timeAgo = _getTimeAgo(timestamp.toDate());
    }

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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return ColoredBox(
                    color: Colors.black12,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white24,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[800],
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.white54),
                  ),
                ),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Descripción
                if (caption.isNotEmpty)
                  Text(
                    caption,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
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
                      '$likes me gusta',
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
  }

  /// Utilidad simple para calcular tiempo relativo
  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays >= 1) {
      return 'Hace ${difference.inDays} d';
    } else if (difference.inHours >= 1) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inMinutes >= 1) {
      return 'Hace ${difference.inMinutes} min';
    } else {
      return 'Hace un momento';
    }
  }
}
