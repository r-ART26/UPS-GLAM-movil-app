import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/typography.dart';
import '../../theme/colors.dart';
import '../../widgets/effects/gradient_background.dart';
import '../../../services/auth/auth_service.dart';

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

  @override
  void initState() {
    super.initState();
    _initProfile();
  }

  Future<void> _initProfile() async {
    // 1. Determinar qué ID vamos a mostrar
    if (widget.userId != null) {
      _currentUserId = widget.userId;
    } else {
      // Obtener mi ID desde el token (si implementaste guardar el ID)
      // O por ahora, usaremos el email para buscar, o asumiremos que el backend te da el ID
      // *Truco*: Si AuthService no nos da el UID, intentaremos buscar por email o decodificar mejor.
      // Para este ejemplo, si es "Mi Perfil", cargaremos datos básicos del token.
      final email = await AuthService.getUserEmail();
      // Aquí idealmente deberías tener un método AuthService.getUserId()
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
        // === MI PERFIL (Token + Firestore opcional) ===
        // 1. Cargar lo básico del token
        final name = await AuthService.getUserName();
        final email = await AuthService.getUserEmail();

        // 2. Intentar buscar datos extra en Firestore si supiéramos mi UID
        // Por simplificación ahora, usaremos los datos del token
        if (mounted) {
          setState(() {
            _userName = name;
            _userEmail = email;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error cargando perfil: $e');
      if (mounted) setState(() => _isLoading = false);
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
                  const CircleAvatar(
                    radius: 46,
                    backgroundImage: NetworkImage('https://picsum.photos/200'),
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
                  // Si no tenemos ID (caso "Mi Perfil" sin UID resuelto), mostramos vacío o error
                  // *Nota*: Para ver TOMAR tus posts, necesitaríamos saber TU uid.
                  // Si estamos viendo OTRO perfil, usamos widget.userId.
                  final targetUid = widget.userId;

                  if (targetUid == null) {
                    return const Center(
                      child: Text(
                        'Mis posts (WIP)',
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
                          final data = docs[i].data() as Map<String, dynamic>;
                          final img = data['pos_imageUrl'] as String? ?? '';

                          return GestureDetector(
                            onTap: () {
                              // Opcional: Ir al detalle del post
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

// Widget pequeño para estadísticas
class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

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
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}
