import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import 'models/logic_component.dart';
import 'models/markdown_component.dart';
import 'models/gates.dart';
import 'models/io_devices.dart';
import 'models/memory.dart';
import 'models/connection.dart';
import 'models/pin.dart';
import 'models/circuit_io.dart';
import 'utils/file_ops.dart';

class CircuitProvider extends ChangeNotifier {
  List<LogicComponent> components = [];
  List<Connection> connections = [];
  // ignore: unused_field
  Timer? _simulationTimer;
  String circuitSessionId = const Uuid().v4();
  String? currentFilePath;

  // Callback to get current viewport center from UI
  Offset Function()? getViewportCenter;

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
      for (var p in c.inputs) {
        if (p.id == pinId) return p;
      }
      for (var p in c.outputs) {
        if (p.id == pinId) return p;
      }
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

  void selectAll() {
    selectedComponentIds.clear();
    for (var c in components) {
      selectedComponentIds.add(c.id);
    }
    notifyListeners();
  }

  void moveSelectedComponents(Offset delta) {
    if (selectedComponentIds.isEmpty) return;
    for (var c in components) {
      if (selectedComponentIds.contains(c.id)) {
        c.position += delta;
      }
    }
    notifyListeners();
  }

  void updateComponentPosition(String id, Offset delta) {
    try {
      var comp = components.firstWhere((c) => c.id == id);
      comp.position += delta;
      notifyListeners();
    } catch (_) {}
  }

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

  void clearCircuit() {
    components.clear();
    connections.clear();
    selectedComponentIds.clear();
    currentFilePath = null;
    circuitSessionId = const Uuid().v4();
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
      for (var c in selected) {
        c.position = Offset(minX, c.position.dy);
      }
    } else if (axis == 'right') {
      double maxX = selected
          .map((c) => c.position.dx)
          .reduce((a, b) => a > b ? a : b);
      for (var c in selected) {
        c.position = Offset(maxX, c.position.dy);
      }
    } else if (axis == 'top') {
      double minY = selected
          .map((c) => c.position.dy)
          .reduce((a, b) => a < b ? a : b);
      for (var c in selected) {
        c.position = Offset(c.position.dx, minY);
      }
    } else if (axis == 'bottom') {
      double maxY = selected
          .map((c) => c.position.dy)
          .reduce((a, b) => a > b ? a : b);
      for (var c in selected) {
        c.position = Offset(c.position.dx, maxY);
      }
    }

