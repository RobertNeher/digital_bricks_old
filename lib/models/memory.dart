import 'logic_component.dart';

class DFlipFlop extends LogicComponent {
  bool _storedValue = false;
  bool _lastClock = false;

  DFlipFlop({super.id, required super.position})
    : super(name: 'D-FF', type: ComponentType.dFlipFlop) {
    // Inputs: 0: D, 1: Clock, 2: Preset, 3: Clear
    addInputPin(); // D
    addInputPin(); // Clock
    addInputPin(); // Preset
    addInputPin(); // Clear

    // Outputs: 0: Q, 1: Q_not
    addOutputPin(); // Q
    addOutputPin(); // Q_not

    // Initial state
    outputs[0].value = false;
    outputs[1].value = true;
  }

  @override
  void evaluate() {
    if (inputs.length < 4) return;

    bool d = inputs[0].value;
    bool clk = inputs[1].value;
    bool pre = inputs[2].value;
    bool clr = inputs[3].value;

    // Asynchronous Logic (Highest Priority)
    if (clr) {
      _storedValue = false;
    } else if (pre) {
      _storedValue = true;
    } else {
      // Synchronous Logic (Rising Edge)
      if (clk != _lastClock && clk) {
        _storedValue = d;
      }
    }

    // Update Outputs
    outputs[0].value = _storedValue;
    outputs[1].value = !_storedValue;

    _lastClock = clk;
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['storedValue'] = _storedValue;
    return json;
  }

  // Need to restore state if deserialized?
  // Usually we create fresh, but for proper save/load we might want exact state.
  // We can add a named constructor or setter.
  void setStoredValue(bool val) {
    _storedValue = val;
    outputs[0].value = val;
    outputs[1].value = !val;
  }
}

class RsFlipFlop extends LogicComponent {
  bool _storedValue = false;

  // Note: We don't have a clock, so we just check state changes or steady state?
  // RS Flip Flop (NOR-based usually):
  // S=1, R=0 -> Set (1)
  // S=0, R=1 -> Reset (0)
  // S=0, R=0 -> Hold
  // S=1, R=1 -> Invalid (usually Q=0, Qnot=0 in NOR latch)

  RsFlipFlop({super.id, required super.position})
    : super(name: 'RS-FF', type: ComponentType.rsFlipFlop) {
    // Inputs: 0: S, 1: R
    addInputPin(); // S
    addInputPin(); // R

    // Outputs: 0: Q, 1: Q_not
    addOutputPin(); // Q
    addOutputPin(); // Q_not

    // Initial state
    outputs[0].value = false;
    outputs[1].value = true;
  }

  @override
  void evaluate() {
    if (inputs.length < 2) return;

    bool s = inputs[0].value;
    bool r = inputs[1].value;

    if (s && !r) {
      _storedValue = true;
    } else if (!s && r) {
      _storedValue = false;
    } else if (s && r) {
      // Invalid state. For NOR latch, both outputs go Low.
      _storedValue = false;
    }
    // Else 0,0 -> Hold

    outputs[0].value = _storedValue;
    outputs[1].value = !_storedValue;

    // Correction for S=1, R=1:
    if (s && r) {
      outputs[0].value = false;
      outputs[1].value = false;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['storedValue'] = _storedValue;
    return json;
  }

  void setStoredValue(bool val) {
    _storedValue = val;
    outputs[0].value = val;
    outputs[1].value = !val;
  }
}

class JKFlipFlop extends LogicComponent {
  bool _storedValue = false;
  bool _lastClock = false;

  JKFlipFlop({super.id, required super.position})
    : super(name: 'JK-FF', type: ComponentType.jkFlipFlop) {
    // Inputs: 0: J, 1: K, 2: Clock, 3: Preset, 4: Clear
    addInputPin(); // J
    addInputPin(); // K
    addInputPin(); // Clock
    addInputPin(); // Preset
    addInputPin(); // Clear

    // Outputs: 0: Q, 1: Q_not
    addOutputPin(); // Q
    addOutputPin(); // Q_not

    // Initial state
    outputs[0].value = false;
    outputs[1].value = true;
  }

  @override
  void evaluate() {
    if (inputs.length < 5) return;

    bool j = inputs[0].value;
    bool k = inputs[1].value;
    bool clk = inputs[2].value;
    bool pre = inputs[3].value;
    bool clr = inputs[4].value;

    // Asynchronous Logic (Highest Priority)
    if (clr) {
      _storedValue = false;
    } else if (pre) {
      _storedValue = true;
    } else {
      // Synchronous Logic (Rising Edge)
      if (clk != _lastClock && clk) {
        if (!j && !k) {
          // No Change
        } else if (j && !k) {
          // Set
          _storedValue = true;
        } else if (!j && k) {
          // Reset
          _storedValue = false;
        } else if (j && k) {
          // Toggle
          _storedValue = !_storedValue;
        }
      }
    }

    // Update Outputs
    outputs[0].value = _storedValue;
    outputs[1].value = !_storedValue;

    _lastClock = clk;
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['storedValue'] = _storedValue;
    return json;
  }

  void setStoredValue(bool val) {
    _storedValue = val;
    outputs[0].value = val;
    outputs[1].value = !val;
  }
}
