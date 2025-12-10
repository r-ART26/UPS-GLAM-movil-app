import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// Bottom Navigation Bar institucional para UPStagram.
/// Íconos amarillos cuando están activos, íconos blancos cuando están inactivos.
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: AppColors.upsBlueDark,
      currentIndex: currentIndex,
      onTap: onTabSelected,

      selectedItemColor: AppColors.upsYellow,
      unselectedItemColor: Colors.white70,

      showSelectedLabels: true,
      showUnselectedLabels: true,

      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Buscar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_box_outlined),
          label: 'Nuevo',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Perfil',
        ),
      ],
    );
  }
}
