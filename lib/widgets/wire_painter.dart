import 'package:flutter/material.dart';
import '../models/connection.dart';
import '../models/logic_component.dart';
// import '../models/gates.dart';
import '../models/io_devices.dart';
import '../models/integrated_circuit.dart';

class WirePainter extends CustomPainter {
  final List<Connection> connections;
  final List<LogicComponent> components;

  WirePainter({required this.connections, required this.components});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final activePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (var conn in connections) {
      Offset? p1 = _getPinPos(conn.sourcePinId);
      Offset? p2 = _getPinPos(conn.targetPinId);

      if (p1 != null && p2 != null) {
        // Find if source pin is active
        bool isActive = false;
        // Optimization: we could pass map, but list lookup is ok for small app
        for (var c in components) {
          for (var p in c.outputs) {
            if (p.id == conn.sourcePinId) {
              isActive = p.value;
              break;
            }
          }
        }

        Path path = Path();
        path.moveTo(p1.dx, p1.dy);

        // Bezier or Manhattan routing?
        // Simple cubic bezier looks nice for hanging wires
        double dist = (p2.dx - p1.dx).abs();
        path.cubicTo(
          p1.dx + dist / 2,
          p1.dy,
          p2.dx - dist / 2,
          p2.dy,
          p2.dx,
          p2.dy,
        );

        canvas.drawPath(path, isActive ? activePaint : paint);
      }
    }
  }

  Offset? _getPinPos(String pinId) {
    for (var c in components) {
      // Check Inputs
      for (int i = 0; i < c.inputs.length; i++) {
        if (c.inputs[i].id == pinId) {
          return _calculatePinOffset(c, i, true);
        }
      }
      // Check Outputs
      for (int i = 0; i < c.outputs.length; i++) {
        if (c.outputs[i].id == pinId) {
          return _calculatePinOffset(c, i, false);
        }
      }
    }
    return null;
  }

  Offset _calculatePinOffset(LogicComponent c, int index, bool isInput) {
    // Logic matching ComponentWidget layout
    // Row(Inputs, Body, Outputs)
    // Body width varies.
    // Inputs at local x ~ 6 (12/2).
    // Outputs at local x ~ width + 20 - 6.

    // Recalculate component dimensions used in widget
    double height = 60.0;
    if (c.inputs.length > 3) {
      height = c.inputs.length * 20.0;
    }
    double width = 60.0;
    if (c is SegmentDisplay) {
      // Logic matching ComponentWidget
      double fontH = c.fontSize;
      double pinH = c.inputs.length * 20.0;
      height = fontH > pinH ? fontH : pinH;
      width = fontH * 0.8;
    }

    if (c is IntegratedCircuit) {
      double maxInW = 0;
      double maxOutW = 0;
      const double charWidth = 8.0;

      for (var l in c.blueprint.inputLabels) {
        if (l.length * charWidth > maxInW) maxInW = l.length * charWidth;
      }
      for (var l in c.blueprint.outputLabels) {
        if (l.length * charWidth > maxOutW) maxOutW = l.length * charWidth;
      }
      width = 60.0 + maxInW + maxOutW;
    }

    double totalWidth = width + 20;

    // Vertical pos
    // MainAxisAlignment.spaceEvenly
    int count = isInput ? c.inputs.length : c.outputs.length;
    double step = height / (count + 1);
    double y = c.position.dy + step * (index + 1);

    double x = c.position.dx;
    if (isInput) {
      x += 6; // Center of 12px circle centered in 12px column? Center is 6.
    } else {
      x += totalWidth - 6;
    }

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant WirePainter oldDelegate) {
    // Ideally check if lists changed, but for animation we just repaint
    return true;
  }
}
