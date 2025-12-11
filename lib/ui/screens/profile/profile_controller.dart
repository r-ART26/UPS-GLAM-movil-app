import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../models/user_model.dart';
import '../../../services/auth/auth_service.dart';
import '../../widgets/dialogs/error_dialog.dart';

class ProfileController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Estado
  UserModel? _user;
  bool _isLoading = true;
  String? _currentUserId; // ID del usuario que se está visualizando
  String? _myUserId; // ID del usuario logueado en la app

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isMyProfile =>
      _currentUserId != null &&
      _myUserId != null &&
      _currentUserId == _myUserId;
  String? get currentUserId => _currentUserId;

  /// Inicializa el controlador determinando qué perfil mostrar
  Future<void> init(String? userIdParam) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Obtener mi ID
      _myUserId = await AuthService.getUserId();

      // 2. Determinar ID a mostrar
      if (userIdParam != null) {
        _currentUserId = userIdParam;
      } else {
        _currentUserId = _myUserId;
      }

      // 3. Cargar datos
      await loadProfile();
    } catch (e) {
      debugPrint('Error en ProfileController.init: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga datos del usuario desde Firestore
  Future<void> loadProfile() async {
    if (_currentUserId == null) return;

    try {
      final doc = await _db.collection('Users').doc(_currentUserId).get();

      if (doc.exists) {
        // Usuario encontrado en DB
        _user = UserModel.fromFirestore(doc);
      } else if (isMyProfile) {
        // Fallback: Si es 'mi perfil' pero no está en DB, intentar sacar datos del token local (AuthService)
        // Esto es un parche por si el registro falló en crear el documento pero sí hay token
        final name = await AuthService.getUserName();
        final email = await AuthService.getUserEmail();
        _user = UserModel(
          uid: _currentUserId!,
          username: name ?? 'Usuario',
          email: email ?? '',
        );
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
      rethrow; // Para que la UI pueda mostrar error si quiere
    }
    notifyListeners();
  }

  /// Cerrar Sesión
  Future<void> signOut(BuildContext context) async {
    try {
      await AuthService.deleteToken();
      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
      if (context.mounted) {
        ErrorDialog.show(
          context,
          title: 'Error',
          message: 'No se pudo cerrar sesión.',
        );
      }
    }
  }
}
