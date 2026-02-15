import 'package:flutter_test/flutter_test.dart';
import 'package:digital_bricks/circuit_provider.dart';
import 'package:digital_bricks/models/circuit_io.dart';
import 'package:digital_bricks/models/gates.dart';
import 'package:digital_bricks/models/integrated_circuit.dart';
import 'package:flutter/material.dart';

void main() {
  group('Repacking Logic Tests', () {
    late CircuitProvider provider;

    setUp(() {
      provider = CircuitProvider();
    });

    test('Repack with Explicit CircuitInput and CircuitOutput', () {
      // 1. Create components
      // Input A
      var inputA = CircuitInput(id: 'in-A', position: const Offset(0, 0));
      inputA.label = "A";

      // Gate
      var gate = AndGate(id: 'and-1', position: const Offset(100, 0));

      // Output Q
      var outputQ = CircuitOutput(id: 'out-Q', position: const Offset(200, 0));
      outputQ.label = "Q";

      // 2. Add to provider
      provider.addComponent(inputA);
      provider.addComponent(gate);
      provider.addComponent(outputQ);

      // 3. Connect them
      // inputA (output 0) -> gate (input 0)
      provider.addConnection(inputA.outputs[0].id, gate.inputs[0].id);
      // gate (output 0) -> outputQ (input 0)
      provider.addConnection(gate.outputs[0].id, outputQ.inputs[0].id);

      // 4. Assign to a Group (simulation of Unpacked state)
      String groupId = "group-1";
      inputA.icGroupId = groupId;
      gate.icGroupId = groupId;
      outputQ.icGroupId = groupId;

      // Also need to set icBlueprintName as per unpack logic
      // Use a DIFFERENT name to avoid "recursion" check if we repack into "TestBP"
      // or we can just say they came from "OriginalIC"
      inputA.icBlueprintName = "OriginalIC";
      gate.icBlueprintName = "OriginalIC";
      outputQ.icBlueprintName = "OriginalIC";

      // 5. Repack
      provider.repackIntegratedCircuit(groupId, "TestBP");

      // 6. Verify Result
      // One component should remain (the new IC)
      expect(
        provider.components.length,
        1,
        reason: "Components should be replaced by 1 IC",
      );
      expect(provider.components.first is IntegratedCircuit, true);

      IntegratedCircuit ic = provider.components.first as IntegratedCircuit;

      // Verify Ports in Blueprint
      expect(
        ic.blueprint.inputPorts.length,
        1,
        reason: "Should have 1 input port",
      );
      expect(
        ic.blueprint.outputPorts.length,
        1,
        reason: "Should have 1 output port",
      );
      expect(ic.blueprint.inputLabels, [
        "A",
      ], reason: "Input label should be A");
      expect(ic.blueprint.outputLabels, [
        "Q",
      ], reason: "Output label should be Q");

      // Verify Pins on IC instance
      expect(
        ic.inputs.length,
        1,
        reason: "IC Instance should have 1 input pin",
      );
      expect(
        ic.outputs.length,
        1,
        reason: "IC Instance should have 1 output pin",
      );
    });

    test('Repack with Implicit Ports (No CircuitIO)', () {
      // Gate 1
      var gate1 = AndGate(id: 'and-1', position: const Offset(0, 0));
      // Gate 2
      var gate2 = OrGate(id: 'or-1', position: const Offset(100, 0));

      provider.addComponent(gate1);
      provider.addComponent(gate2);

      // Connection: And -> Or
      provider.addConnection(gate1.outputs[0].id, gate2.inputs[0].id);

      // Group
      String groupId = "group-2";
      gate1.icGroupId = groupId;
      gate2.icGroupId = groupId;

      // Repack
      provider.repackIntegratedCircuit(groupId, "ImplicitBP");

      IntegratedCircuit ic = provider.components.first as IntegratedCircuit;

      // Expecting:
      // And inputs (2) are unconnected -> 2 input ports
      // Or output (1) is unconnected -> 1 output port
      expect(
        ic.blueprint.inputPorts.length,
        2 + 1,
      ); // Wait, OrGate has 2 inputs. 1 is connected.
      // AndGate has 2 inputs. Both unconnected.
      // OrGate has 2 inputs. One connected to AndGate. One unconnected.
      // Total inputs = 2 + 1 = 3.

      expect(ic.blueprint.outputPorts.length, 1);
    });
  });
}
