import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/navigation/bottom_nav_bar.dart';

/// Shell principal para la navegación interna.
/// Recibe el widget hijo del GoRouter y coloca el BottomNavBar.
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/home/feed')) return 0;
    if (location.startsWith('/home/search')) return 1;
    if (location.startsWith('/home/post/new')) return 2;
    if (location.startsWith('/home/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Si hay historial, hacer pop
          if (context.canPop()) {
            context.pop();
          } else {
            // Si no hay historial, ir al feed (pantalla principal)
            context.go('/home/feed');
          }
        }
      },
      child: Scaffold(
        body: child,

        bottomNavigationBar: BottomNavBar(
          currentIndex: currentIndex,
          onTabSelected: (index) {
            switch (index) {
              case 0:
                context.go('/home/feed');
                break;
              case 1:
                context.go('/home/search');
                break;
              case 2:
                context.go('/home/post/new');
                break;
              case 3:
                context.go('/home/profile');
                break;
            }
          },
        ),
      ),
    );
  }
}
