import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/typography.dart';
import '../../theme/colors.dart';

import '../../widgets/like_button.dart';
import '../post/post_detail_screen.dart';
import 'feed_controller.dart';
import '../../../models/feed_post_model.dart';
import '../../widgets/design_system/glam_button.dart';

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
      decoration: const BoxDecoration(gradient: AppGradients.darkBackground),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER SUPERIOR
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // Separar logo y acciones
                children: [
                  // Marca UPStagram
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text('UPS', style: AppTypography.titleUPS),
                      const SizedBox(width: 4),
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppGradients.gold.createShader(bounds),
                        child: const Text(
                          'tagram',
                          style: AppTypography.titleGlam,
                        ),
                      ),
                    ],
                  ),

                  // Botón de notificaciones (placeholder por ahora)
                  IconButton(
                    onPressed: () {}, // TODO: Implementar notificaciones
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: Colors.white70,
                    ),
                    splashRadius: 24,
                  ),
                ],
              ),
            ),

            /// LISTA DE POSTS (CON PULL-TO-REFRESH Y PAGINACIÓN)
            Expanded(
              child: RefreshIndicator(
                onRefresh: _controller.refresh,
                color: AppColors.upsYellow,
                backgroundColor: AppColors.darkBackground,
                child: Stack(
                  children: [
                    _buildBody(),
                    if (_controller.newPostsCount > 0)
                      Positioned(
                        top: 24,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: () {
                              _controller.refresh();
                              _scrollController.animateTo(
                                0,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOut,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.upsBlue,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.arrow_upward_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _controller.newPostsCount == 1
                                        ? '1 nueva publicación'
                                        : '${_controller.newPostsCount} nuevas publicaciones',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
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
        child: CircularProgressIndicator(color: AppColors.upsYellow),
      );
    }

    // 2. Datos vacíos (y no está cargando)
    if (_controller.posts.isEmpty && !_controller.isLoading) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: Colors.white24,
              ),
              const SizedBox(height: 16),
              const Text(
                'No hay publicaciones aún.\n¡Sé el primero en postear!',
                textAlign: TextAlign.center,
                style: AppTypography.body,
              ),
            ],
          ),
        ),
      );
    }

    // 3. Lista con datos
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _controller.posts.length + 1, // +1 para el loader final
      itemBuilder: (context, index) {
        if (index < _controller.posts.length) {
          final post = _controller.posts[index];
          return _buildPostCard(context, post);
        } else {
          // Loader final de paginación
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: _controller.hasMore
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white24,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Has llegado al final",
                      style: TextStyle(color: Colors.white24, fontSize: 12),
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
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: AppColors.glassWhite, // Glassmorphism base
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.glassBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del Post (Usuario)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      GoRouter.of(context).push('/profile/${post.authorUid}');
                    },
                    child: _UserNameFetcher(uid: post.authorUid),
                  ),
                  Text(
                    post.timeAgo,
                    style: AppTypography.caption.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),

            // Imagen del post
            Hero(
              tag: post.id,
              child: AspectRatio(
                aspectRatio: 4 / 3, // Standard social media aspect ratio
                child: Image.network(
                  post.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.white.withOpacity(0.05),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          color: AppColors.upsYellow,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: Colors.white24,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Acciones y Contenido
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra de Acciones
                  Row(
                    children: [
                      LikeButton(
                        postId: post.id,
                        initialLikesCount: post.likesCount,
                        iconSize: 26,
                        likedColor: AppColors.upsYellow, // Gold heart
                        unlikedColor: Colors.white70,
                        countStyle: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
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
                        child: Row(
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: Colors.white70,
                              size: 24,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${post.commentsCount}',
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (post.caption.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      post.caption,
                      style: AppTypography.body.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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
class _UserNameFetcher extends StatelessWidget {
  final String uid;

  const _UserNameFetcher({required this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) {
      return _buildUserRow('Usuario UPS', null);
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('Users').doc(uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        String name = 'Usuario UPS';
        String? photoUrl;

        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          name = data?['usr_username'] as String? ?? 'Usuario UPS';
          photoUrl = data?['usr_photoUrl'] as String?;
        }

        return _buildUserRow(name, photoUrl);
      },
    );
  }

  Widget _buildLoadingState() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 100,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildUserRow(String name, String? photoUrl) {
    ImageProvider avatarImage;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      avatarImage = NetworkImage(photoUrl);
    } else {
      final safeName = Uri.encodeComponent(name);
      avatarImage = NetworkImage(
        'https://ui-avatars.com/api/?name=$safeName&background=003F87&color=fff&size=150&bold=true',
      );
    }

    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.glassBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.upsBlue,
            backgroundImage: avatarImage,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          name,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2, // Slightly wider for headings
          ),
        ),
      ],
    );
  }
}
