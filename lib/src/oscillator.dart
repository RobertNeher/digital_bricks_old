import 'dart:async';

import 'package:digital_bricks/src/logic_component.dart';
import 'package:digital_bricks/src/logic_pin.dart';
import 'package:flutter/material.dart';

typedef SetState = void Function();

class Oscillator extends LogicComponent {
  SetState setState;
  late Timer timer;
  double frequency = 10;
  Oscillator(
      {required String id,
      required Offset position,
      this.frequency = 10,
      required this.setState})
      : super(id, position) {
    outputs.add(LogicPin());
    timer = Timer.periodic(
        Duration(milliseconds: (1 / frequency * 1000).round()), (timer) {
      outputs.first.value = !outputs.first.value;
      setState();
    });
  }

  @override
  void calculateOutput(Map<String, LogicComponent> components) {
    // Oscillator is self-driven by Timer, no input dependency to calculate
  }

  @override
  bool get hasOutput => true;

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'OSC',
      'id': id,
      'dx': position.dx,
      'dy': position.dy,
      'frequency': frequency,
    };
  }
}
