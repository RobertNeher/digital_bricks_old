import 'package:digital_bricks/src/components/logic_component.dart';
import 'package:flutter/material.dart';

class DraggableWidget extends StatelessWidget {
  final LogicComponent component;
  final Widget child;
  final VoidCallback onDrag;

  const DraggableWidget({
    super.key,
    required this.component,
    required this.child,
    required this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: component.position.dy,
      left: component.position.dx,
      child: GestureDetector(
        onPanUpdate: (details) {
          component.position += details.delta;
          onDrag();
        },
        child: child,
      ),
    );
  }
}
