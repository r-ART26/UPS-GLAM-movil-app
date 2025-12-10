import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../theme/typography.dart';
import '../../theme/colors.dart';
import '../../widgets/effects/gradient_background.dart';
import '../../widgets/like_button.dart';
import '../../../services/posts/feed_service.dart';
import '../post/post_detail_screen.dart';

/// Pantalla principal (Feed) con integración a Firestore en Tiempo Real.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
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
                    authorUid: authorUid,
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
                    // Nombre dinámico desde Firebase 'Users'
                    GestureDetector(
                      onTap: () {
                        GoRouter.of(context).push('/profile/$authorUid');
                      },
                      child: _UserNameFetcher(uid: authorUid),
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

                // Barra de Acciones: Likes y Comentarios
                Row(
                  children: [
                    // --- LIKES (Interactivo con animación) ---
                    LikeButton(
                      postId: docId,
                      initialLikesCount: likes,
                      iconSize: 22,
                      likedColor: Colors.redAccent,
                      unlikedColor: Colors.white70,
                      countStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(width: 24), // Espacio entre grupos
                    // --- COMENTARIOS (Interactivo) ---
                    GestureDetector(
                      onTap: () {
                        // Navegar a la pantalla de detalle del post
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PostDetailScreen(
                              postId: docId,
                              imageUrl: imageUrl,
                              description: caption,
                              authorUid: authorUid,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.white70,
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('Posts')
                                .doc(docId)
                                .snapshots(),
                            builder: (context, postSnapshot) {
                              int currentComments = comments;
                              if (postSnapshot.hasData && postSnapshot.data != null) {
                                final data = postSnapshot.data!.data() as Map<String, dynamic>?;
                                if (data != null) {
                                  currentComments = data['pos_commentsCount'] as int? ?? comments;
                                }
                              }
                              
                              return Text(
                                '$currentComments',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ],
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

/// Widget pequeño para cargar el nombre de usuario bajo demanda
class _UserNameFetcher extends StatelessWidget {
  final String uid;

  const _UserNameFetcher({required this.uid});

  @override
  Widget build(BuildContext context) {
    // Si no hay UID válido
    if (uid.isEmpty) {
      return Row(
        children: const [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 16, color: Colors.white),
          ),
          SizedBox(width: 8),
          Text(
            'Usuario UPS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('Users').doc(uid).get(),
      builder: (context, snapshot) {
        // 1. Cargando
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Colors.white10,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 80,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          );
        }

        // 2. Extraer datos
        String name = 'Usuario UPS';
        String? photoUrl;

        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          name = data?['usr_username'] as String? ?? 'Usuario UPS';
          photoUrl = data?['usr_photoUrl'] as String?;
        }

        // 3. Lógica de Avatar
        ImageProvider? avatarImage;
        if (photoUrl != null && photoUrl.isNotEmpty) {
          avatarImage = NetworkImage(photoUrl);
        } else {
          // Generar avatar con iniciales si no hay foto
          // Usamos el azul UPS (003F87) de fondo y letras blancas
          final safeName = Uri.encodeComponent(name);
          avatarImage = NetworkImage(
            'https://ui-avatars.com/api/?name=$safeName&background=003F87&color=fff&size=150&bold=true',
          );
        }

        return Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.upsBlue,
              backgroundImage: avatarImage,
              // Ya no necesitamos child Icon porque siempre habrá imagen (real o generada)
            ),

            const SizedBox(width: 8),

            // Nombre
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        );
      },
    );
  }
}
