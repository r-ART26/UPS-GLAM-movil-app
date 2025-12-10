import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

/// Servicio para búsqueda de usuarios de forma reactiva desde Firestore.
class UserSearchService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int SEARCH_LIMIT = 5;

  /// Stream reactivo de búsqueda de usuarios por nombre o email.
  /// 
  /// Parámetros:
  /// - [query]: Texto de búsqueda (nombre o email)
  /// 
  /// Retorna un Stream<List<UserModel>> con los resultados.
  /// Si la query está vacía, retorna lista vacía.
  static Stream<List<UserModel>> searchUsersStream(String query) {
    if (query.trim().isEmpty) {
      return Stream.value([]);
    }

    String searchQuery = query.trim();
    String searchQueryEnd = searchQuery + '\uf8ff'; // Carácter Unicode para prefijo
    String searchQueryLower = searchQuery.toLowerCase();

    // Búsqueda por username (prioritaria)
    return _firestore
        .collection('Users')
        .where('usr_username', isGreaterThanOrEqualTo: searchQuery)
        .where('usr_username', isLessThan: searchQueryEnd)
        .limit(SEARCH_LIMIT * 2)
        .snapshots()
        .asyncMap((usernameSnapshot) async {
      Set<UserModel> results = {};

      // Procesar resultados de username
      for (var doc in usernameSnapshot.docs) {
        final data = doc.data();
        final username = data['usr_username'] as String? ?? '';
        final email = data['usr_email'] as String? ?? '';

        if (username.toLowerCase().contains(searchQueryLower) ||
            email.toLowerCase().contains(searchQueryLower)) {
          results.add(UserModel.fromFirestore(doc));
        }
      }

      // Si no hay suficientes resultados, buscar por email también
      if (results.length < SEARCH_LIMIT) {
        final emailSnapshot = await _firestore
            .collection('Users')
            .where('usr_email', isGreaterThanOrEqualTo: searchQuery)
            .where('usr_email', isLessThan: searchQueryEnd)
            .limit(SEARCH_LIMIT * 2)
            .get();

        for (var doc in emailSnapshot.docs) {
          final data = doc.data();
          final username = data['usr_username'] as String? ?? '';
          final email = data['usr_email'] as String? ?? '';

          if (username.toLowerCase().contains(searchQueryLower) ||
              email.toLowerCase().contains(searchQueryLower)) {
            results.add(UserModel.fromFirestore(doc));
          }
        }
      }

      // Ordenar por relevancia (coincidencias en username primero)
      final sortedResults = results.toList();
      sortedResults.sort((a, b) {
        final aUsernameMatch = a.username.toLowerCase().startsWith(searchQueryLower);
        final bUsernameMatch = b.username.toLowerCase().startsWith(searchQueryLower);
        if (aUsernameMatch && !bUsernameMatch) return -1;
        if (!aUsernameMatch && bUsernameMatch) return 1;
        return a.username.compareTo(b.username);
      });

      return sortedResults.take(SEARCH_LIMIT).toList();
    });
  }
}

