import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pin.dart';
import '../circuit_provider.dart';

class PinWidget extends StatelessWidget {
  final Pin pin;

  const PinWidget({super.key, required this.pin});

  @override
  Widget build(BuildContext context) {
    // Pin color based on value
    // We can assume red = true, gray/black = false
    Color color = pin.value ? Colors.red : Colors.grey;

    return DragTarget<String>(
      onWillAccept: (data) =>
          data != null && data != pin.id, // Can't connect to self
      onAccept: (sourcePinId) {
        Provider.of<CircuitProvider>(
          context,
          listen: false,
        ).addConnection(sourcePinId, pin.id);
      },
      builder: (context, candidateData, rejectedData) {
        return Draggable<String>(
          data: pin.id,
          feedback: Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: color.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
          ),
          child: Container(
            width: 12, // Hit box size
            height: 12,
            decoration: BoxDecoration(
              color: candidateData.isNotEmpty ? Colors.blue : color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1),
            ),
          ),
        );
      },
    );
  }
}
