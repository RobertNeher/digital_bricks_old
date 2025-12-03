import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.info_outline,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              'Digital Bricks',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Version 1.0.0'),
            const SizedBox(height: 20),
            const Text('A digital logic simulator built with Flutter.'),
          ],
        ),
      ),
    );
  }
}
