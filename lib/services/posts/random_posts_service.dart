import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio para obtener posts aleatorios para la cuadrícula de fotos.
class RandomPostsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream reactivo de posts para mostrar en la cuadrícula de fotos.
  /// Retorna solo las URLs de las imágenes.
  /// 
  /// Retorna un Stream<List<String>> con las URLs de las imágenes.
  static Stream<List<String>> getRandomPostsStream() {
    return _firestore
        .collection('Posts')
        .orderBy('pos_timestamp', descending: true)
        .limit(50) // Obtener últimos 50 posts
        .snapshots()
        .map((snapshot) {
      List<String> imageUrls = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final imageUrl = data['pos_imageUrl'] as String?;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          imageUrls.add(imageUrl);
        }
      }

      // Mezclar aleatoriamente
      imageUrls.shuffle();
      return imageUrls;
    });
  }
}

