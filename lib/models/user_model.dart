import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de datos para representar un usuario.
class UserModel {
  final String uid;
  final String username;
  final String email;
  final String? photoUrl;
  final String? bio;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.photoUrl,
    this.bio,
  });

  /// Crea un UserModel desde un DocumentSnapshot de Firestore.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return UserModel(
      uid: doc.id,
      username: data?['usr_username'] as String? ?? '',
      email: data?['usr_email'] as String? ?? '',
      photoUrl: data?['usr_photoUrl'] as String?,
      bio: data?['usr_bio'] as String?,
    );
  }

  /// Genera la URL del avatar. Si no hay photoUrl, genera una con iniciales.
  String getAvatarUrl() {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return photoUrl!;
    }
    final safeName = Uri.encodeComponent(username);
    return 'https://ui-avatars.com/api/?name=$safeName&background=003F87&color=fff&size=150&bold=true';
  }
}

