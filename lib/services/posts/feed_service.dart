import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio dedicado a leer el feed de posts desde Firestore en tiempo real.
class FeedService {
  // Instancia de Firestore
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Nombre de la colección
  static const String _collection = 'Posts';

  /// Obtiene el stream de posts ordenados cronológicamente.
  /// Escucha cambios en tiempo real.
  static Stream<QuerySnapshot> getPostsStream() {
    return _db
        .collection(_collection)
        .orderBy('pos_timestamp', descending: true) // Lo más nuevo primero
        .snapshots();
  }
}
