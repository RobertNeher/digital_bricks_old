import 'package:digital_bricks/src/logic_component.dart';
import 'package:digital_bricks/src/logic_pin.dart';
import 'package:flutter/material.dart';

class AndGate extends LogicComponent {
  AndGate({required String id, required Offset position, int inputCount = 2})
      : super(id, position) {
    for (int i = 0; i < inputCount; i++) {
      inputs.add(LogicPin());
    }
    outputs.add(LogicPin());
  }

  @override
  bool get hasOutput => true;

  @override
  void calculateOutput(Map<String, LogicComponent> components) {
    bool result = true;
    for (LogicPin pin in inputs) {
      if (!pin.value) {
        result = false;
        break;
      }
    }
    outputs.first.value = result;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'AND',
      'id': id,
      'dx': position.dx,
      'dy': position.dy,
      'inputCount': inputs.length,
    };
  }
}
