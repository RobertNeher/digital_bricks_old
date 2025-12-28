class SavedCircuit {
  final String name;
  final List<Map<String, dynamic>> components;
  final List<Map<String, dynamic>> connections;
  final List<String>
  inputPorts; // IDs of internal pins that are exposed as inputs
  final List<String>
  outputPorts; // IDs of internal pins that are exposed as outputs
  final List<String> inputLabels;
  final List<String> outputLabels;

  SavedCircuit({
    required this.name,
    required this.components,
    required this.connections,
    required this.inputPorts,
    required this.outputPorts,
    this.inputLabels = const [],
    this.outputLabels = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'components': components,
      'connections': connections,
      'inputPorts': inputPorts,
      'outputPorts': outputPorts,
      'inputLabels': inputLabels,
      'outputLabels': outputLabels,
    };
  }

  factory SavedCircuit.fromJson(Map<String, dynamic> json) {
    return SavedCircuit(
      name: json['name'],
      components: List<Map<String, dynamic>>.from(json['components']),
      connections: List<Map<String, dynamic>>.from(json['connections']),
      inputPorts: List<String>.from(json['inputPorts'] ?? []),
      outputPorts: List<String>.from(json['outputPorts'] ?? []),
      inputLabels: List<String>.from(json['inputLabels'] ?? []),
      outputLabels: List<String>.from(json['outputLabels'] ?? []),
    );
  }
}
