import 'package:flutter/material.dart';
import '../models/logic_component.dart';

class GatePainter extends CustomPainter {
  final ComponentType type;
  final Color color;

  GatePainter({required this.type, this.color = Colors.black});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    Path path = Path();

    // Standard size assumed ~ width: , height:
    // Drawing logic normalized to size

    switch (type) {
      case ComponentType.and:
      case ComponentType.nand:
        _drawAnd(path, size);
        if (type == ComponentType.nand) _drawBubble(path, size);
        break;
      case ComponentType.or:
      case ComponentType.nor:
        _drawOr(path, size);
        if (type == ComponentType.nor) _drawBubble(path, size);
        break;
      case ComponentType.xor:
      case ComponentType.nxor:
        _drawXor(path, size);
        if (type == ComponentType.nxor) _drawBubble(path, size);
        break;
      case ComponentType.inverter:
        _drawInverter(path, size);
        _drawBubble(path, size);
        break;
      case ComponentType.oscillator:
        _drawBox(path, size);
        _drawOscSymbol(canvas, size, paint); // Special case
        break;
      case ComponentType.led:
        // LED is usually drawn as filled circle in the widget, but we can outline here
        _drawCircle(path, size);
        break;
      case ComponentType.segment7:
      case ComponentType.segment16:
        _drawBox(path, size);
        break;
      case ComponentType.constantSource:
        _drawBox(path, size);
        // Draw V or G symbol or just text?
        // Text is hard in CustomPainter without TextPainter.
        // Let's draw a small '1' or '0' shape or just a circle.
        // Actually, ComponentWidget can render the text state.
        break;
    }

    canvas.drawPath(path, paint);
  }

  void _drawAnd(Path path, Size size) {
    // D shape
    path.moveTo(0, 0);
    path.lineTo(size.width * 0.5, 0);

    // Draw elliptical arc
    // Rect defines the full ellipse. We use the right half.
    path.arcTo(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -1.5708, // -PI/2 (Top)
      3.14159, // PI (Sweep to Bottom)
      false, // forceMoveTo: false (connects line)
    );

    path.lineTo(0, size.height);
    path.close();
  }

  void _drawOr(Path path, Size size) {
    // Shield shape
    path.moveTo(0, 0);
    path.quadraticBezierTo(size.width * 0.25, size.height / 2, 0, size.height);
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height,
      size.width,
      size.height / 2,
    );
    path.quadraticBezierTo(size.width * 0.75, 0, 0, 0);
    path.close();
  }

  void _drawXor(Path path, Size size) {
    // Double curved back OR
    // First curve (back input guard)
    path.moveTo(-5, 0);
    path.quadraticBezierTo(
      size.width * 0.25 - 5,
      size.height / 2,
      -5,
      size.height,
    );

    // Main body
    path.moveTo(5, 0);
    path.quadraticBezierTo(
      size.width * 0.25 + 5,
      size.height / 2,
      5,
      size.height,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height,
      size.width,
      size.height / 2,
    );
    path.quadraticBezierTo(size.width * 0.75, 0, 5, 0);
  }

  void _drawInverter(Path path, Size size) {
    // Triangle
    path.moveTo(0, 0);
    path.lineTo(size.width - 10, size.height / 2);
    path.lineTo(0, size.height);
    path.close();
  }

  void _drawBubble(Path path, Size size) {
    // Small circle at tip
    // Need to find tip. For standard gates, tip is at (width, height/2) roughly
    // Adjusted by bubble size
    path.addOval(
      Rect.fromCircle(center: Offset(size.width, size.height / 2), radius: 5),
    );
  }

  void _drawBox(Path path, Size size) {
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  void _drawCircle(Path path, Size size) {
    path.addOval(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  void _drawOscSymbol(Canvas canvas, Size size, Paint paint) {
    // Draw square wave inside
    Path p = Path();
    double h = size.height;
    double w = size.width;
    p.moveTo(w * 0.2, h * 0.7);
    p.lineTo(w * 0.2, h * 0.3);
    p.lineTo(w * 0.5, h * 0.3);
    p.lineTo(w * 0.5, h * 0.7);
    p.lineTo(w * 0.8, h * 0.7);
    p.lineTo(w * 0.8, h * 0.3);
    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
