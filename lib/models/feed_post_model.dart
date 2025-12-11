import 'package:cloud_firestore/cloud_firestore.dart';

class FeedPost {
  final String id;
  final String imageUrl;
  final String authorUid;
  final String caption;
  final int likesCount;
  final int commentsCount;
  final DateTime timestamp;

  FeedPost({
    required this.id,
    required this.imageUrl,
    required this.authorUid,
    required this.caption,
    required this.likesCount,
    required this.commentsCount,
    required this.timestamp,
  });

  /// Factory factory para crear una instancia desde un DocumentSnapshot de Firestore
  factory FeedPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return FeedPost(
      id: doc.id,
      imageUrl: data['pos_imageUrl'] as String? ?? '',
      authorUid: data['pos_authorUid'] as String? ?? '',
      caption: data['pos_caption'] as String? ?? '',
      likesCount: data['pos_likesCount'] as int? ?? 0,
      commentsCount: data['pos_commentsCount'] as int? ?? 0,
      timestamp:
          (data['pos_timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Utilidad para saber cuánto tiempo ha pasado desde la publicación
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays >= 1) {
      return 'Hace ${difference.inDays} d';
    } else if (difference.inHours >= 1) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inMinutes >= 1) {
      return 'Hace ${difference.inMinutes} min';
    } else {
      return 'Hace un momento';
    }
  }
}
