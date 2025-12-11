import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/posts/comment_service.dart';

class PostDetailController extends ChangeNotifier {
  final String postId;
  final TextEditingController commentController = TextEditingController();

  String _currentUserName = 'Usuario';
  String? _currentUserPhotoUrl;
  String? _currentUserId;
  bool _isPostingComment = false;
  bool _isComposing = false;

  PostDetailController({required this.postId}) {
    _init();
    commentController.addListener(_onCommentChanged);
  }

  // Getters
  String get currentUserName => _currentUserName;
  String? get currentUserPhotoUrl => _currentUserPhotoUrl;
  String? get currentUserId => _currentUserId;
  bool get isPostingComment => _isPostingComment;
  bool get isComposing => _isComposing;

  Stream<QuerySnapshot> get commentsStream {
    return FirebaseFirestore.instance
        .collection('Posts')
        .doc(postId)
        .collection('Comments')
        .orderBy('com_timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> get likesStream {
    return FirebaseFirestore.instance
        .collection('Posts')
        .doc(postId)
        .collection('Likes')
        .orderBy('lik_timestamp', descending: true)
        .snapshots();
  }

  // Stream for the post itself (for like count updates)
  Stream<DocumentSnapshot> get postStream {
    return FirebaseFirestore.instance
        .collection('Posts')
        .doc(postId)
        .snapshots();
  }

  void _onCommentChanged() {
    final composing = commentController.text.trim().isNotEmpty;
    if (_isComposing != composing) {
      _isComposing = composing;
      notifyListeners();
    }
  }

  Future<void> _init() async {
    await _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final uid = await AuthService.getUserId();
    if (uid != null) {
      _currentUserId = uid;
      notifyListeners();

      try {
        final doc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(uid)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          _currentUserName = data['usr_username'] as String? ?? 'Usuario';
          _currentUserPhotoUrl = data['usr_photoUrl'] as String?;
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error cargando usuario actual: $e');
      }
    }
  }

  Future<bool> postComment(BuildContext context) async {
    final text = commentController.text.trim();

    // 1. Si el usuario es null, intentamos cargarlo nuevamente
    if (_currentUserId == null) {
      await _loadCurrentUser();
    }

    if (text.isEmpty) {
      return false;
    }

    // 2. Si sigue siendo null, mostramos error
    if (_currentUserId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error: Usuario no identificado. Intenta reiniciar la app o iniciar sesión nuevamente.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return false;
    }

    _isPostingComment = true;
    notifyListeners();

    try {
      // Delegamos al servicio que llama a la API (Spring Boot)
      final success = await CommentService.createComment(postId, text, context);

      if (success) {
        commentController.clear();
        if (context.mounted) FocusScope.of(context).unfocus();
        return true;
      } else {
        // El servicio ya se encarga de mostrar diálogos de error
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error inesperado: $e')));
      }
      return false;
    } finally {
      _isPostingComment = false;
      _isComposing = false; // Because we cleared the text
      notifyListeners();
    }
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }
}
