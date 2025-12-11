import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/subscriptions/subscription_service.dart';
import '../../services/auth/auth_service.dart';
import '../theme/colors.dart';

/// Widget de botón para seguir/dejar de seguir con actualización optimista.
class FollowButton extends StatefulWidget {
  final String targetUserId;
  final double? width;
  final double? height;
  final double? fontSize;

  const FollowButton({
    super.key,
    required this.targetUserId,
    this.width,
    this.height,
    this.fontSize,
  });

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  String? _currentUserId;
  bool? _optimisticState;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final userId = await AuthService.getUserId();
    if (mounted) {
      setState(() {
        _currentUserId = userId;
      });
    }
  }

  Future<void> _handleToggle() async {
    if (_isToggling || _currentUserId == null || _currentUserId == widget.targetUserId) {
      return;
    }

    setState(() {
      _isToggling = true;
    });

    // Obtener estado actual
    final currentDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(_currentUserId!)
        .collection('Following')
        .doc(widget.targetUserId)
        .get();

    final currentlyFollowing = currentDoc.exists;

    // Actualización optimista
    setState(() {
      _optimisticState = !currentlyFollowing;
    });

    // Hacer la petición al servidor
    final success = currentlyFollowing
        ? await SubscriptionService.unsubscribe(widget.targetUserId, context)
        : await SubscriptionService.subscribe(widget.targetUserId, context);

    if (mounted) {
      if (!success) {
        // Revertir si falló
        setState(() {
          _optimisticState = null;
        });
      }

      setState(() {
        _isToggling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null || _currentUserId == widget.targetUserId) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<bool>(
      stream: SubscriptionService.isSubscribedStream(_currentUserId!, widget.targetUserId),
      builder: (context, snapshot) {
        final streamFollowing = snapshot.data ?? false;
        
        // Limpiar estado optimista cuando el stream confirma el cambio
        if (snapshot.hasData && 
            _optimisticState != null &&
            _optimisticState == streamFollowing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _optimisticState = null;
              });
            }
          });
        }

        final isFollowing = _optimisticState ?? streamFollowing;

        return SizedBox(
          width: widget.width,
          height: widget.height ?? 32,
          child: OutlinedButton(
            onPressed: _isToggling ? null : _handleToggle,
            style: OutlinedButton.styleFrom(
              foregroundColor: isFollowing ? AppColors.upsBlue : AppColors.upsYellow,
              backgroundColor: isFollowing ? AppColors.upsYellow : Colors.transparent,
              side: BorderSide(
                color: isFollowing ? AppColors.upsYellow : AppColors.upsYellow,
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isToggling
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isFollowing ? AppColors.upsBlue : AppColors.upsYellow,
                      ),
                    ),
                  )
                : Text(
                    isFollowing ? 'Siguiendo' : 'Seguir',
                    style: TextStyle(
                      fontSize: widget.fontSize ?? 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );
      },
    );
  }
}

