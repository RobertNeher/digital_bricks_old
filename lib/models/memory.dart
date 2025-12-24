import 'logic_component.dart';

class DFlipFlop extends LogicComponent {
  bool _storedValue = false;
  bool _lastClock = false;

  DFlipFlop({super.id, required super.position})
    : super(name: 'D-FF', type: ComponentType.dFlipFlop) {
    // Inputs: 0: D, 1: Clock
    addInputPin(); // D
    addInputPin(); // Clock

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

    bool d = inputs[0].value;
    bool clk = inputs[1].value;

    // Rising edge detection: Low -> High
    if (clk != _lastClock && clk) {
      _storedValue = d;
      outputs[0].value = _storedValue;
      outputs[1].value = !_storedValue;
    }

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
