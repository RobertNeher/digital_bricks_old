import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import 'models/logic_component.dart';
import 'models/gates.dart';
import 'models/io_devices.dart';
import 'models/memory.dart';
import 'models/connection.dart';
import 'models/pin.dart';
import 'models/saved_circuit.dart';
import 'utils/file_ops.dart';

class CircuitProvider extends ChangeNotifier {
  List<LogicComponent> components = [];
  List<Connection> connections = [];
  Timer? _simulationTimer;

  // Simulation constants
  // Simulation constants
  static const int _tickRateMs = 50; // 20Hz update rate for UI/Sim
  static const double gridSize = 20.0;

  CircuitProvider() {
    _startSimulation();
  }

  void _startSimulation() {
    _simulationTimer = Timer.periodic(Duration(milliseconds: _tickRateMs), (
      timer,
    ) {
      _tick();
    });
  }

  void _tick() {
    // 1. Update Oscillators
    final now = DateTime.now().millisecondsSinceEpoch;
    bool needsUpdate = false;

    for (var comp in components) {
      if (comp is Oscillator) {
        int periodMs = (1000 / comp.frequency).round();
        if (periodMs == 0) periodMs = 1;
        bool newState = (now % periodMs) < (periodMs / 2);

        bool oldVal = comp.outputs[0].value;
        comp.outputs[0].value = newState;
        if (oldVal != newState) needsUpdate = true;
      }
    }

    // 2. Propagate
    for (int i = 0; i < 5; i++) {
      bool changed = _propagateValues();
      if (changed) needsUpdate = true;
    }

    if (needsUpdate) {
      notifyListeners();
    }
  }

  bool _propagateValues() {
    bool anyChange = false;

    // Transfer values from Outputs to Inputs via Connections
    for (var conn in connections) {
      var sourcePin = _findPin(conn.sourcePinId);
      var targetPin = _findPin(conn.targetPinId);

      if (sourcePin != null && targetPin != null) {
        if (targetPin.value != sourcePin.value) {
          targetPin.value = sourcePin.value;
          anyChange = true;
        }
      }
    }

    // Evaluate Components
    for (var comp in components) {
      if (comp is! Oscillator && comp is! ConstantSource) {
        List<bool> oldOutputs = comp.outputs.map((p) => p.value).toList();
        comp.evaluate();
        for (int k = 0; k < comp.outputs.length; k++) {
          if (comp.outputs[k].value != oldOutputs[k]) anyChange = true;
        }
      } else if (comp is ConstantSource) {
        // Ensure constant source maintains its state
        if (comp.outputs.isNotEmpty && comp.outputs[0].value != comp.state) {
          comp.outputs[0].value = comp.state;
          anyChange = true;
        }
      }
    }

    return anyChange;
  }

  Pin? _findPin(String pinId) {
    for (var c in components) {
      for (var p in c.inputs) if (p.id == pinId) return p;
      for (var p in c.outputs) if (p.id == pinId) return p;
    }
    return null;
  }

  // --- Actions ---

  void addComponent(LogicComponent component) {
    components.add(component);
    notifyListeners();
  }

  void removeComponent(String id) {
    components.removeWhere((c) => c.id == id);

    // Find connections attached to this component
    List<String> connectionsToRemove = [];
    for (var conn in connections) {
      if (conn.sourcePinId.startsWith(id) || conn.targetPinId.startsWith(id)) {
        connectionsToRemove.add(conn.id);
      }
    }

    // Remove them one by one to trigger pin reset logic
    for (var connId in connectionsToRemove) {
      removeConnection(connId);
    }

    notifyListeners();
  }

  void addConnection(String sourcePinId, String targetPinId) {
    connections.removeWhere((c) => c.targetPinId == targetPinId);

    connections.add(
      Connection(
        id: const Uuid().v4(),
        sourcePinId: sourcePinId,
        targetPinId: targetPinId,
      ),
    );
    notifyListeners();
  }

  void removeConnection(String connectionId) {
    int index = connections.indexWhere((c) => c.id == connectionId);
    if (index != -1) {
      // Logic to reset the target pin to false (floating input = low)
      var conn = connections[index];
      var targetPin = _findPin(conn.targetPinId);
      if (targetPin != null) {
        targetPin.value = false;
      }
      connections.removeAt(index);
      notifyListeners();
    }
  }

  // --- Selection ---
  final Set<String> selectedComponentIds = {};

