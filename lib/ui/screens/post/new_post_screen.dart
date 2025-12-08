import 'package:flutter/material.dart';

class NewPostScreen extends StatelessWidget {
  const NewPostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Text(
          'Crear Nuevo Post',
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),
      ),
    );
  }
}
