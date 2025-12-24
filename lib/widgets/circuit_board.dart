import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../circuit_provider.dart';
import '../models/logic_component.dart'; // Needed for type
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
    );
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
