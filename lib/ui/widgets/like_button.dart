import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/posts/like_service.dart';
import '../../services/auth/auth_service.dart';

/// Widget de botón de like con animación optimista
class LikeButton extends StatefulWidget {
  final String postId;
  final int initialLikesCount;
  final double iconSize;
  final Color? likedColor;
  final Color? unlikedColor;
  final bool showCount;
  final TextStyle? countStyle;

  const LikeButton({
    super.key,
    required this.postId,
    required this.initialLikesCount,
    this.iconSize = 22,
    this.likedColor,
    this.unlikedColor,
    this.showCount = true,
    this.countStyle,
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton>
    with SingleTickerProviderStateMixin {
  String? _currentUserId;
  bool? _optimisticLikeState;
  int? _optimisticLikeCount;
  bool _isTogglingLike = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    
    // Configurar animación de escala
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserId() async {
    final userId = await AuthService.getUserId();
    if (mounted) {
      setState(() {
        _currentUserId = userId;
      });
    }
  }

  Future<void> _handleLikeToggle() async {
    if (_isTogglingLike || _currentUserId == null) return;

    setState(() {
      _isTogglingLike = true;
    });

    // Obtener estado actual del like
    final currentLikeDoc = await FirebaseFirestore.instance
        .collection('Posts')
        .doc(widget.postId)
        .collection('Likes')
        .doc(_currentUserId!)
        .get();

    final currentlyLiked = currentLikeDoc.exists;

    // Obtener contador actual
    final postDoc = await FirebaseFirestore.instance
        .collection('Posts')
        .doc(widget.postId)
        .get();
    final data = postDoc.data();
    final currentCount = data?['pos_likesCount'] as int? ?? widget.initialLikesCount;

    // Actualización optimista
    setState(() {
      _optimisticLikeState = !currentlyLiked;
      _optimisticLikeCount = currentlyLiked ? currentCount - 1 : currentCount + 1;
    });

    // Animar solo si se está dando like (no cuando se quita)
    if (!currentlyLiked) {
      _animationController.forward(from: 0.0);
    }

    // Hacer la petición al servidor
    final success = await LikeService.toggleLike(widget.postId, context);

    if (mounted) {
      if (!success) {
        // Revertir si falló
        setState(() {
          _optimisticLikeState = null;
          _optimisticLikeCount = null;
        });
      }

      setState(() {
        _isTogglingLike = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Row(
        children: [
          Icon(
            Icons.favorite_border,
            size: widget.iconSize,
            color: widget.unlikedColor ?? Colors.white70,
          ),
          if (widget.showCount) ...[
            const SizedBox(width: 6),
            Text(
              '${widget.initialLikesCount}',
              style: widget.countStyle ??
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ],
      );
    }

    return GestureDetector(
      onTap: _handleLikeToggle,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Posts')
                .doc(widget.postId)
                .collection('Likes')
                .doc(_currentUserId!)
                .snapshots(),
            builder: (context, likeSnapshot) {
              final streamLiked = likeSnapshot.hasData && likeSnapshot.data!.exists;
              
              // Limpiar estado optimista cuando el stream confirma el cambio
              if (likeSnapshot.hasData && 
                  _optimisticLikeState != null &&
                  _optimisticLikeState == streamLiked) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _optimisticLikeState = null;
                      _optimisticLikeCount = null;
                    });
                  }
                });
              }

              final hasLiked = _optimisticLikeState ?? streamLiked;
              final likedColor = widget.likedColor ?? Colors.redAccent;
              final unlikedColor = widget.unlikedColor ?? Colors.white70;

              return AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: hasLiked && _animationController.isAnimating 
                        ? _scaleAnimation.value 
                        : 1.0,
                    child: Icon(
                      hasLiked ? Icons.favorite : Icons.favorite_border,
                      size: widget.iconSize,
                      color: hasLiked ? likedColor : unlikedColor,
                    ),
                  );
                },
              );
            },
          ),
          if (widget.showCount) ...[
            const SizedBox(width: 6),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Posts')
                  .doc(widget.postId)
                  .snapshots(),
              builder: (context, postSnapshot) {
                int likesCount = widget.initialLikesCount;
                if (postSnapshot.hasData && postSnapshot.data != null) {
                  final data = postSnapshot.data!.data() as Map<String, dynamic>?;
                  if (data != null) {
                    likesCount = data['pos_likesCount'] as int? ?? widget.initialLikesCount;
                  }
                }

                // Limpiar estado optimista cuando el stream confirma el cambio
                if (postSnapshot.hasData && 
                    _optimisticLikeCount != null &&
                    _optimisticLikeCount == likesCount) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _optimisticLikeState = null;
                        _optimisticLikeCount = null;
                      });
                    }
                  });
                }

                final displayCount = _optimisticLikeCount ?? likesCount;

                return Text(
                  '$displayCount',
                  style: widget.countStyle ??
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                );
              },
            ),
          ],
          ],
        ),
      ),
    );
  }
}

