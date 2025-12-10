import 'package:go_router/go_router.dart';

// Layout
import '../ui/layout/app_shell.dart';

// Pantallas públicas
import '../ui/screens/welcome/welcome_screen.dart';
import '../ui/screens/auth/login_screen.dart';
import '../ui/screens/auth/register_screen.dart';

// Pantallas internas
import '../ui/screens/feed/feed_screen.dart';
import '../ui/screens/post/new_post_screen.dart';
import '../ui/screens/profile/profile_screen.dart';

// Middleware
import '../services/auth/auth_middleware.dart';

/// Router central de la aplicación.
final GoRouter appRouter = GoRouter(
  initialLocation: '/welcome',

  // Redirección basada en autenticación
  redirect: (context, state) async {
    return await AuthMiddleware.redirect(state.uri.path);
  },

  routes: [
    // ========================
    // RUTAS PÚBLICAS
    // ========================
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

    // ========================
    // ÁREA INTERNA (ShellRoute)
    // ========================
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/home/feed',
          builder: (context, state) => const FeedScreen(),
        ),
        GoRoute(
          path: '/home/post/new',
          builder: (context, state) => const NewPostScreen(),
        ),
        GoRoute(
          path: '/home/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/profile/:uid',
          builder: (context, state) {
            final uid = state.pathParameters['uid'];
            return ProfileScreen(userId: uid);
          },
        ),
      ],
    ),
  ],
);
