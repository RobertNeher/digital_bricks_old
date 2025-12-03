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
            Icon(
              Icons.info_outline,
              size: 64,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            Text(
              'Digital Bricks',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Version 1.0.0'),
            SizedBox(height: 20),
            Text(
              'Features',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('Pre-defined logic circuits: AND, OR, XOR, NAND, NOR, NXOR'),
            SizedBox(height: 10),
            Image.asset('images/20240722142346365.png', height: 150),
            SizedBox(height: 10),
            Image.asset('images/b994dc405860bca8b1bf8c848fe84cc9.jpg',
                height: 150),
            SizedBox(height: 10),
            Text('Oscillator with custom frequency'),
            Text('7 or 16 segment display'),
            Text('Keyboard entry (4, 7 or 8 bit)'),
            Text('D/A converter (4, or 8 bit)'),
            Text('Loud speaker'),
            Text('LED (1 to n with customizable color range(s)'),
            Text('Button (double or triple state)'),
            Text('Touch pad (mouse replacement) with 4, or 8 bit resolution'),
          ],
        ),
      ),
    );
  }
}
