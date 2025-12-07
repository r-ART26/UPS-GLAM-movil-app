import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usamos un Container a pantalla completa con degradado de fondo
      body: Container(
        width: double.infinity,
        height: double.infinity,

        // 🎨 Fondo con degradado azul UPS
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF003A75), // azul más claro
              Color(0xFF002B5C), // azul más oscuro
            ],
          ),
        ),

        // 📐 Contenido interno
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Título principal: "Matrículas"
                const Text(
                  'Matrículas',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),

                // Título secundario: "Abiertas" en amarillo
                const Text(
                  'Abiertas',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFC400), // amarillo UPS
                    height: 1.0,
                  ),
                ),

                const SizedBox(height: 24),

                // Subtítulo opcional
                const Text(
                  'Explora, publica y comparte contenido visual\ncon la comunidad UPS.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFE0E0E0),
                  ),
                ),

                const SizedBox(height: 40),

                // 🔘 Botón principal "Ingresar"
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Aquí más adelante navegaremos al login
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC400),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Ingresar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Texto secundario tipo "CTA" suave
                const Text(
                  'Desliza hacia arriba o toca continuar\npara iniciar sesión o registrarte.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFB0BEC5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
