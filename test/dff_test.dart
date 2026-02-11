import 'package:flutter_test/flutter_test.dart';
import 'package:digital_bricks/models/memory.dart';
import 'dart:ui';

void main() {
  group('D-FlipFlop Logic Tests', () {
    late DFlipFlop dff;

    setUp(() {
      dff = DFlipFlop(id: 'dff1', position: const Offset(0, 0));
    });

    test('Initial State', () {
      expect(
        dff.inputs.length,
        4,
        reason: 'Should have 4 inputs (D, Clk, Pre, Clr)',
      );
      expect(dff.outputs[0].value, false, reason: 'Q should be initially Low');
      expect(
        dff.outputs[1].value,
        true,
        reason: 'Q_not should be initially High',
      );
    });

    test('Normal Clock Operation', () {
      // D=1, Clock rising edge
      dff.inputs[0].value = true; // D
      dff.inputs[1].value = true; // Clock
      dff.evaluate();

      expect(
        dff.outputs[0].value,
        true,
        reason: 'Q should capture D on rising edge',
      );
      expect(dff.outputs[1].value, false, reason: 'Q_not should be inverted');

      // Clock falling edge
      dff.inputs[1].value = false;
      dff.evaluate();
      expect(
        dff.outputs[0].value,
        true,
        reason: 'State should hold on falling edge',
      );
    });

    test('Preset Operation', () {
      // Ensure Q is 0 first
      dff.inputs[2].value = true; // Preset
      dff.evaluate();
      expect(dff.outputs[0].value, true, reason: 'Preset should set Q=1');

      // Check priority over D/Clock
      dff.inputs[0].value = false; // D=0
      dff.inputs[1].value = true; // Clock rising
      dff.evaluate();
      expect(
        dff.outputs[0].value,
        true,
        reason: 'Preset should override Clock',
      );

      // Release Preset
      dff.inputs[2].value = false;
      dff.evaluate();
      expect(
        dff.outputs[0].value,
        true,
        reason: 'State should hold after Preset release',
      );
    });

    test('Clear Operation', () {
      // Ensure Q is 1 first (via Preset)
      dff.inputs[2].value = true;
      dff.evaluate();
      dff.inputs[2].value = false;

      // Assert Q=1
      expect(dff.outputs[0].value, true);

      // Activate Clear
      dff.inputs[3].value = true; // Clear
      dff.evaluate();
      expect(dff.outputs[0].value, false, reason: 'Clear should set Q=0');

      // Release Clear
      dff.inputs[3].value = false;
      dff.evaluate();
      expect(
        dff.outputs[0].value,
        false,
        reason: 'State should hold after Clear release',
      );
    });

    test('Clear Priority over Preset', () {
      dff.inputs[2].value = true; // Preset
      dff.inputs[3].value = true; // Clear
      dff.evaluate();

      expect(
        dff.outputs[0].value,
        false,
        reason: 'Clear should override Preset',
      );
    });
  });
}
