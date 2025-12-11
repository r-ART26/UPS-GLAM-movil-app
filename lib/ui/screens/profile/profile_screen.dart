import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../theme/typography.dart';
import '../../theme/colors.dart';

import '../../widgets/follow_button.dart';
import '../../widgets/user_list_item.dart';
import '../../../services/subscriptions/subscription_service.dart';
import '../../../models/user_model.dart';
import '../post/post_detail_screen.dart';
import 'edit_profile_screen.dart';
import '../../widgets/full_screen_image_viewer.dart';
import 'profile_controller.dart';

import '../../widgets/design_system/glam_button.dart'; // For GlamButton usage if needed

class ProfileScreen extends StatefulWidget {
  final String? userId; // Si es null, es MI perfil

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileController _controller;
  final GlobalKey _settingsButtonKey = GlobalKey(); // Key para el botón

  @override
  void initState() {
    super.initState();
    _controller = ProfileController();
    // Inicializar controlador (determinar ID y cargar datos)
    _controller.init(widget.userId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.darkBackground),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // 1. Cargando
            if (_controller.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            // 2. Datos listos
            return Column(
              children: [
                _buildHeader(context),
                _buildUserInfo(context),
                _buildPostsGrid(context),
              ],
            );
          },
        ),
      ),
    );
  }

  /// HEADER SUPERIOR
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text('UPS', style: AppTypography.titleUPS),
              const SizedBox(width: 4),
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppGradients.gold.createShader(bounds),
                child: const Text('tagram', style: AppTypography.titleGlam),
              ),
            ],
          ),
          // Solo mostrar configuración si es MI perfil
          if (_controller.isMyProfile)
            IconButton(
              key: _settingsButtonKey, // Agregar Key para obtener posición
              onPressed: () =>
                  _showSettingsMenu(context), // Cambiar nombre de función
              icon: const Icon(
                Icons.settings_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),
        ],
      ),
    );
  }

  /// INFO DEL USUARIO
  Widget _buildUserInfo(BuildContext context) {
    final user = _controller.user;
    if (user == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Avatar con Zoom
              GestureDetector(
                onTap: () {
                  if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenImageViewer(
                          imageUrl: user.photoUrl!,
                          heroTag: 'profile_avatar_${user.uid}',
                        ),
                      ),
                    );
                  }
                },
                child: Hero(
                  tag: 'profile_avatar_${user.uid}',
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: AppColors.upsBlue,
                    backgroundImage: NetworkImage(user.getAvatarUrl()),
                  ),
                ),
              ),

              // Bocadillo de Bio (Si existe)
              if (user.bio != null && user.bio!.isNotEmpty)
                Positioned(top: 0, left: 70, child: _buildBioBubble(user.bio!)),
            ],
          ),

          const SizedBox(height: 12),

          // Nombre
          Text(user.username, style: AppTypography.h2),

          const SizedBox(height: 4),

          // Email
          Text(user.email, style: AppTypography.bodySmall),

          const SizedBox(height: 20),

          // Botón de seguir/dejar de seguir (solo si NO es mi perfil)
          if (!_controller.isMyProfile &&
              _controller.isMyProfile == false) // Redundante pero explícito
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FollowButton(
                targetUserId: user.uid,
                width: 200,
                height: 36,
                fontSize: 15,
              ),
            ),

          // Estadísticas
          _StatsRow(userId: user.uid),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// GLOBO DE BIO
  Widget _buildBioBubble(String bio) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Pico del globo
        Positioned(
          top: 12,
          left: -6,
          child: Transform.rotate(
            angle: -0.785,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(-1, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Cuerpo del globo
        Container(
          constraints: const BoxConstraints(maxWidth: 110),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Text(
            bio,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: AppColors.upsBlue,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  /// GRID DE PUBLICACIONES
  Widget _buildPostsGrid(BuildContext context) {
    final uid = _controller.currentUserId;
    if (uid == null) return const SizedBox();

    return Expanded(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Mis publicaciones', style: AppTypography.body),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Posts')
                  .where('pos_authorUid', isEqualTo: uid)
                  .orderBy('pos_timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white24),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Sin publicaciones',
                      style: TextStyle(color: Colors.white30),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: docs.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final img = data['pos_imageUrl'] as String? ?? '';
                    final caption = data['pos_caption'] as String? ?? '';

                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PostDetailScreen(
                              postId: doc.id,
                              imageUrl: img,
                              description: caption,
                              authorUid: uid,
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(img, fit: BoxFit.cover),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// MENÚ DE CONFIGURACIÓN (TIPO POPUP)
  void _showSettingsMenu(BuildContext context) {
    final RenderBox renderBox =
        _settingsButtonKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    // Calcular la posición (esquina superior derecha alineada con el botón)
    final double left =
        offset.dx - 220 + size.width; // Ancho del menú aprox 220
    final double top = offset.dy + size.height + 8;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar configuración',
      barrierColor: Colors.black26, // Fondo más sutil
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => const SizedBox(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              child: Material(
                color: Colors.transparent,
                child: FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    alignment: Alignment.topRight,
                    scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: 220,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.darkBackground.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min, // Ajuste importante
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Botón Editar Perfil
                              InkWell(
                                onTap: () async {
                                  Navigator.of(context).pop();
                                  final user = _controller.user;
                                  if (user == null) return;
                                  final result = await Navigator.of(context)
                                      .push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditProfileScreen(
                                                currentName: user.username,
                                                currentBio: user.bio ?? '',
                                                currentPhotoUrl: user.photoUrl,
                                              ),
                                        ),
                                      );
                                  if (result == true) {
                                    await _controller.loadProfile();
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(
                                        Icons.edit_outlined,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Editar perfil',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const Divider(height: 1, color: Colors.white12),

                              // Botón Cerrar Sesión
                              InkWell(
                                onTap: () async {
                                  Navigator.of(context).pop();
                                  await _handleLogout(context);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(
                                        Icons.logout_rounded,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Cerrar sesión',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// PROCESO DE LOGOUT CON CONFIRMACIÓN
  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.darkBackground,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '¿Estás seguro de que deseas cerrar sesión?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Cerrar sesión',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm == true) {
      await _controller.signOut(context);
    }
  }
}

// Widget para estadísticas (Mantenido casi igual pero independiente)
class _StatsRow extends StatelessWidget {
  final String userId;
  const _StatsRow({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Posts
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Posts')
              .where('pos_authorUid', isEqualTo: userId)
              .snapshots(),
          builder: (context, snapshot) {
            final postsCount = snapshot.data?.docs.length ?? 0;
            return _StatItem(label: 'Posts', value: '$postsCount');
          },
        ),
        const SizedBox(width: 32),
        // Seguidores
        StreamBuilder<int>(
          stream: SubscriptionService.getFollowersCountStream(userId),
          builder: (context, snapshot) {
            final followersCount = snapshot.data ?? 0;
            return _StatItem(
              label: 'Seguidores',
              value: '$followersCount',
              onTap: () => _showFollowersList(context, userId),
            );
          },
        ),
        const SizedBox(width: 32),
        // Siguiendo
        StreamBuilder<int>(
          stream: SubscriptionService.getFollowingCountStream(userId),
          builder: (context, snapshot) {
            final followingCount = snapshot.data ?? 0;
            return _StatItem(
              label: 'Siguiendo',
              value: '$followingCount',
              onTap: () => _showFollowingList(context, userId),
            );
          },
        ),
      ],
    );
  }

  void _showFollowersList(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _UsersListBottomSheet(
        title: 'Seguidores',
        stream: SubscriptionService.getFollowersStream(userId),
      ),
    );
  }

  void _showFollowingList(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _UsersListBottomSheet(
        title: 'Siguiendo',
        stream: SubscriptionService.getFollowingStream(userId),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _StatItem({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    final widget = Column(
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
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
    if (onTap != null) return GestureDetector(onTap: onTap, child: widget);
    return widget;
  }
}

// Bottom sheet para mostrar lista de usuarios
class _UsersListBottomSheet extends StatelessWidget {
  final String title;
  final Stream<List<UserModel>> stream;

  const _UsersListBottomSheet({required this.title, required this.stream});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          // Lista
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay usuarios',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                final users = snapshot.data!;

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    return UserListItem(user: users[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
