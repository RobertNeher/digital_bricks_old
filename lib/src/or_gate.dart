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

  void updateInputCount(int count) {
    if (count < 2) count = 2; // Minimum 2 inputs for OR gate
    if (count == inputs.length) return;

    if (count > inputs.length) {
      // Add pins
      int toAdd = count - inputs.length;
      for (int i = 0; i < toAdd; i++) {
        inputs.add(LogicPin());
      }
    } else {
      // Remove pins (from the end)
      int toRemove = inputs.length - count;
      for (int i = 0; i < toRemove; i++) {
        inputs.removeLast();
      }
    }
  }
}
