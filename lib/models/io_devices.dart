// import 'dart:async';
import 'package:flutter/material.dart';
import 'logic_component.dart';

class Oscillator extends LogicComponent {
  double frequency; // in Hz
  // Timer? _timer;
  final bool _isOn = false;

  Oscillator({super.id, required super.position, this.frequency = 1.0})
    : super(name: 'OSC', type: ComponentType.oscillator) {
    addOutputPin();
  }

  // Not used directly in loop, but useful if external runner wants it
  @override
  void evaluate() {
    outputs[0].value = _isOn;
  }

  // This needs to be hooked up to the main simulation loop or run independently
  // For a discrete step simulation, "frequency" might define how many ticks it stays on/off.
  // Or, if we use real-time, the UI will toggle it.
  // For now, let's just store the state. The controller will handle timing.

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['frequency'] = frequency;
    return json;
  }
}

class Led extends LogicComponent {
  int colorHigh;
  int colorLow;

  Led({
    super.id,
    required super.position,
    this.colorHigh = 0xFFFF0000, // Red
    this.colorLow = 0xFF550000, // Dark Red
  }) : super(name: 'LED', type: ComponentType.led) {
    addInputPin();
  }

  @override
  void evaluate() {
    // Just holds state
  }

  Color get currentColor =>
      inputs.isNotEmpty && inputs[0].value ? Color(colorHigh) : Color(colorLow);

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['colorHigh'] = colorHigh;
    json['colorLow'] = colorLow;
    return json;
  }
}

class SegmentDisplay extends LogicComponent {
  int segments; // 7 or 16
  int color;
  int backgroundColor; // Unlit segments
  int bodyColor; // Display box background
  double fontSize;

  SegmentDisplay({
    super.id,
    required super.position,
    this.segments = 7,
    this.color = 0xFF4CAF50, // Green
    this.backgroundColor = 0xFF152515, // Dark Greenish-Black default
    this.bodyColor = 0xFF000000, // Black default
    this.fontSize = 80.0,
  }) : super(
         name: '$segments-Seg',
         type: segments == 7 ? ComponentType.segment7 : ComponentType.segment16,
       ) {
    if (segments == 7) {
      // 4 inputs for Hex decoding (0-F)
      for (int i = 0; i < 4; i++) {
        addInputPin();
      }
    } else {
      // 7 inputs for ASCII (0-127) to cover A-Z, a-z
      for (int i = 0; i < 7; i++) {
        addInputPin();
      }
    }
  }

  // Helper to get integer value from inputs
  int get inputValue {
    int val = 0;
    // Reverse bit order:
    // If we want Bottom (last index) to be Bit 0:
    for (int i = 0; i < inputs.length; i++) {
      if (inputs[i].value) {
        // If i=0 (Top) -> Bit (length-1)
        // If i=last -> Bit 0
        val |= (1 << (inputs.length - 1 - i));
      }
    }
    return val;
  }

  // For rendering, the UI widget will read `inputValue` and determine which segments to light up.

  @override
  void evaluate() {
    // Passive
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['segments'] = segments;
    json['color'] = color;
    json['backgroundColor'] = backgroundColor;
    json['bodyColor'] = bodyColor;
    json['fontSize'] = fontSize;
    return json;
  }
}

class ConstantSource extends LogicComponent {
  bool state; // High (true) or Low (false)

  ConstantSource({super.id, required super.position, this.state = true})
    : super(name: 'CONST', type: ComponentType.constantSource) {
    addOutputPin();
    outputs[0].value = state;
  }

  @override
  void evaluate() {
    // Always push state to output
    if (outputs.isNotEmpty) {
      outputs[0].value = state;
    }
  }

  void setState(bool newState) {
    state = newState;
    outputs[0].value = state;
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['state'] = state; // Save custom property
    return json;
  }
}
