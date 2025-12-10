import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_model.dart';
import '../theme/colors.dart';
import 'follow_button.dart';

/// Widget para mostrar un usuario en una lista.
class UserListItem extends StatelessWidget {
  final UserModel user;
  final bool showFollowButton;

  const UserListItem({
    super.key,
    required this.user,
    this.showFollowButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.push('/profile/${user.uid}');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.upsBlue,
              backgroundImage: NetworkImage(user.getAvatarUrl()),
            ),
            const SizedBox(width: 12),
            // Información del usuario
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Botón de seguir (si está habilitado)
            if (showFollowButton)
              FollowButton(
                targetUserId: user.uid,
                width: 100,
                height: 32,
                fontSize: 13,
              ),
          ],
        ),
      ),
    );
  }
}

