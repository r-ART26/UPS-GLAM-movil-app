import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio para obtener posts aleatorios para la cuadrícula de fotos.
class RandomPostsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream reactivo de posts para mostrar en la cuadrícula de fotos.
  /// Retorna una lista de mapas con la información del post.
  /// Cada mapa tiene: 'postId', 'imageUrl', 'description', 'authorUid'.
  static Stream<List<Map<String, dynamic>>> getRandomPostsStream() {
    return _firestore
        .collection('Posts')
        .orderBy('pos_timestamp', descending: true)
        .limit(50) // Obtener últimos 50 posts
        .snapshots()
        .map((snapshot) {
          List<Map<String, dynamic>> posts = [];

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final imageUrl = data['pos_imageUrl'] as String?;

            if (imageUrl != null && imageUrl.isNotEmpty) {
              posts.add({
                'postId': doc.id,
                'imageUrl': imageUrl,
                'description': data['pos_caption'] ?? '',
                'authorUid': data['pos_authorUid'] ?? '',
              });
            }
          }

          // Mezclar aleatoriamente
          posts.shuffle();
          return posts;
        });
  }
}
