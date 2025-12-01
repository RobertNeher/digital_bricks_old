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
      this.frequency = 1,
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
    timer.cancel();
    timer = Timer.periodic(
        Duration(milliseconds: (1 / frequency * 1000).round()), (timer) {
      outputs.first.value = !outputs.first.value;
      print("$frequency ${outputs.first.value}");
    });
  }

  @override
  bool get hasOutput => true;
}
