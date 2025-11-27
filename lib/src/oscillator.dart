import 'dart:async';

import 'package:digital_bricks/src/logic_component.dart';
import 'package:digital_bricks/src/logic_pin.dart';
import 'package:flutter/material.dart';

class Oscillator extends LogicComponent {
  late Timer timer;
  double frequency = 1;
  Oscillator({required String id, required Offset position, this.frequency = 1})
      : super(id, position) {
    outputs.add(LogicPin());
    timer = Timer.periodic(
        Duration(milliseconds: (1 / frequency * 1000).round()), (timer) {
      outputs.first.value = !outputs.first.value;
    });
  }

  @override
  void calculateOutput(Map<String, LogicComponent> components) {
    timer.cancel();
    timer = Timer.periodic(
        Duration(milliseconds: (1 / frequency * 1000).round()), (timer) {
      outputs.first.value = !outputs.first.value;
    });
  }

  @override
  bool get hasOutput => true;
}
