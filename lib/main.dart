import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Pantalla inicial
import 'ui/screens/welcome/welcome_screen.dart';

// Tema global UPSGlam
import 'ui/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

/// Aplicación principal de UPSGlam 2.0
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UPSGlam 2.0',
      debugShowCheckedModeBanner: false,

      // Ahora sí usamos el ThemeData global que creamos en Fase 1.3
      theme: AppTheme.light,

      home: const WelcomeScreen(),
    );
  }
}
