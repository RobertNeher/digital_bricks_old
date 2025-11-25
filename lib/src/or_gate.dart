import 'package:digital_bricks/src/logic_component.dart';
import 'package:digital_bricks/src/logic_pin.dart';
import 'package:flutter/material.dart';

class OrGate extends LogicComponent {
  OrGate(String id, Offset position, int inputCount) : super(id, position) {
    for (int i = 0; i < inputCount; i++) {
      inputs.add(LogicPin());
    }
    outputs.add(LogicPin());
  }

  @override
  bool get hasOutput => true;

  @override
  void calculateOutput(Map<String, LogicComponent> components) {
    bool result = false;
    for (LogicPin pin in inputs) {
      if (pin.value) {
        result = true;
        break;
      }
    }
    outputs.first.value = result;
  }
}
