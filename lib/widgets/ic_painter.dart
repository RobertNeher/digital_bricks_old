import 'package:flutter/material.dart';
import '../models/logic_component.dart';
import 'gate_painter.dart';

class ICPainter extends CustomPainter {
  final List<LogicComponent> components;

  ICPainter(this.components);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw surrounding box
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);

    if (components.isEmpty) return;

    // 1. Calculate Bounding Box of internals
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (var c in components) {
      if (c.position.dx < minX) minX = c.position.dx;
      if (c.position.dy < minY) minY = c.position.dy;
      // Assume approx size 50x50 for bounds calculation
      if (c.position.dx + 50 > maxX) maxX = c.position.dx + 50;
      if (c.position.dy + 50 > maxY) maxY = c.position.dy + 50;
    }

    double contentWidth = maxX - minX;
    double contentHeight = maxY - minY;

    // Avoid division by zero
    if (contentWidth <= 0) contentWidth = 1;
    if (contentHeight <= 0) contentHeight = 1;

    // 2. Calculate Scale
    // We want to fit content into 'size', with some padding
    double padding = 4.0;
    double availW = size.width - padding * 2;
    double availH = size.height - padding * 2;

    double scaleX = availW / contentWidth;
    double scaleY = availH / contentHeight;
    double scale = scaleX < scaleY ? scaleX : scaleY;

    // Center it
    double drawW = contentWidth * scale;
    double drawH = contentHeight * scale;
    double offsetX = (size.width - drawW) / 2;
    double offsetY = (size.height - drawH) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);
    canvas.translate(-minX, -minY); // Normalize to 0,0

    for (var c in components) {
      canvas.save();
      canvas.translate(c.position.dx, c.position.dy);

      // Draw component
      // We assume standard size for all components for now (e.g. 40x40 or 50x50)
      // GatePainter expects a specific size.
      // Logic from ComponentWidget: width 60, height 60 usually.
      // But segment display is dynamic.
      // Let's use a standard 40x40 for visualization to keep it simple.
      Size compSize = const Size(40, 40);

      // Use different color for visuals?
      GatePainter(type: c.type, color: Colors.black54).paint(canvas, compSize);

      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ICPainter oldDelegate) {
    return oldDelegate.components != components;
  }
}
