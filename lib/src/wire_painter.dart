import 'package:digital_bricks/src/wire.dart';
import 'package:digital_bricks/src/components/logic_component.dart';
import 'package:flutter/material.dart';

class WirePainter extends CustomPainter {
  final List<Wire> wires;
  final List<LogicComponent> components;
  final Offset? dragStartPos;
  final Offset? dragEndPos;

  WirePainter({
    required this.wires,
    required this.components,
    this.dragStartPos,
    this.dragEndPos,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (var wire in wires) {
      final startComp = components.firstWhere(
          (c) => c.id == wire.startComponentId,
          orElse: () => throw Exception("Component not found"));
      final endComp = components.firstWhere((c) => c.id == wire.endComponentId,
          orElse: () => throw Exception("Component not found"));

      final startPos = startComp.getOutputPosition(wire.startPinIndex);
      final endPos = endComp.getInputPosition(wire.endPinIndex);

      paint.color = wire.value ? Colors.blue : Colors.black;

      _drawWire(canvas, startPos, endPos, paint);
    }

    if (dragStartPos != null && dragEndPos != null) {
      paint.color = Colors.grey;
      _drawWire(canvas, dragStartPos!, dragEndPos!, paint);
    }
  }

  void _drawWire(Canvas canvas, Offset start, Offset end, Paint paint) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    // Simple cubic bezier for smooth wire
    final controlPoint1 = Offset(start.dx + 50, start.dy);
    final controlPoint2 = Offset(end.dx - 50, end.dy);

    path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx,
        controlPoint2.dy, end.dx, end.dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WirePainter oldDelegate) {
    return true; // Repaint often for dragging
  }
}
