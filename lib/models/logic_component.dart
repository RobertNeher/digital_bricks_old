import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'pin.dart';

enum ComponentType {
  and,
  nand,
  or,
  nor,
  xor,
  nxor,
  inverter,
  oscillator,
  led,
  segment7,
  segment16,
  constantSource,
  dFlipFlop,
  custom, // Integrated Circuit
}

abstract class LogicComponent {
  String id;
  String name;
  Offset position;
  ComponentType type;
  List<Pin> inputs = [];
  List<Pin> outputs = [];

  // For Unpack/Repack tracking
  String? icGroupId;
  String? icBlueprintName;

  // Base constructor
  LogicComponent({
    String? id,
    required this.name,
    required this.position,
    required this.type,
  }) : id = id ?? const Uuid().v4();

  // Abstract method to update component physics/logic
  void evaluate();

  // Helper to init pins
  void addInputPin() {
    inputs.add(
      Pin(id: '$id-in-${inputs.length}', componentId: id, type: PinType.input),
    );
  }

  void addOutputPin() {
    outputs.add(
      Pin(
        id: '$id-out-${outputs.length}',
        componentId: id,
        type: PinType.output,
      ),
    );
  }

  // Serialization methods must be implemented or handled by a factory
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'position_dx': position.dx,
      'position_dy': position.dy,
      'inputs': inputs.map((e) => e.toJson()).toList(),
      'outputs': outputs.map((e) => e.toJson()).toList(),
      // Subclasses should add their specific params
    };
  }

  // For deserialization, we will likely need a factory or static method
  // that switches on ComponentType
}
