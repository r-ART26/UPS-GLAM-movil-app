import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/typography.dart';
import '../../widgets/effects/gradient_background.dart';
import '../../../services/posts/feed_service.dart';
import '../post/post_detail_screen.dart';

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
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildPostCard(context, data, doc.id);
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

  Widget _buildPostCard(
    BuildContext context,
    Map<String, dynamic> post,
    String docId,
  ) {
    // Extracción segura de datos (campos pos_*)
    final imageUrl =
        post['pos_imageUrl'] as String? ??
        'https://via.placeholder.com/800x600?text=No+Image';
    // Nota: La DB parece no tener username plano, usa authorUid.
    // Usamos el UID para buscar el nombre en el widget
    final authorUid = post['pos_authorUid'] as String? ?? '';
    final caption = post['pos_caption'] as String? ?? '';
    final likes = post['pos_likesCount'] as int? ?? 0;
    final comments = post['pos_commentsCount'] as int? ?? 0;

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
          // Imagen del post - Tapa para ver detalles
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PostDetailScreen(
                    postId: docId,
                    imageUrl: imageUrl,
                    description: caption,
                    authorName:
                        'Usuario', // Se resolverá dentro si es necesario, o podemos pasar el UID
                  ),
                ),
              );
            },
            child: Hero(
              tag: docId,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
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
                    // Nombre dinámico desde Firebase 'Users'
                    _UserNameFetcher(uid: authorUid),

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

                // Barra de Acciones: Likes y Comentarios
                Row(
                  children: [
                    // --- LIKES ---
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite_border,
                          color: Colors.white70,
                          size: 22,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$likes',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 24), // Espacio entre grupos
                    // --- COMENTARIOS ---
                    Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.white70,
                          size: 22,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$comments',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

/// Widget pequeño para cargar el nombre de usuario bajo demanda
class _UserNameFetcher extends StatelessWidget {
  final String uid;

  const _UserNameFetcher({required this.uid});

  @override
  Widget build(BuildContext context) {
    // Si no hay UID válido
    if (uid.isEmpty) {
      return const Text(
        'Usuario UPS',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('Users').doc(uid).get(),
      builder: (context, snapshot) {
        // 1. Cargando o esperando
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 80,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }

        // 2. Extraer nombre
        String name = 'Usuario UPS';
        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          name = data?['usr_username'] as String? ?? 'Usuario UPS';
        }

        return Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        );
      },
    );
  }
}
