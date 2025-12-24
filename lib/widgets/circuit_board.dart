import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../circuit_provider.dart';
import '../models/logic_component.dart'; // Needed for type
import '../models/connection.dart';
import '../models/io_devices.dart'; // For SegmentDisplay check
import 'component_widget.dart';
import 'wire_painter.dart';

class CircuitBoard extends StatefulWidget {
  const CircuitBoard({super.key});

  @override
  State<CircuitBoard> createState() => _CircuitBoardState();
}

class _CircuitBoardState extends State<CircuitBoard> {
  final TransformationController _transformController =
      TransformationController();
  final GlobalKey _canvasKey = GlobalKey(); // Key for the internal Container

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CircuitProvider>(context);

    // Canvas size
    const double canvasWidth = 2000;
    const double canvasHeight = 2000;

    return ColoredBox(
      color: Colors.white,
      child: InteractiveViewer(
        transformationController: _transformController,
        boundaryMargin: const EdgeInsets.all(double.infinity),
        minScale: 0.1,
        maxScale: 4.0,
        constrained: false,
        child: GestureDetector(
          onSecondaryTapUp: (details) {
            _handleSecondaryTap(context, details.localPosition, provider);
          },
          child: DragTarget<ComponentType>(
            onAcceptWithDetails: (details) {
              _handleDrop(context, details.data, details.offset);
            },
            builder: (context, candidateData, rejectedData) {
              return Container(
                key: _canvasKey,
                width: canvasWidth,
                height: canvasHeight,
                color: Colors.grey[200], // Fixed color
                child: Stack(
                  children: [
                    // Wires (Bottom layer)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: WirePainter(
                          connections: provider.connections,
                          components: provider.components,
                        ),
                      ),
                    ),

                    // Components
                    ...provider.components.map((comp) {
                      return Positioned(
                        left: comp.position.dx,
                        top: comp.position.dy,
                        child: ComponentWidget(component: comp),
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleSecondaryTap(
    BuildContext context,
    Offset localPos,
    CircuitProvider provider,
  ) {
    // Check for wire hit
    for (var conn in provider.connections) {
      if (_isWireHit(conn, localPos, provider.components)) {
        _showWireContextMenu(context, conn.id);
        return;
      }
    }
  }

  bool _isWireHit(
    Connection conn,
    Offset tapPos,
    List<LogicComponent> components,
  ) {
    Offset? p1 = _getPinPos(conn.sourcePinId, components);
    Offset? p2 = _getPinPos(conn.targetPinId, components);

    if (p1 == null || p2 == null) return false;

    // Wire uses cubicTo. Checking hit on bezier is expensive.
    // Simplify: check distance to bounds or sample points?
    // Or check distance to the straight line? (Wont match curved wire well).
    // Or checking distance to the Bezier curve iteratively.

    // Let's use a simplified check: check points along the bezier curve
    // Bezier P0=p1, P1=(p1.x+d/2, p1.y), P2=(p2.x-d/2, p2.y), P3=p2
    double distX = (p2.dx - p1.dx).abs();
    Offset c1 = Offset(p1.dx + distX / 2, p1.dy);
    Offset c2 = Offset(p2.dx - distX / 2, p2.dy);

    // Check 20 steps
    for (double t = 0; t <= 1.0; t += 0.05) {
      Offset p = _evalCubicBezier(p1, c1, c2, p2, t);
      if ((p - tapPos).distance < 10.0) return true; // 10px tolerance
    }
    return false;
  }

  Offset _evalCubicBezier(
    Offset p0,
    Offset p1,
    Offset p2,
    Offset p3,
    double t,
  ) {
    double u = 1 - t;
    double tt = t * t;
    double uu = u * u;
    double uuu = uu * u;
    double ttt = tt * t;

    return p0 * uuu + p1 * (3 * uu * t) + p2 * (3 * u * tt) + p3 * ttt;
  }

  void _showWireContextMenu(BuildContext context, String connectionId) {
    // Get position for menu? showModalBottomSheet is easier
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text("Delete Connection"),
              onTap: () {
                Provider.of<CircuitProvider>(
                  context,
                  listen: false,
                ).removeConnection(connectionId);
                Navigator.pop(ctx);
              },
            ),
          ],
        );
      },
    );
  }

  // Reusing logic from WirePainter (should refactor later)
  Offset? _getPinPos(String pinId, List<LogicComponent> components) {
    for (var c in components) {
      for (int i = 0; i < c.inputs.length; i++) {
        if (c.inputs[i].id == pinId) return _calculatePinOffset(c, i, true);
      }
      for (int i = 0; i < c.outputs.length; i++) {
        if (c.outputs[i].id == pinId) return _calculatePinOffset(c, i, false);
      }
    }
    return null;
  }

  Offset _calculatePinOffset(LogicComponent c, int index, bool isInput) {
    double height = 60.0;
    if (c.inputs.length > 3) {
      height = c.inputs.length * 20.0;
    }
    double width = 60.0;
    if (c is SegmentDisplay) {
      width = 80.0;
      height = 100.0;
    }
    double totalWidth = width + 20;

    int count = isInput ? c.inputs.length : c.outputs.length;
    double step = height / (count + 1);
    double y = c.position.dy + step * (index + 1);

    double x = c.position.dx;
    if (isInput) {
      x += 6;
    } else {
      x += totalWidth - 6;
    }

    return Offset(x, y);
  }

  void _handleDrop(BuildContext context, ComponentType type, Offset dropPos) {
    // dropPos is in global screen coordinates.
    // We need to convert it to the local coordinate system of the Container (Canvas).

    final RenderBox? renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final Offset localPos = renderBox.globalToLocal(dropPos);
      // localPos is now relative to the Container's 0,0 (Top Left of 2000x2000 canvas).
      // This includes the InteractiveViewer's transform automatically?
      // Yes, globalToLocal traverses up the tree and applies inverses.

      Provider.of<CircuitProvider>(
        context,
        listen: false,
      ).addComponentByType(type, localPos);
    }
  }
}
