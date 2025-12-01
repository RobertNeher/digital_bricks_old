import 'package:digital_bricks/src/oscillator.dart';
import 'package:flutter/material.dart';

class OscillatorWidget extends StatelessWidget {
  final Oscillator oscillator;

  const OscillatorWidget({super.key, required this.oscillator});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100 +
          (oscillator.outputs.length * 20.0), // Adjust height based on inputs
      decoration: BoxDecoration(
        color: Colors.blue[100],
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Oscillator Symbol
          Positioned(
            left: 25,
            top: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomPaint(
                  painter: SquarePulsePainter(),
                  child: Container(
                    width: 40,
                    height: 30,
                  ),
                ),
                Text("${oscillator.frequency.round()} Hz",
                    style: const TextStyle(fontSize: 18)),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Out", style: TextStyle(fontSize: 10)),
                  const SizedBox(width: 4),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: oscillator.outputs.first.value
                          ? Colors.green
                          : Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SquarePulsePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(
        Offset(0, size.height), Offset(size.width / 4, size.height), paint);
    canvas.drawLine(Offset(size.width / 4, size.height),
        Offset(size.width / 4, size.height / 2), paint);
    canvas.drawLine(Offset(size.width / 4, size.height / 2),
        Offset(size.width * 0.75, size.height / 2), paint);
    canvas.drawLine(Offset(size.width * 0.75, size.height / 2),
        Offset(size.width * 0.75, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.75, size.height),
        Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
