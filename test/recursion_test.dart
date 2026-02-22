import 'package:flutter_test/flutter_test.dart';
import 'package:digital_bricks/models/integrated_circuit.dart';
import 'package:digital_bricks/models/saved_circuit.dart';

void main() {
  test('IntegratedCircuit detects infinite recursion', () {
    // 1. Create a self-referential blueprint
    // We can't easily make a circular JSON/Map structure for the `components` list
    // because SavedCircuit.fromJson expects a Map.
    // However, we can construct the SavedCircuit manually and pass it to the component logic.

    // We need a blueprint that contains... itself?
    // But SavedCircuit is immutable-ish.
    // Let's create a blueprint 'A'.

    // Trick: In the real app, the recursion comes from `customCircuits` containing blueprints that refer to others.
    // When `IntegratedCircuit` deserializes, it reads the blueprint from the JSON.
    // The JSON contains the FULL blueprint data for the child.

    // So to simulate infinite recursion for the test without the full Provider infrastructure:
    // We can create a SavedCircuit 'recurse'.
    // Inside it, we have a component of type Custom.
    // We need to set the 'blueprint' of that component to 'recurse' itself.

    final Map<String, dynamic> recursiveComponentJson = {
      'id': 'comp1',
      'type': 16, // ComponentType.custom.index (assuming 16)
      'position_dx': 0.0,
      'position_dy': 0.0,
      // 'blueprint': ... // We will fill this in
    };

    // ignore: unused_local_variable
    final savedCircuit = SavedCircuit(
      name: 'RecursiveBP',
      components: [
        recursiveComponentJson,
      ], // This list will contain the component
      connections: [],
      inputPorts: [],
      outputPorts: [],
    );

    // Now close the loop manually by injecting the blueprint object into the JSON map
    // Note: This relies on the fact that IntegratedCircuit uses the map directly.
    // But wait, SavedCircuit.fromJson expects Maps, not objects.
    // And IntegratedCircuit._deserializeInternal(json) reads `json['blueprint']` and calls `SavedCircuit.fromJson`.

    // So we need:
    // blueprint.components[0]['blueprint'] = blueprint.toJson()

    // Let's try to construct a depth-limited chain first to verify the depth counter works.
    // It's harder to construct an *infinite* structure in setup without a loop.

    // Let's just create a chain of 25 nested blueprints manually.
    SavedCircuit? inner = SavedCircuit(
      name: 'Leaf',
      components: [],
      connections: [],
      inputPorts: [],
      outputPorts: [],
    );

    for (int i = 0; i < 25; i++) {
      // Wrap 'inner' in a new wrapper
      final wrapperComp = {
        'id': 'wrapper_$i',
        'type': 16, // custom
        'position_dx': 0.0,
        'position_dy': 0.0,
        'blueprint': inner!.toJson(),
      };

      inner = SavedCircuit(
        name: 'Wrapper_$i',
        components: [wrapperComp],
        connections: [],
        inputPorts: [],
        outputPorts: [],
      );
    }

    // Now 'inner' is a chain of depth ~25.
    // Instantiating it should throw.

    try {
      IntegratedCircuit(
        id: 'test_root',
        position: Offset.zero,
        blueprint: inner!,
      );
      fail("Should have thrown an exception due to depth limit");
    } catch (e) {
      expect(e.toString(), contains("Maximum recursion depth"));
    }
  });
}
