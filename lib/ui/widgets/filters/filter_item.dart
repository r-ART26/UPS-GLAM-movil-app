import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// Widget para mostrar un filtro en la lista horizontal.
class FilterItem extends StatelessWidget {
  final String name;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const FilterItem({
    super.key,
    required this.name,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.upsYellow
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppColors.upsYellow
                : Colors.white.withOpacity(0.3),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.black87 : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                color: isActive ? Colors.black87 : Colors.white,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

