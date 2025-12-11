import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/feed_post_model.dart';

class FeedController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final int _limit = 3; // Paginación de 3 en 3

  List<FeedPost> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  // Getters para la UI
  List<FeedPost> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  FeedController() {
    // Cargar posts iniciales al instanciar el controlador
    fetchPosts();
  }

  /// Carga inicial de posts
  Future<void> fetchPosts() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      Query query = _db
          .collection('Posts')
          .orderBy('pos_timestamp', descending: true)
          .limit(_limit);

      final QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _posts = snapshot.docs
            .map((doc) => FeedPost.fromFirestore(doc))
            .toList();
        _lastDocument = snapshot.docs.last;
        _hasMore = snapshot.docs.length == _limit;
      } else {
        _posts = [];
        _hasMore = false;
      }
    } catch (e) {
      debugPrint("Error fetching posts: $e");
      // Aquí se podría manejar errores de UI si se desea
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar más posts (Paginación)
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore || _lastDocument == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      Query query = _db
          .collection('Posts')
          .orderBy('pos_timestamp', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_limit);

      final QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        final newPosts = snapshot.docs
            .map((doc) => FeedPost.fromFirestore(doc))
            .toList();
        _posts.addAll(newPosts);
        _lastDocument = snapshot.docs.last;
        _hasMore = snapshot.docs.length == _limit;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint("Error loading more posts: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Pull-to-Refresh: Reinicia la lista
  Future<void> refresh() async {
    _lastDocument = null;
    _hasMore = true;
    _posts.clear();
    await fetchPosts();
  }
}
