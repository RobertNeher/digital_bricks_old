import 'package:digital_bricks/src/logic_pin.dart';
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
}
