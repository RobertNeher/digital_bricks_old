import 'package:digital_bricks/src/components/logic_component.dart';
import 'package:digital_bricks/src/components/logic_pin.dart';
import 'package:flutter/material.dart';

class Inverter extends LogicComponent {
  Inverter({required String id, required Offset position})
      : super(id, position) {
    inputs.add(LogicPin());
    outputs.add(LogicPin());
  }

  @override
  bool get hasOutput => true;

  @override
  void calculateOutput(Map<String, LogicComponent> components) {
    outputs.first.value = !inputs.first.value;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'Inverter',
      'id': id,
      'dx': position.dx,
      'dy': position.dy,
    };
  }
}
