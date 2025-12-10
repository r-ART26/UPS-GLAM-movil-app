import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../../services/auth/auth_service.dart';
import '../../widgets/dialogs/confirm_dialog.dart';
import '../../widgets/like_button.dart';
import '../../../services/posts/comment_service.dart';
import '../../../services/auth/auth_service.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final String imageUrl;
  final String description; // pos_caption
  final String authorUid; // UID del autor para navegación

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.imageUrl,
    required this.description,
    required this.authorUid,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  String _currentUserName =
      'Usuario'; // Nombre por defecto para el avatar propio

  bool _isPostingComment = false;
  bool _isComposing = false; // Estado para saber si hay texto
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadCurrentUserId();
    _commentController.addListener(() {
      setState(() {
        _isComposing = _commentController.text.trim().isNotEmpty;
      });
    });
  }

  Future<void> _loadCurrentUser() async {
    final name = await AuthService.getUserName();
    if (name != null && mounted) {
      setState(() {
        _currentUserName = name;
      });
    }
  }

  Future<void> _loadCurrentUserId() async {
    final userId = await AuthService.getUserId();
    if (mounted) {
      setState(() {
        _currentUserId = userId;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Referencia a Firestore para leer comentarios
  Stream<QuerySnapshot> get _commentsStream {
    return FirebaseFirestore.instance
        .collection('Posts')
        .doc(widget.postId)
        .collection('Comments')
        .orderBy('com_timestamp', descending: true)
        .snapshots();
  }

  /// Muestra el modal con la lista de usuarios que dieron like
  void _showLikesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E), // Fondo oscuro
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          children: [
            // Header del Modal
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white12)),
              ),
              child: const Center(
                child: Text(
                  'Me gusta',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            // Lista de Likes
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Posts')
                    .doc(widget.postId)
                    .collection('Likes')
                    // Ordenamos por fecha si existe, sino por defecto
                    .orderBy('lik_timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Error al cargar',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white24),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aún no hay Me gusta',
                        style: TextStyle(color: Colors.white30),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final authorUid = data['lik_authorUid'] as String? ?? '';

                      return InkWell(
                        onTap: () =>
                            GoRouter.of(context).push('/profile/$authorUid'),
                        child: ListTile(
                          // Quitamos el leading porque _UserNameFetcher ya trae avatar
                          title: _UserNameFetcher(uid: authorUid),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handlePostComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _currentUserId == null) return;

    setState(() {
      _isPostingComment = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('Posts')
          .doc(widget.postId)
          .collection('Comments')
          .add({
            'com_text': text,
            'com_authorUid': _currentUserId,
            'com_timestamp': FieldValue.serverTimestamp(),
          });

      _commentController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al publicar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPostingComment = false;
          _isComposing = false;
        });
      }
    }
  }

  void _showCommentInput(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.upsBlue,
                  backgroundImage: NetworkImage(
                    'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_currentUserName)}&background=003F87&color=fff&size=150&bold=true',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    autofocus: true,
                    minLines: 1,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu comentario...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _commentController,
                  builder: (context, value, child) {
                    final hasText = value.text.trim().isNotEmpty;
                    return TextButton(
                      onPressed: (hasText && !_isPostingComment)
                          ? () async {
                              await _handlePostComment();
                              if (context.mounted) Navigator.pop(context);
                            }
                          : null,
                      child: _isPostingComment
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.upsYellow,
                              ),
                            )
                          : Text(
                              'Publicar',
                              style: TextStyle(
                                color: hasText
                                    ? AppColors.upsYellow
                                    : Colors.white24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo oscuro estilo inmersivo
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Comentarios', style: TextStyle(color: Colors.white)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCommentInput(context),
        backgroundColor: AppColors.upsYellow,
        child: const Icon(Icons.chat_bubble_outline, color: Colors.black),
      ),
      body: Column(
        children: [
          // 1. Contenido del Post (Scrollable)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen Hero (Animación suave desde el feed)
                  Hero(
                    tag: widget.postId,
                    child: Image.network(
                      widget.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Descripción Original
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre Autor (Clicable)
                        GestureDetector(
                          onTap: () {
                            GoRouter.of(
                              context,
                            ).push('/profile/${widget.authorUid}');
                          },
                          child: _UserNameFetcher(uid: widget.authorUid),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Botón para dar like y ver Likes
                        Row(
                          children: [
                            // Botón de like con animación
                            LikeButton(
                              postId: widget.postId,
                              initialLikesCount: 0,
                              iconSize: 20,
                              likedColor: Colors.redAccent,
                              unlikedColor: Colors.white54,
                              showCount: false,
                            ),
                            const SizedBox(width: 8),
                            // Contador de likes y botón para ver lista
                            GestureDetector(
                              onTap: () => _showLikesModal(context),
                              child: StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('Posts')
                                    .doc(widget.postId)
                                    .snapshots(),
                                builder: (context, postSnapshot) {
                                  int likesCount = 0;
                                  if (postSnapshot.hasData &&
                                      postSnapshot.data != null) {
                                    final data =
                                        postSnapshot.data!.data()
                                            as Map<String, dynamic>?;
                                    if (data != null) {
                                      likesCount =
                                          data['pos_likesCount'] as int? ?? 0;
                                    }
                                  }

                                  return Text(
                                    '$likesCount Me gusta',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Sección de Comentarios (Título)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Comentarios',
                      style: TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  // Lista de Comentarios en Tiempo Real
                  StreamBuilder<QuerySnapshot>(
                    stream: _commentsStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Error cargando comentarios',
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(
                              color: Colors.white24,
                            ),
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              'Sin comentarios',
                              style: TextStyle(color: Colors.white30),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap:
                            true, // Importante dentro de SingleChildScrollView
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          final commentText = data['com_text'] as String? ?? '';
                          // Usamos el UID del autor del comentario
                          final authorUid =
                              data['com_authorUid'] as String? ?? '';
                          final commentId = docs[index].id;
                          final isOwner =
                              _currentUserId != null &&
                              _currentUserId == authorUid;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            // El Avatar ya viene dentro de _UserNameFetcher en el título
                            title: Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => GoRouter.of(
                                        context,
                                      ).push('/profile/$authorUid'),
                                      child: _UserNameFetcher(uid: authorUid),
                                    ),
                                  ),
                                  // Botón de eliminar (solo si eres el dueño)
                                  if (isOwner)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: Colors.white38,
                                      ),
                                      onPressed: () async {
                                        final confirmed = await ConfirmDialog.show(
                                          context,
                                          title: 'Eliminar comentario',
                                          message:
                                              '¿Estás seguro de que deseas eliminar este comentario?',
                                          confirmText: 'Eliminar',
                                          cancelText: 'Cancelar',
                                          confirmColor: Colors.redAccent,
                                        );

                                        if (confirmed == true) {
                                          await CommentService.deleteComment(
                                            widget.postId,
                                            commentId,
                                            context,
                                          );
                                        }
                                      },
                                    ),
                                ],
                              ),
                            ),
                            subtitle: Text(
                              commentText,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // Espacio extra para que el teclado no tape el último comentario
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
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
    // Si no hay UID válido
    if (uid.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min, // Importante para no expandir el Layout
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
            mainAxisSize: MainAxisSize.min,
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
                width: 60,
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
          mainAxisSize: MainAxisSize.min,
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
