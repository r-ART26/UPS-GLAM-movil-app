import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Para tipos de datos si es necesario (ej DocumentSnapshot implícitos)
import '../../theme/typography.dart';
import '../../theme/colors.dart';
import '../../widgets/effects/gradient_background.dart';
import '../../widgets/like_button.dart';
import '../post/post_detail_screen.dart';
import 'feed_controller.dart';
import '../../../models/feed_post_model.dart';

/// Pantalla principal (Feed) con arquitectura separada (MVC) y Paginación.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late FeedController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = FeedController();

    // Escuchar cambios en el controlador para reconstruir la UI
    _controller.addListener(() {
      if (mounted) setState(() {});
    });

    // Listener para Scroll Infinito (Paginación)
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _controller.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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
                mainAxisAlignment: MainAxisAlignment.start,
                children: const [
                  // Marca UPStagram
                  Text('UPS', style: AppTypography.titleUPS),
                  SizedBox(width: 4),
                  Text('tagram', style: AppTypography.titleGlam),
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

            /// LISTA DE POSTS (CON PULL-TO-REFRESH Y PAGINACIÓN)
            Expanded(
              child: RefreshIndicator(
                onRefresh: _controller.refresh,
                color: AppColors.upsBlue,
                backgroundColor: Colors.white,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    // 1. Cargando inicial (solo si la lista está vacía)
    if (_controller.isLoading && _controller.posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // 2. Datos vacíos (y no está cargando)
    if (_controller.posts.isEmpty && !_controller.isLoading) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: const Center(
            child: Text(
              'No hay publicaciones aún.\n¡Sé el primero en postear!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      );
    }

    // 3. Lista con datos
    return ListView.builder(
      controller: _scrollController,
      physics:
          const AlwaysScrollableScrollPhysics(), // Permite refresh incluso con pocos items
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _controller.posts.length + 1, // +1 para el loader final
      itemBuilder: (context, index) {
        if (index < _controller.posts.length) {
          final post = _controller.posts[index];
          return _buildPostCard(context, post);
        } else {
          // Loader final de paginación
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: _controller.hasMore
                  ? const CircularProgressIndicator(
                      color: Colors.white54,
                      strokeWidth: 2,
                    )
                  : const Text(
                      "Has llegado al final",
                      style: TextStyle(color: Colors.white30),
                    ),
            ),
          );
        }
      },
    );
  }

  Widget _buildPostCard(BuildContext context, FeedPost post) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(
              postId: post.id,
              imageUrl: post.imageUrl,
              description: post.caption,
              authorUid: post.authorUid,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(25),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del post
            Hero(
              tag: post.id,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.network(
                    post.imageUrl,
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
                      GestureDetector(
                        onTap: () {
                          GoRouter.of(
                            context,
                          ).push('/profile/${post.authorUid}');
                        },
                        behavior: HitTestBehavior.opaque,
                        child: _UserNameFetcher(uid: post.authorUid),
                      ),

                      Text(
                        post.timeAgo,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Descripción
                  if (post.caption.isNotEmpty)
                    Text(
                      post.caption,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Barra de Acciones: Comentarios y Likes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // --- COMENTARIOS (Interactivo) ---
                      GestureDetector(
                        onTap: () {
                          // Navegar a la pantalla de detalle del post
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PostDetailScreen(
                                postId: post.id,
                                imageUrl: post.imageUrl,
                                description: post.caption,
                                authorUid: post.authorUid,
                              ),
                            ),
                          );
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.white70,
                              size: 22,
                            ),
                            const SizedBox(width: 6),
                            // Mantenemos Stream local solo para el contador en tiempo real si se desea,
                            // o usamos el valor estático del modelo para eficiencia.
                            // El usuario pidió separar lógica, así que usar el modelo es más "limpio".
                            // Si se quiere realtime estricto en contadores, se debe mantener el Stream.
                            // Por ahora usaremos el valor del modelo para cumplir con la optimización de recursos.
                            Text(
                              '${post.commentsCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // --- LIKES (Interactivo con animación) ---
                      LikeButton(
                        postId: post.id,
                        initialLikesCount: post.likesCount,
                        iconSize: 22,
                        likedColor: Colors.redAccent,
                        unlikedColor: Colors.white70,
                        countStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget pequeño para cargar el nombre de usuario bajo demanda
/// (Podría moverse a un archivo aparte, pero se mantiene aquí por ahora como componente de UI puro)
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