    notifyListeners();
  }

  // --- Save / Load ---

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
    // Web: Use FileOps.saveFile which now supports FS Access API (Save As Picker)
    if (kIsWeb) {
      debugPrint("saveCircuitAs: Web detected, invoking FileOps.saveFile...");
      // We pass a default name, but saveFile will trigger the picker.
      String? savedName = await FileOps.saveFile(
        jsonEncode({
          'components': components.map((c) => c.toJson()).toList(),
          'connections': connections.map((c) => c.toJson()).toList(),
        }),
        "circuit.json",
      );

      if (savedName != null) {
        currentFilePath = savedName;
        debugPrint("saveCircuitAs: Saved to $savedName");
      }
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

  Future<({Map<String, dynamic> data, String name})?>
  pickAndReadCircuit() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) return null;

    PlatformFile pFile = result.files.single;
    if (pFile.path != null) {
      currentFilePath = pFile.path;
    }

    String content = await FileOps.readFile(pFile);
    if (content.isEmpty) return null;

    try {
      final data = jsonDecode(content) as Map<String, dynamic>;
      String name = pFile.name;
      if (name.toLowerCase().endsWith(".json")) {
        name = name.substring(0, name.length - 5);
      }
      return (data: data, name: name);
    } catch (e) {
      debugPrint("Error decoding circuit: $e");
      return null;
    }
  }

  void applyCircuitData(
    Map<String, dynamic> jsonMap, {
    bool clearCanvas = true,
    String? name,
    Offset? position,
  }) {
    if (clearCanvas) {
      components.clear();
      connections.clear();
      selectedComponentIds.clear();
      circuitSessionId = const Uuid().v4();
    }

    final List<dynamic> compsJson = jsonMap['components'];
    final List<dynamic> connsJson = jsonMap['connections'];

    // Map to track old ID -> new component mapping if we were doing deep copy,
    // but here we just deserialize.
    for (var j in compsJson) {
      var comp = _deserializeComponent(j);
      if (comp != null) {
        if (position != null) {
          // If appending, might want to offset?
          // For now just add.
        }
        addComponent(comp);
      }
    }

    for (var j in connsJson) {
      connections.add(Connection.fromJson(j));
    }

    notifyListeners();
  }

  Future<void> loadCircuit({Offset? position}) async {
    final result = await pickAndReadCircuit();
    if (result != null) {
      applyCircuitData(
        result.data,
        clearCanvas: true,
        name: result.name,
        position: position,
      );
    }
  }

  LogicComponent? _deserializeComponent(Map<String, dynamic> json) {
    ComponentType type = ComponentType.values[json['type']];
    Offset pos = Offset(json['position_dx'], json['position_dy']);
    String id = json['id'];

    // HEURISTIC FIX: Detect enum drift in old files (CircuitInput 20 -> 19 as RsFlipFlop)
    if (type == ComponentType.rsFlipFlop && json.containsKey('label')) {
      debugPrint(
        "Correcting component type from RsFlipFlop to CircuitInput (Enum Drift Fix)",
      );
      type = ComponentType.circuitInput;
    }

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
          colorHigh: json['colorHigh'] ?? 0xFFFF0000,
          colorLow: json['colorLow'] ?? 0xFF550000,
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
      case ComponentType.rsFlipFlop:
        comp = RsFlipFlop(id: id, position: pos);
        if (json.containsKey('storedValue')) {
          (comp as RsFlipFlop).setStoredValue(json['storedValue']);
        }
        break;
      case ComponentType.jkFlipFlop:
        comp = JKFlipFlop(id: id, position: pos);
        if (json.containsKey('storedValue')) {
          (comp as JKFlipFlop).setStoredValue(json['storedValue']);
        }
        break;
      case ComponentType.circuitInput:
        comp = CircuitInput(id: id, position: pos);
        if (json.containsKey('label')) {
          (comp as CircuitInput).label = json['label'];
        }
        break;
      case ComponentType.circuitOutput:
        comp = CircuitOutput(id: id, position: pos);
        if (json.containsKey('label')) {
          (comp as CircuitOutput).label = json['label'];
        }
        break;
      case ComponentType.button:
        comp = ButtonComponent(id: id, position: pos);
        if (json.containsKey('isPressed')) {
          (comp as ButtonComponent).isPressed = json['isPressed'];
        }
        if (json.containsKey('label')) {
          (comp as ButtonComponent).label = json['label'];
        }
        break;
      case ComponentType.markdownText:
        comp = MarkdownComponent(
          id: id,
          position: pos,
          text: json['text'] ?? "",
        );
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
      case ComponentType.rsFlipFlop:
        comp = RsFlipFlop(id: id, position: pos);
        break;
      case ComponentType.jkFlipFlop:
        comp = JKFlipFlop(id: id, position: pos);
        break;
      case ComponentType.circuitInput:
        comp = CircuitInput(id: id, position: pos);
        break;
      case ComponentType.circuitOutput:
        comp = CircuitOutput(id: id, position: pos);
        break;
      case ComponentType.button:
        comp = ButtonComponent(id: id, position: pos);
        break;
      case ComponentType.markdownText:
        comp = MarkdownComponent(id: id, position: pos);
        break;
    }

    addComponent(comp);
  }

  void refresh() {
    notifyListeners();
  }
}