  void selectComponent(String id, {bool additive = false}) {
    if (!additive) {
      selectedComponentIds.clear();
    }
    selectedComponentIds.add(id);
    notifyListeners();
  }

  void deselectComponent(String id) {
    selectedComponentIds.remove(id);
    notifyListeners();
  }

  void toggleComponentSelection(String id) {
    if (selectedComponentIds.contains(id)) {
      selectedComponentIds.remove(id);
    } else {
      selectedComponentIds.add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    if (selectedComponentIds.isNotEmpty) {
      selectedComponentIds.clear();
      notifyListeners();
    }
  }

  bool isSelected(String id) => selectedComponentIds.contains(id);

  // --- Bulk Actions ---

  void deleteSelectedComponents() {
    if (selectedComponentIds.isEmpty) return;

    // Create a copy to iterate safely
    final idsToRemove = Set<String>.from(selectedComponentIds);

    for (var id in idsToRemove) {
      removeComponent(id);
    }
    selectedComponentIds.clear();
    notifyListeners();
  }

  void alignSelectedComponents(String axis) {
    if (selectedComponentIds.length < 2) return;

    List<LogicComponent> selected = components
        .where((c) => selectedComponentIds.contains(c.id))
        .toList();

    if (selected.isEmpty) return;

    if (axis == 'left') {
      double minX = selected
          .map((c) => c.position.dx)
          .reduce((a, b) => a < b ? a : b);
      for (var c in selected) c.position = Offset(minX, c.position.dy);
    } else if (axis == 'right') {
      double maxX = selected
          .map((c) => c.position.dx)
          .reduce((a, b) => a > b ? a : b);
      for (var c in selected) c.position = Offset(maxX, c.position.dy);
    } else if (axis == 'top') {
      double minY = selected
          .map((c) => c.position.dy)
          .reduce((a, b) => a < b ? a : b);
      for (var c in selected) c.position = Offset(c.position.dx, minY);
    } else if (axis == 'bottom') {
      double maxY = selected
          .map((c) => c.position.dy)
          .reduce((a, b) => a > b ? a : b);
      for (var c in selected) c.position = Offset(c.position.dx, maxY);
    }

    notifyListeners();
  }

  // --- Save / Load ---

  String? currentFilePath;

  // Generic save: requires currentFilePath or prompts user
  Future<void> saveCurrentCircuit() async {
    if (currentFilePath != null) {
      await saveCircuitToPath(currentFilePath!);
    } else {
      await saveCircuitAs();
    }
  }

  Future<void> saveCircuitAs() async {
    // Web: FilePicker.saveFile is not useful for path selection. Just trigger download.
    if (kIsWeb) {
      debugPrint(
        "saveCircuitAs: Web detected, skipping picker and downloading...",
      );
      await saveCircuitToPath("circuit.json");
      return;
    }

    // Desktop/Mobile: Use FilePicker
    debugPrint("saveCircuitAs: requesting save file dialog...");
    try {
      String? initialDir = await FileOps.getAssetsDirectory();
      debugPrint("saveCircuitAs: using initialDir: $initialDir");

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Circuit As',
        fileName: 'circuit.json',
        initialDirectory: initialDir,
      );
      debugPrint("saveCircuitAs: dialog returned: $outputFile");

      if (outputFile != null) {
        currentFilePath = outputFile;
        await saveCircuitToPath(outputFile);
      } else {
        debugPrint("saveCircuitAs: cancelled by user");
      }
    } catch (e) {
      debugPrint("saveCircuitAs: ERROR: $e");
      // Fallback: try without initialDirectory if it failed?
      // But we can't retry easily inside the same flow without user action usually.
    }
  }

  Future<void> saveCircuitToPath(String path) async {
    debugPrint("saveCircuitToPath: saving to $path");
    final jsonMap = {
      'components': components.map((c) => c.toJson()).toList(),
      'connections': connections.map((c) => c.toJson()).toList(),
    };
    String content = jsonEncode(jsonMap);
    debugPrint(
      "saveCircuitToPath: encoding complete, writing using FileOps...",
    );
    await FileOps.saveFileToPath(path, content);
    debugPrint("saveCircuitToPath: write complete");
  }

  Future<void> loadCircuit() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      PlatformFile pFile = result.files.single;
      if (pFile.path != null) {
        currentFilePath = pFile.path;
      }

      String content = await FileOps.readFile(pFile);
      if (content.isEmpty) return; // or handle error

