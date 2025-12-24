enum PinType { input, output }

class Pin {
  final String id; // Unique ID for the pin (usually "componentId-pinIndex")
  final String componentId;
  final PinType type;
  bool value;

  Pin({
    required this.id,
    required this.componentId,
    required this.type,
    this.value = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'componentId': componentId,
      'type': type.index,
      'value': value,
    };
  }

  factory Pin.fromJson(Map<String, dynamic> json) {
    return Pin(
      id: json['id'],
      componentId: json['componentId'],
      type: PinType.values[json['type']],
      value: json['value'] ?? false,
    );
  }
}
