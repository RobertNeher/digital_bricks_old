import 'package:flutter_test/flutter_test.dart';
import 'package:digital_bricks/src/components/and_gate.dart';
import 'package:flutter/material.dart';

void main() {
  test('AndGate initializes with correct inputs', () {
    final gate = AndGate("gate1", Offset.zero, inputCount: 3);
    expect(gate.inputs.length, 3);
    expect(gate.outputs.length, 1);
  });

  test('AndGate updates input count correctly', () {
    final gate = AndGate("gate1", Offset.zero, inputCount: 2);
    expect(gate.inputs.length, 2);

    gate.updateInputCount(4);
    expect(gate.inputs.length, 4);

    gate.updateInputCount(2);
    expect(gate.inputs.length, 2);
  });

  test('AndGate logic works correctly', () {
    final gate = AndGate("gate1", Offset.zero, inputCount: 2);
    
    // Default false
    gate.calculateOutput({});
    expect(gate.outputs.first.value, false);

    // One true
    gate.inputs[0].value = true;
    gate.calculateOutput({});
    expect(gate.outputs.first.value, false);

    // All true
    gate.inputs[1].value = true;
    gate.calculateOutput({});
    expect(gate.outputs.first.value, true);
  });

  test('AndGate logic works with 3 inputs', () {
    final gate = AndGate("gate1", Offset.zero, inputCount: 3);
    
    gate.inputs[0].value = true;
    gate.inputs[1].value = true;
    gate.calculateOutput({});
    expect(gate.outputs.first.value, false); // 3rd is false

    gate.inputs[2].value = true;
    gate.calculateOutput({});
    expect(gate.outputs.first.value, true);
  });
}
