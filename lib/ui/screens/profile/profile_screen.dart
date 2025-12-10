import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/typography.dart';
import '../../theme/colors.dart';
import '../../widgets/effects/gradient_background.dart';
import '../../widgets/dialogs/error_dialog.dart';
import '../../widgets/follow_button.dart';
import '../../widgets/user_list_item.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/subscriptions/subscription_service.dart';
import '../../../models/user_model.dart';
import '../post/post_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // Si es null, es MI perfil

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _userName;
  String? _userEmail;
  String? _userBio; // Nuevo campo
  String? _photoUrl;
  bool _isLoading = true;
  String? _currentUserId; // ID del perfil que estamos viendo
  String? _myUserId; // Mi propio ID

  @override
  void initState() {
    super.initState();
    _initProfile();
  }

  Future<void> _initProfile() async {
    // 1. Obtener mi ID
    _myUserId = await AuthService.getUserId();

    // 2. Determinar qué ID vamos a mostrar
    if (widget.userId != null) {
      _currentUserId = widget.userId;
    } else {
      // Si es mi perfil, usar mi ID
      _currentUserId = _myUserId;
    }

    await _loadUserData();
  }

  /// Carga los datos del usuario (Local o Firestore)
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      if (widget.userId != null) {
        // === PERFIL DE OTRO (Firestore) ===
        final doc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(widget.userId)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          if (mounted) {
            setState(() {
              _userName = data['usr_username'] as String?;
              _userEmail = data['usr_email'] as String?;
              _userBio = data['usr_bio'] as String?; // Si existe en DB
              _photoUrl = data['usr_photoUrl'] as String?;
              _isLoading = false;
            });
          }
        }
      } else {
        // === MI PERFIL (Firestore) ===
        if (_currentUserId != null) {
          final doc = await FirebaseFirestore.instance
              .collection('Users')
              .doc(_currentUserId)
              .get();

          if (doc.exists) {
            final data = doc.data()!;
            if (mounted) {
              setState(() {
                _userName = data['usr_username'] as String?;
                _userEmail = data['usr_email'] as String?;
                _userBio = data['usr_bio'] as String?;
                _photoUrl = data['usr_photoUrl'] as String?;
                _isLoading = false;
              });
            }
          } else {
            // Fallback a datos del token
            final name = await AuthService.getUserName();
            final email = await AuthService.getUserEmail();
            if (mounted) {
              setState(() {
                _userName = name;
                _userEmail = email;
                _isLoading = false;
              });
            }
          }
        } else {
          // Fallback a datos del token
          final name = await AuthService.getUserName();
          final email = await AuthService.getUserEmail();
          if (mounted) {
            setState(() {
              _userName = name;
              _userEmail = email;
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error cargando perfil: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        await ErrorDialog.show(
          context,
          title: 'Error al cargar perfil',
          message:
              'No se pudieron cargar los datos del perfil. Por favor, intenta nuevamente.',
        );
      }
    }
  }

  /// Muestra el diálogo de configuración con opción de cerrar sesión
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.upsBlueDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Configuración',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white),
                title: const Text(
                  'Editar perfil',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  // TODO: Navegar a "editar perfil"
                },
              ),
              const Divider(color: Colors.white24),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () async {
                  Navigator.of(dialogContext).pop();
                  await _handleLogout(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Maneja el cierre de sesión
  Future<void> _handleLogout(BuildContext context) async {
    // Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.upsBlueDark,
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
                // Icono de advertencia
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

                // Título
                const Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Mensaje
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

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(false);
                        },
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
                        onPressed: () {
                          Navigator.of(dialogContext).pop(true);
                        },
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
      // Eliminar token
      await AuthService.deleteToken();

      // Redirigir al login
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.welcomeBackground),
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
                      Text('tagram', style: AppTypography.titleGlam),
                    ],
                  ),
                  // Solo mostrar configuración si es MI perfil
                  if (widget.userId == null)
                    IconButton(
                      onPressed: () {
                        _showSettingsDialog(context);
                      },
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
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
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: AppColors.upsBlue,
                    backgroundImage:
                        (_photoUrl != null && _photoUrl!.isNotEmpty)
                        ? NetworkImage(_photoUrl!)
                        : NetworkImage(
                            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_userName ?? 'Usuario')}&background=003F87&color=fff&size=200&bold=true',
                          ),
                  ),

                  const SizedBox(height: 12),

                  _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _userName ?? 'Usuario',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                  const SizedBox(height: 4),

                  _isLoading
                      ? const SizedBox(height: 20)
                      : Text(
                          _userEmail ?? 'No disponible',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),

                  const SizedBox(height: 20),

                  // Botón de seguir/dejar de seguir (solo si no es mi perfil)
                  if (_currentUserId != null &&
                      _myUserId != null &&
                      _currentUserId != _myUserId)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: FollowButton(
                        targetUserId: _currentUserId!,
                        width: 200,
                        height: 36,
                        fontSize: 15,
                      ),
                    ),

                  // ===========================
                  // ESTADÍSTICAS
                  // ===========================
                  if (_currentUserId != null)
                    _StatsRow(userId: _currentUserId!)
                  else
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatItem(label: 'Posts', value: '0'),
                        SizedBox(width: 32),
                        _StatItem(label: 'Seguidores', value: '0'),
                        SizedBox(width: 32),
                        _StatItem(label: 'Siguiendo', value: '0'),
                      ],
                    ),

                  const SizedBox(height: 8),
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
                child: Text('Mis publicaciones', style: AppTypography.body),
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: Builder(
                builder: (context) {
                  // Usar _currentUserId que ya está establecido correctamente
                  // (widget.userId si es otro perfil, o _myUserId si es mi perfil)
                  final targetUid = _currentUserId;

                  if (targetUid == null) {
                    return const Center(
                      child: Text(
                        'Cargando publicaciones...',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Posts')
                        .where('pos_authorUid', isEqualTo: targetUid)
                        .orderBy('pos_timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white24,
                          ),
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
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 6,
                              crossAxisSpacing: 6,
                            ),
                        itemBuilder: (context, i) {
                          final doc = docs[i];
                          final data = doc.data() as Map<String, dynamic>;
                          final img = data['pos_imageUrl'] as String? ?? '';
                          final caption = data['pos_caption'] as String? ?? '';
                          final authorUid =
                              data['pos_authorUid'] as String? ?? targetUid;
                          final postId = doc.id;

                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => PostDetailScreen(
                                    postId: postId,
                                    imageUrl: img,
                                    description: caption,
                                    authorUid: authorUid,
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

// Widget para estadísticas reactivas y clickeables
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
            return _StatItem(
              label: 'Posts',
              value: '$postsCount',
              onTap: null, // Posts no es clickeable por ahora
            );
          },
        ),
        const SizedBox(width: 32),
        // Seguidores (clickeable)
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
        // Siguiendo (clickeable)
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

// Widget pequeño para estadísticas
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

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: widget);
    }

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
        color: AppColors.upsBlueDark,
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
