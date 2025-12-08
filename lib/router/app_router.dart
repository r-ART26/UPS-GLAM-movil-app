import 'package:go_router/go_router.dart';

// Pantallas
import '../ui/screens/welcome/welcome_screen.dart';
import '../ui/screens/auth/login_screen.dart';
import '../ui/screens/auth/register_screen.dart';

/// Router central de la aplicación.
/// En Fase 3 agregaremos protección de rutas y redirecciones de auth.
final GoRouter appRouter = GoRouter(
  initialLocation: '/welcome',

  routes: [
    GoRoute(
      path: '/welcome',
      name: 'welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),

    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),

    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
  ],
);
