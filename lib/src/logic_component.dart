import 'package:digital_bricks/src/components/and_gate.dart';
import 'package:digital_bricks/src/logic_pin.dart';
import 'package:digital_bricks/src/components/or_gate.dart';
import 'package:digital_bricks/src/components/oscillator.dart';
import 'package:flutter/material.dart';

// Abstract base class for any component on the backplane
abstract class LogicComponent {
  final String id;
  Offset position;
  final List<LogicPin> inputs = [];
  final List<LogicPin> outputs = [];
  bool get hasOutput; // e.g., for Power/Ground

  Offset getInputPosition(int index) {
    // Default implementation, override in subclasses if needed
    // Assuming inputs are on the left side
    // Height calculation matches the widget implementation: 100 + (inputs.length * 20.0)
    // We need to match the widget's layout logic exactly.
    // In AndWidget: Column mainAxisAlignment: MainAxisAlignment.spaceEvenly
    // Height: 100 + (inputs.length * 20.0)
    // This is tricky without access to the actual RenderBox.
    // For now, let's approximate based on the known widget structure.

    final height = 100.0 + (inputs.length * 20.0);
    final spacePerItem = height / (inputs.length + 1);
    final yOffset = spacePerItem * (index + 1);

    return position + Offset(0, yOffset);
  }

  Offset getOutputPosition(int index) {
    // Default implementation, override in subclasses if needed
    // Assuming output is on the right side, centered vertically
    final height = 100.0 + (inputs.length * 20.0);
    return position + Offset(100, height / 2);
  }

  // The core simulation method
  void calculateOutput(Map<String, LogicComponent> components);
  // Constructor, serialization methods, etc.
  LogicComponent(this.id, this.position);

  Map<String, dynamic> toJson();

  static LogicComponent fromJson(Map<String, dynamic> json,
      {Function? setState}) {
    final type = json['type'];
    final id = json['id'];
    final position = Offset(json['dx'], json['dy']);

    switch (type) {
      case 'AND':
        return AndGate(
            id: id, position: position, inputCount: json['inputCount'] ?? 2);
      case 'OR':
        return OrGate(
            id: id, position: position, inputCount: json['inputCount'] ?? 2);
      case 'OSC':
        return Oscillator(
            id: id,
            position: position,
            frequency: json['frequency'] ?? 1.0,
            setState: setState as void Function());
      default:
        throw Exception('Unknown component type: $type');
    }
  }
}
