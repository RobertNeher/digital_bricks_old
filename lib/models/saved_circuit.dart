class SavedCircuit {
  final String name;
  final List<Map<String, dynamic>> components;
  final List<Map<String, dynamic>> connections;

  SavedCircuit({
    required this.name,
    required this.components,
    required this.connections,
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'components': components, 'connections': connections};
  }

  factory SavedCircuit.fromJson(Map<String, dynamic> json) {
    return SavedCircuit(
      name: json['name'],
      components: List<Map<String, dynamic>>.from(json['components']),
      connections: List<Map<String, dynamic>>.from(json['connections']),
    );
  }
}
