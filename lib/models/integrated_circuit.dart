import 'package:flutter/material.dart';
import 'logic_component.dart';
import 'markdown_component.dart';
import 'saved_circuit.dart';
import 'connection.dart';
import 'pin.dart';
import 'gates.dart';
import 'io_devices.dart';
import 'memory.dart';
import 'circuit_io.dart';

class IntegratedCircuit extends LogicComponent {
  final SavedCircuit blueprint;
  final List<LogicComponent> internalComponents = [];
  final List<Connection> internalConnections = [];

  // Mapping from External Pin ID -> Internal Pin ID
  final Map<String, String> inputMap = {};
  final Map<String, String> outputMap = {};

  // Cache for fast lookups
  final Map<String, Pin> _pinMap = {};

  final int depth;
  static const int maxDepth = 20;

  IntegratedCircuit({
    required String super.id,
    required super.position,
    required this.blueprint,
    this.depth = 0,
  }) : super(name: blueprint.name, type: ComponentType.custom) {
    _initialize();
  }

  void _initialize() {
    if (depth > maxDepth) {
      throw Exception(
        "Maximum recursion depth ($maxDepth) exceeded for blueprint '${blueprint.name}'",
      );
    }

    // 1. Deserialize Internal Components
    for (var compData in blueprint.components) {
      LogicComponent comp = _deserializeInternal(compData);
      internalComponents.add(comp);
    }

    // 2. Deserialize Internal Connections
    for (var connData in blueprint.connections) {
      internalConnections.add(Connection.fromJson(connData));
    }

    // 3. Build lookup map
    _buildPinMap();

    // 4. Create External Pins and maps
    // Inputs
    for (int i = 0; i < blueprint.inputPorts.length; i++) {
      String internalPinId = blueprint.inputPorts[i];
      String extId = "$id-in-$i";
      String label = (i < blueprint.inputLabels.length)
          ? blueprint.inputLabels[i]
          : "IN";
      inputs.add(
        Pin(id: extId, componentId: id, type: PinType.input, label: label),
      );
      inputMap[extId] = internalPinId;
    }

    // Outputs
    for (int i = 0; i < blueprint.outputPorts.length; i++) {
      String internalPinId = blueprint.outputPorts[i];
      String extId = "$id-out-$i";
      String label = (i < blueprint.outputLabels.length)
          ? blueprint.outputLabels[i]
          : "OUT";
      outputs.add(
        Pin(id: extId, componentId: id, type: PinType.output, label: label),
      );
      outputMap[extId] = internalPinId;
    }
  }

  void _buildPinMap() {
    _pinMap.clear();
    for (var c in internalComponents) {
      for (var p in c.inputs) {
        _pinMap[p.id] = p;
      }
      for (var p in c.outputs) {
        _pinMap[p.id] = p;
      }
    }
  }

