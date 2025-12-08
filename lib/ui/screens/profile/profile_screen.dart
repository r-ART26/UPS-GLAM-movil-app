import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Text(
          'Perfil del Usuario',
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),
      ),
    );
  }
}
