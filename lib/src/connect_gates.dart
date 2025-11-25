import 'package:digital_bricks/src/logic_component.dart';

class ConnectGates {
  late List connections;

  // Source gate: ouput pin
  // Target gate: input pin #, gate id
  ConnectGates() {
    connections = [];
  }

  void connect(LogicComponent sourceGate, String sourcePin,
      LogicComponent targetGate, String targetPin) {
    connections.add({
      'sourceGate': sourceGate,
      'sourcePin': sourcePin,
      'targetGate': targetGate,
      'targetPin': targetPin,
    });
  }

  void disconnect(LogicComponent sourceGate, String sourcePin,
      LogicComponent targetGate, String targetPin) {
    connections.removeWhere((connection) =>
        connection['sourceGate'] == sourceGate &&
        connection['sourcePin'] == sourcePin &&
        connection['targetGate'] == targetGate &&
        connection['targetPin'] == targetPin);
  }

  void disconnectAll() {
    connections.clear();
  }

  void propagate() {
    for (var connection in connections) {
      LogicComponent sourceGate = connection['sourceGate'];
      String sourcePin = connection['sourcePin'];
      LogicComponent targetGate = connection['targetGate'];
      String targetPin = connection['targetPin'];
      bool sourceValue = sourceGate.outputs.contains(sourcePin);
      targetGate.findTargetPin(targetPin).value = sourceValue;
    }
  }
}