  LogicComponent _deserializeInternal(Map<String, dynamic> json) {
    ComponentType type = ComponentType.values[json['type']];
    Offset pos = Offset(json['position_dx'], json['position_dy']);
    String compId = json['id'];

    switch (type) {
      case ComponentType.and:
        return AndGate(
          id: compId,
          position: pos,
          inputCount: json['inputCount'],
        );
      case ComponentType.nand:
        return NandGate(
          id: compId,
          position: pos,
          inputCount: json['inputCount'],
        );
      case ComponentType.or:
        return OrGate(
          id: compId,
          position: pos,
          inputCount: json['inputCount'],
        );
      case ComponentType.nor:
        return NorGate(
          id: compId,
          position: pos,
          inputCount: json['inputCount'],
        );
      case ComponentType.xor:
        return XorGate(
          id: compId,
          position: pos,
          inputCount: json['inputCount'],
        );
      case ComponentType.nxor:
        return NxorGate(
          id: compId,
          position: pos,
          inputCount: json['inputCount'],
        );
      case ComponentType.inverter:
        return Inverter(id: compId, position: pos);
      case ComponentType.oscillator:
        return Oscillator(
          id: compId,
          position: pos,
          frequency: json['frequency'],
        );
      case ComponentType.led:
        return Led(
          id: compId,
          position: pos,
          colorHigh: json['colorHigh'],
          colorLow: json['colorLow'],
        );
      case ComponentType.segment7:
        return SegmentDisplay(
          id: compId,
          position: pos,
          segments: 7,
          color: json['color'] ?? 0xFF4CAF50,
          fontSize: json['fontSize'] ?? 80.0,
        );
      case ComponentType.segment16:
        return SegmentDisplay(
          id: compId,
          position: pos,
          segments: 16,
          color: json['color'] ?? 0xFF4CAF50,
          fontSize: json['fontSize'] ?? 24.0,
        );
      case ComponentType.constantSource:
        return ConstantSource(
          id: compId,
          position: pos,
          state: json['state'] ?? true,
        );
      case ComponentType.dFlipFlop:
        var ff = DFlipFlop(id: compId, position: pos);
        if (json.containsKey('storedValue'))
          ff.setStoredValue(json['storedValue']);
        return ff;
      case ComponentType.rsFlipFlop:
        var ff = RsFlipFlop(id: compId, position: pos);
        if (json.containsKey('storedValue'))
          ff.setStoredValue(json['storedValue']);
        return ff;
      case ComponentType.jkFlipFlop:
        var ff = JKFlipFlop(id: compId, position: pos);
        if (json.containsKey('storedValue'))
          ff.setStoredValue(json['storedValue']);
        return ff;
      case ComponentType.custom:
        SavedCircuit bp = SavedCircuit.fromJson(json['blueprint']);
        return IntegratedCircuit(
          id: compId,
          position: pos,
          blueprint: bp,
          depth: depth + 1,
        );
      case ComponentType.circuitInput:
        var ci = CircuitInput(id: compId, position: pos);
        if (json.containsKey('label')) ci.label = json['label'];
        return ci;
      case ComponentType.circuitOutput:
        var co = CircuitOutput(id: compId, position: pos);
        if (json.containsKey('label')) co.label = json['label'];
        return co;
      case ComponentType.button:
        var btn = ButtonComponent(id: compId, position: pos);
        if (json.containsKey('isPressed')) btn.isPressed = json['isPressed'];
        return btn;
      case ComponentType.markdownText:
        return MarkdownComponent(
          id: compId,
          position: pos,
          text: json['text'] ?? "",
        );
    }
  }

  Pin? _findInternalPin(String pinId) => _pinMap[pinId];

  @override
  void evaluate() {
    // 1. Sync Inputs (External -> Internal)
    for (var extPin in inputs) {
      String? internalId = inputMap[extPin.id];
      if (internalId != null) {
        Pin? internalPin = _findInternalPin(internalId);
        if (internalPin != null) {
          internalPin.value = extPin.value;
        }
      }
    }

    // 2. Propagate Internal Connections & Evaluate
    // 2 passes - the global tick will handle subsequent settling
    for (int i = 0; i < 2; i++) {
      bool changed = false;
      // Propagate wires
      for (var conn in internalConnections) {
        Pin? src = _findInternalPin(conn.sourcePinId);
        Pin? dst = _findInternalPin(conn.targetPinId);
        if (src != null && dst != null) {
          if (dst.value != src.value) {
            dst.value = src.value;
            changed = true;
          }
        }
      }

      // Evaluate components
      for (var comp in internalComponents) {
        List<bool> oldState = comp.outputs.map((p) => p.value).toList();
        comp.evaluate();
        for (int k = 0; k < comp.outputs.length; k++) {
          if (comp.outputs[k].value != oldState[k]) {
            changed = true;
          }
        }
      }
      if (!changed) break;
    }

    // 3. Sync Outputs (Internal -> External)
    for (var extPin in outputs) {
      String? internalId = outputMap[extPin.id];
      if (internalId != null) {
        Pin? internalPin = _findInternalPin(internalId);
        if (internalPin != null) {
          extPin.value = internalPin.value;
        }
      }
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'position_dx': position.dx,
      'position_dy': position.dy,
      'blueprint': blueprint.toJson(),
    };
  }
}
