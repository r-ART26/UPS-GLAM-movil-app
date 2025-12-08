import 'package:flutter/material.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Text(
          'Feed Screen',
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),
      ),
    );
  }
}
