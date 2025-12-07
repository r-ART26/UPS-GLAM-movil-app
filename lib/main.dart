import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Importación de la pantalla inicial de la aplicación.
// Se asume que existe en: lib/ui/screens/welcome/welcome_screen.dart
import 'ui/screens/welcome/welcome_screen.dart';

Future<void> main() async {
  // Necesario para inicializar plugins antes de ejecutar runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de Firebase utilizando las opciones generadas automáticamente.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

/// Widget raíz de la aplicación.
/// Define el tema global y la pantalla inicial.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // Título general de la aplicación.
      title: 'UPSGlam 2.0',

      // Tema base de la aplicación. Será reemplazado más adelante
      // por un tema centralizado en ui/theme/app_theme.dart.
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF003A75), // Azul institucional UPS.
        ),
        scaffoldBackgroundColor: Colors.white,
      ),

      // Pantalla de inicio. Actualmente se muestra la pantalla de bienvenida.
      home: const WelcomeScreen(),
    );
  }
}
