import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

/// Servicio para búsqueda de usuarios de forma reactiva desde Firestore.
class UserSearchService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int SEARCH_LIMIT = 5;

  /// Stream reactivo de búsqueda de usuarios por nombre o email.
  /// La búsqueda es case-insensitive (insensible a mayúsculas/minúsculas).
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
    String searchQueryLower = searchQuery.toLowerCase();
    
    // Obtener primera letra en minúscula y mayúscula para búsqueda de prefijo
    String firstChar = searchQuery[0];
    String firstCharLower = firstChar.toLowerCase();
    String firstCharUpper = firstChar.toUpperCase();
    
    // Crear rangos de búsqueda para ambas versiones (minúscula y mayúscula)
    String searchQueryLowerStart = firstCharLower;
    String searchQueryUpperStart = firstCharUpper;
    String searchQueryLowerEnd = firstCharLower + '\uf8ff';
    String searchQueryUpperEnd = firstCharUpper + '\uf8ff';

    // Búsqueda por username (case-insensitive)
    // Buscar con ambas versiones (minúscula y mayúscula) para capturar todos los casos
    return _firestore
        .collection('Users')
        .where('usr_username', isGreaterThanOrEqualTo: searchQueryLowerStart)
        .where('usr_username', isLessThan: searchQueryLowerEnd)
        .limit(50) // Obtener más resultados para filtrar en cliente
        .snapshots()
        .asyncMap((usernameSnapshot) async {
      // Usar Map con UID como clave para evitar duplicados
      Map<String, UserModel> resultsMap = {};

      // Procesar resultados de username (filtrado case-insensitive en cliente)
      for (var doc in usernameSnapshot.docs) {
        final data = doc.data();
        final username = data['usr_username'] as String? ?? '';
        final email = data['usr_email'] as String? ?? '';

        // Filtrado case-insensitive: verificar si contiene la query (sin importar mayúsculas)
        if (username.toLowerCase().contains(searchQueryLower) ||
            email.toLowerCase().contains(searchQueryLower)) {
          final user = UserModel.fromFirestore(doc);
          resultsMap[user.uid] = user; // Usar UID como clave para evitar duplicados
        }
      }

      // También buscar con la primera letra en mayúscula
      final usernameSnapshotUpper = await _firestore
          .collection('Users')
          .where('usr_username', isGreaterThanOrEqualTo: searchQueryUpperStart)
          .where('usr_username', isLessThan: searchQueryUpperEnd)
          .limit(50)
          .get();

      for (var doc in usernameSnapshotUpper.docs) {
        final data = doc.data();
        final username = data['usr_username'] as String? ?? '';
        final email = data['usr_email'] as String? ?? '';

        // Filtrado case-insensitive
        if (username.toLowerCase().contains(searchQueryLower) ||
            email.toLowerCase().contains(searchQueryLower)) {
          final user = UserModel.fromFirestore(doc);
          resultsMap[user.uid] = user; // Usar UID como clave para evitar duplicados
        }
      }

      // Buscar por email también (case-insensitive)
      final emailSnapshot = await _firestore
          .collection('Users')
          .where('usr_email', isGreaterThanOrEqualTo: searchQueryLowerStart)
          .where('usr_email', isLessThan: searchQueryLowerEnd)
          .limit(50)
          .get();

      for (var doc in emailSnapshot.docs) {
        final data = doc.data();
        final username = data['usr_username'] as String? ?? '';
        final email = data['usr_email'] as String? ?? '';

        // Filtrado case-insensitive
        if (username.toLowerCase().contains(searchQueryLower) ||
            email.toLowerCase().contains(searchQueryLower)) {
          final user = UserModel.fromFirestore(doc);
          resultsMap[user.uid] = user; // Usar UID como clave para evitar duplicados
        }
      }

      // También buscar email con primera letra mayúscula
      final emailSnapshotUpper = await _firestore
          .collection('Users')
          .where('usr_email', isGreaterThanOrEqualTo: searchQueryUpperStart)
          .where('usr_email', isLessThan: searchQueryUpperEnd)
          .limit(50)
          .get();

      for (var doc in emailSnapshotUpper.docs) {
        final data = doc.data();
        final username = data['usr_username'] as String? ?? '';
        final email = data['usr_email'] as String? ?? '';

        // Filtrado case-insensitive
        if (username.toLowerCase().contains(searchQueryLower) ||
            email.toLowerCase().contains(searchQueryLower)) {
          final user = UserModel.fromFirestore(doc);
          resultsMap[user.uid] = user; // Usar UID como clave para evitar duplicados
        }
      }

      // Convertir Map a List y ordenar por relevancia (coincidencias en username primero)
      final sortedResults = resultsMap.values.toList();
      sortedResults.sort((a, b) {
        final aUsernameLower = a.username.toLowerCase();
        final bUsernameLower = b.username.toLowerCase();
        final aUsernameMatch = aUsernameLower.startsWith(searchQueryLower);
        final bUsernameMatch = bUsernameLower.startsWith(searchQueryLower);
        if (aUsernameMatch && !bUsernameMatch) return -1;
        if (!aUsernameMatch && bUsernameMatch) return 1;
        return aUsernameLower.compareTo(bUsernameLower);
      });

      return sortedResults.take(SEARCH_LIMIT).toList();
    });
  }
}