      Map<String, dynamic> jsonMap = jsonDecode(content);

      components.clear();
      connections.clear();

      // Deserialize Components
      for (var curr in jsonMap['components']) {
        components.add(_deserializeComponent(curr));
      }

      // Deserialize Connections
      for (var conn in jsonMap['connections']) {
        connections.add(Connection.fromJson(conn));
      }

      notifyListeners();
    }
  }

  LogicComponent _deserializeComponent(Map<String, dynamic> json) {
    ComponentType type = ComponentType.values[json['type']];
    Offset pos = Offset(json['position_dx'], json['position_dy']);
    String id = json['id'];

    LogicComponent? comp;

    switch (type) {
      case ComponentType.and:
        comp = AndGate(id: id, position: pos, inputCount: json['inputCount']);
        break;
      case ComponentType.nand:
        comp = NandGate(id: id, position: pos, inputCount: json['inputCount']);
        break;
      case ComponentType.or:
        comp = OrGate(id: id, position: pos, inputCount: json['inputCount']);
        break;
      case ComponentType.nor:
        comp = NorGate(id: id, position: pos, inputCount: json['inputCount']);
        break;
      case ComponentType.xor:
        comp = XorGate(id: id, position: pos, inputCount: json['inputCount']);
        break;
      case ComponentType.nxor:
        comp = NxorGate(id: id, position: pos, inputCount: json['inputCount']);
        break;
      case ComponentType.inverter:
        comp = Inverter(id: id, position: pos);
        break;
      case ComponentType.oscillator:
        comp = Oscillator(id: id, position: pos, frequency: json['frequency']);
        break;
      case ComponentType.led:
        comp = Led(
          id: id,
          position: pos,
          colorHigh: json['colorHigh'],
          colorLow: json['colorLow'],
        );
        break;
      case ComponentType.segment7:
        comp = SegmentDisplay(
          id: id,
          position: pos,
          segments: 7,
          color: json['color'] ?? 0xFF4CAF50,
          fontSize: json['fontSize'] ?? 80.0,
        );
        break;
      case ComponentType.segment16:
        comp = SegmentDisplay(
          id: id,
          position: pos,
          segments: 16,
          color: json['color'] ?? 0xFF4CAF50,
          fontSize: json['fontSize'] ?? 24.0,
        );
        break;
      case ComponentType.constantSource:
        bool state = json['state'] ?? true;
        comp = ConstantSource(id: id, position: pos, state: state);
        break;
      case ComponentType.dFlipFlop:
        comp = DFlipFlop(id: id, position: pos);
        if (json.containsKey('storedValue')) {
          (comp as DFlipFlop).setStoredValue(json['storedValue']);
        }
        break;
    }

    return comp;
  }

  void addComponentByType(ComponentType type, Offset pos) {
    LogicComponent? comp;
    String id = const Uuid().v4();

    switch (type) {
      case ComponentType.and:
        comp = AndGate(id: id, position: pos);
        break;
      case ComponentType.nand:
        comp = NandGate(id: id, position: pos);
        break;
      case ComponentType.or:
        comp = OrGate(id: id, position: pos);
        break;
      case ComponentType.nor:
        comp = NorGate(id: id, position: pos);
        break;
      case ComponentType.xor:
        comp = XorGate(id: id, position: pos);
        break;
      case ComponentType.nxor:
        comp = NxorGate(id: id, position: pos);
        break;
      case ComponentType.inverter:
        comp = Inverter(id: id, position: pos);
        break;
      case ComponentType.oscillator:
        comp = Oscillator(id: id, position: pos);
        break;
      case ComponentType.led:
        comp = Led(id: id, position: pos);
        break;
      case ComponentType.segment7:
        comp = SegmentDisplay(id: id, position: pos, segments: 7);
        break;
      case ComponentType.segment16:
        comp = SegmentDisplay(id: id, position: pos, segments: 16);
        break;
      case ComponentType.constantSource:
        comp = ConstantSource(id: id, position: pos);
        break;
      case ComponentType.dFlipFlop:
        comp = DFlipFlop(id: id, position: pos);
        break;
    }

    addComponent(comp!);
  }

  // --- Custom Components (Blueprints) ---
  List<SavedCircuit> customCircuits = [];

  Future<void> loadBlueprints() async {
    try {
      String? appDir = await FileOps.getAssetsDirectory();
      if (appDir == null) return;

      // Simple local storage read if implementing properly
      // For now, let's keep it in memory or try to read a specific file
      // NOTE: FileOps doesn't have listDir, so we might need a fixed file name
      // Let's assume 'blueprints.json' in app dir.
    } catch (e) {
      debugPrint("Error loading blueprints: $e");
    }
  }

  void saveSelectionAsCustom(String name) {
    if (selectedComponentIds.isEmpty) return;

    // 1. Identify components
    List<LogicComponent> selectedComps = components
        .where((c) => selectedComponentIds.contains(c.id))
        .toList();

    if (selectedComps.isEmpty) return;

    // 2. Identify internal connections (both ends selected)
    List<Connection> internalConnections = connections.where((conn) {
      bool sourceIn = selectedComponentIds.any(
        (id) => conn.sourcePinId.startsWith(id),
      );
      bool targetIn = selectedComponentIds.any(
        (id) => conn.targetPinId.startsWith(id),
      );
      return sourceIn && targetIn;
    }).toList();

    // 3. Normalize position
    // Find top-left
    double minX = double.infinity;
    double minY = double.infinity;
    for (var c in selectedComps) {
      if (c.position.dx < minX) minX = c.position.dx;
      if (c.position.dy < minY) minY = c.position.dy;
    }

    // Serialize with normalized position
    List<Map<String, dynamic>> compJson = selectedComps.map((c) {
      var json = c.toJson();
      json['position_dx'] = c.position.dx - minX;
      json['position_dy'] = c.position.dy - minY;
      return json;
    }).toList();

    List<Map<String, dynamic>> connJson = internalConnections
        .map((c) => c.toJson())
        .toList();

    SavedCircuit blueprint = SavedCircuit(
      name: name,
      components: compJson,
      connections: connJson,
    );

    customCircuits.add(blueprint);
    notifyListeners();
  }

  void instantiateCustomCircuit(SavedCircuit blueprint, Offset dropPos) {
    // We need to map Old IDs -> New IDs to reconstruct connections accurately
    Map<String, String> idMap = {}; // oldId -> newId

    // 1. Create Components
    for (var compData in blueprint.components) {
      String oldId = compData['id'];
      String newId = const Uuid().v4();
      idMap[oldId] = newId;

      // Create new component copy
      // We deserialized logic is in _deserializeComponent but that expects exact IDs?
      // Actually _deserializeComponent takes the JSON. We can modify the JSON 'id' and 'position' before passing it.

      Map<String, dynamic> newJson = Map.from(compData);
      newJson['id'] = newId;
      newJson['position_dx'] = (compData['position_dx'] as double) + dropPos.dx;
      newJson['position_dy'] = (compData['position_dy'] as double) + dropPos.dy;

      LogicComponent newComp = _deserializeComponent(newJson);
      components.add(newComp);
    }

    // 2. Create Connections
    for (var connData in blueprint.connections) {
      String oldSourcePin = connData['sourcePinId'];
      String oldTargetPin = connData['targetPinId'];

      // Resolve new pin IDs
      // Pin ID format: "compId-pinIndex" ??
      // Actually PinWidget uses pin.id.
      // If pin IDs are constructed as "$compId-$index", we can reconstruct them.
      // But let's check how Pin IDs are generated. LogicComponent generates them in constructor or addInputPin?
      // LogicComponent:
      //  addInputPin() -> inputs.add(Pin(..., id: "$id-in-$index"))
      // So yes, they are deterministic based on ComponentID.

      // Parse old IDs to find pin index or suffix
      String newSourcePin = _remapPinId(oldSourcePin, idMap);
      String newTargetPin = _remapPinId(oldTargetPin, idMap);

      if (newSourcePin.isNotEmpty && newTargetPin.isNotEmpty) {
        addConnection(newSourcePin, newTargetPin);
      }
    }

    notifyListeners();
  }

  String _remapPinId(String oldPinId, Map<String, String> idMap) {
    // Attempt to find the component ID prefix
    // oldPinId could be "d23a...-in-0"
    // We iterate idMap to find which oldCompId is a prefix of oldPinId
    for (var entry in idMap.entries) {
      String oldCompId = entry.key;
      if (oldPinId.startsWith(oldCompId)) {
        String suffix = oldPinId.substring(oldCompId.length);
        return "${entry.value}$suffix";
      }
    }
    return "";
  }

  void refresh() {
    notifyListeners();
  }
}
