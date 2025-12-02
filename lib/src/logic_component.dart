import 'package:digital_bricks/src/and_gate.dart';
import 'package:digital_bricks/src/logic_pin.dart';
import 'package:digital_bricks/src/or_gate.dart';
import 'package:digital_bricks/src/oscillator.dart';
import 'package:flutter/material.dart';

// Abstract base class for any component on the backplane
abstract class LogicComponent {
  final String id;
  Offset position;
  final List<LogicPin> inputs = [];
  final List<LogicPin> outputs = [];
  bool get hasOutput; // e.g., for Power/Ground
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
