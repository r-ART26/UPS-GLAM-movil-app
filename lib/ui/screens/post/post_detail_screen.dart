import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';

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

                      return ListTile(
                        // Quitamos el leading porque _UserNameFetcher ya trae avatar
                        title: _UserNameFetcher(uid: authorUid),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo oscuro estilo inmersivo
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Comentarios', style: TextStyle(color: Colors.white)),
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

                        // Botón para ver Likes
                        GestureDetector(
                          onTap: () => _showLikesModal(context),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.favorite,
                                size: 16,
                                color: Colors.white54,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Ver Me gusta',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
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
                              'Sé el primero en comentar 👇',
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

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            // El Avatar ya viene dentro de _UserNameFetcher en el título
                            title: Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: _UserNameFetcher(uid: authorUid),
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

          // 2. Input para Escribir (Fijo abajo)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: SafeArea(
              // Para respetar el área del iPhone X+
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Agrega un comentario...',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Implementar lógica de envío (Spring Boot o Firebase directo)
                      final text = _commentController.text.trim();
                      if (text.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Funcionalidad de envío pendiente de conectar',
                            ),
                          ),
                        );
                        _commentController.clear();
                      }
                    },
                    child: const Text(
                      'Publicar',
                      style: TextStyle(color: AppColors.upsYellow),
                    ),
                  ),
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

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.upsBlue,
              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                  ? NetworkImage(photoUrl)
                  : null,
              child: (photoUrl == null || photoUrl.isEmpty)
                  ? const Icon(Icons.person, size: 16, color: Colors.white)
                  : null,
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
