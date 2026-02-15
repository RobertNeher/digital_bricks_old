import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'models/integrated_circuit.dart';
import 'models/circuit_io.dart';
import 'utils/file_ops.dart';

class CircuitProvider extends ChangeNotifier {
  List<LogicComponent> components = [];
  List<Connection> connections = [];
  // ignore: unused_field
  Timer? _simulationTimer;

  // Simulation constants
  // Simulation constants
  static const int _tickRateMs = 50; // 20Hz update rate for UI/Sim
  static const double gridSize = 20.0;

  CircuitProvider() {
    _startSimulation();
    loadBlueprints();
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

      try {
        // Deserialize Components
        for (var curr in jsonMap['components']) {
          components.add(_deserializeComponent(curr));
        }

        // Deserialize Connections
        for (var conn in jsonMap['connections']) {
          connections.add(Connection.fromJson(conn));
        }
      } catch (e) {
        debugPrint("Error loading circuit: $e");
        components.clear();
        connections.clear();
        // Rethrow or handle? For now, we clear and maybe let the UI know if we could.
        // Ideally we should use a ScafoldMessenger here but we are in a Provider.
        // We can throw and catch in the UI if we change the signature, but for now safe fail is better than crash.
        return;
      }

      notifyListeners();
    }
  }

  LogicComponent _deserializeComponent(Map<String, dynamic> json) {
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
      case ComponentType.custom:
        SavedCircuit bp = SavedCircuit.fromJson(json['blueprint']);
        comp = IntegratedCircuit(id: id, position: pos, blueprint: bp);
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
      case ComponentType.custom:
        // Cannot add undefined custom component directly by type
        return;
      case ComponentType.circuitInput:
        comp = CircuitInput(id: id, position: pos);
        break;
      case ComponentType.circuitOutput:
        comp = CircuitOutput(id: id, position: pos);
        break;
      case ComponentType.button:
        comp = ButtonComponent(id: id, position: pos);
        break;
    }

    addComponent(comp);
  }

  // --- Custom Components (Blueprints) ---
  List<SavedCircuit> customCircuits = [];
  int _loadedVersion = -1;

  void _sortBlueprints() {
    customCircuits.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
  }

  Future<void> loadBlueprints() async {
    print("loadBlueprints: Starting...");
    try {
      if (kIsWeb) {
        // --- WEB STRATEGY: PROBING ---
        print("loadBlueprints: Web Mode detected. Using Probing Strategy.");

        String bestAssetKey = 'assets/blueprints.json';
        int maxVersion = -1;

        int consecutiveFailures = 0;
        int gapTolerance = 2;

        // Probe range 1 to 50
        for (int i = 1; i <= 50; i++) {
          String candidateKey = 'assets/blueprints ($i).json';
          try {
            await rootBundle.loadString(candidateKey);
            maxVersion = i;
            bestAssetKey = candidateKey;
            consecutiveFailures = 0;
            print("  Found: $candidateKey (v$i)");
          } catch (e) {
            consecutiveFailures++;
            if (consecutiveFailures > gapTolerance) break;
          }
        }

        print("loadBlueprints: Best Web file is $bestAssetKey (v$maxVersion)");
        await _loadFromAsset(bestAssetKey);
      } else {
        // --- NATIVE STRATEGY: FILESYSTEM ---
        print("loadBlueprints: Native Mode detected. Using FileSystem Scan.");

        String? appDir = await FileOps.getAssetsDirectory();
        if (appDir == null) {
          print("loadBlueprints: Asset directory null. Aborting.");
          return;
        }

        List<String> files = await FileOps.listFiles(appDir);
        // Match "blueprints (N).json" or "blueprints(N).json" etc.
        final RegExp versionPattern = RegExp(
          r'blueprints\s*\(?(\d+)\)?\.json$',
        );

        String? bestFile;
        int maxVersion = -1;

        for (String filePath in files) {
          String fileName = filePath.split(FileOps.pathSeparator).last;
          final match = versionPattern.firstMatch(fileName);
          if (match != null) {
            int version = int.parse(match.group(1)!);
            if (version > maxVersion) {
              maxVersion = version;
              bestFile = filePath;
            }
          }
        }

        if (bestFile != null) {
          print(
            "loadBlueprints: Found latest native file: $bestFile (v$maxVersion)",
          );
          await _loadFromFilePath(bestFile);
        } else {
          String defaultPath = '$appDir${FileOps.pathSeparator}blueprints.json';
          print(
            "loadBlueprints: No versioned files found. Trying default: $defaultPath",
          );
          await _loadFromFilePath(defaultPath);
        }
      }

      notifyListeners();
    } catch (e) {
      print("loadBlueprints: Fatal error: $e");
    }
  }

  Future<void> _loadFromAsset(String assetKey) async {
    try {
      String content = await rootBundle.loadString(assetKey);
      _parseAndLoad(content);
    } catch (e) {
      print("Error loading asset $assetKey: $e");
    }
  }

  Future<void> _loadFromFilePath(String path) async {
    try {
      String content = await FileOps.readFileFromPath(path);
      _parseAndLoad(content);
    } catch (e) {
      print("Error loading file $path: $e");
    }
  }

  void _parseAndLoad(String content) {
    if (content.isEmpty) return;
    List<dynamic> jsonList = jsonDecode(content);
    customCircuits.clear();
    for (var bp in jsonList) {
      customCircuits.add(SavedCircuit.fromJson(bp));
    }
    print("loadBlueprints: Loaded ${customCircuits.length} blueprints.");
  }

  Future<void> _saveBlueprints() async {
    try {
      String? appDir = await FileOps.getAssetsDirectory();

      // Increment version for save
      // If loaded version was -1 (default), next is 1.
      // If loaded version was 5, next is 6.
      int nextVersion = (_loadedVersion < 0) ? 1 : _loadedVersion + 1;

      // Update loaded version for subsequent saves
      _loadedVersion = nextVersion;

      String fileName = 'blueprints ($nextVersion).json';

      String path;
      if (appDir == null) {
        // Fallback for web/no-fs: use simple filename to trigger download in FileOps
        path = fileName;
      } else {
        path = '$appDir${FileOps.pathSeparator}$fileName';
      }

      print("Saving blueprints to version $nextVersion: $path");

      String content = jsonEncode(
        customCircuits.map((e) => e.toJson()).toList(),
      );

      await FileOps.saveFileToPath(path, content);
    } catch (e) {
      debugPrint("Error saving blueprints: $e");
    }
  }

  void saveSelectionAsCustom(String rawName) {
    if (selectedComponentIds.isEmpty) return;
    String name = rawName.trim();
    if (name.isEmpty) return;

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

    // 3. Identify Ports (Unconnected internal pins)
    // Input Ports: Input pins compliant with selection but NOT a target of any internal connection
    List<String> inputPorts = [];
    List<String> outputPorts = [];
    List<String> inputLabels = [];
    List<String> outputLabels = [];

    // ... (Selection Logic)

    // 4. Normalize position
    // ...

    // NEW LOGIC: Check if we have explicit CircuitInput / CircuitOutput components
    // If we do, we use them EXCLUSIVELY for the interface.
    // If not, we fall back to the old logic (implicit ports).

    List<CircuitInput> explicitInputs = selectedComps
        .whereType<CircuitInput>()
        .toList();
    List<CircuitOutput> explicitOutputs = selectedComps
        .whereType<CircuitOutput>()
        .toList();

    bool useExplicit = explicitInputs.isNotEmpty || explicitOutputs.isNotEmpty;

    if (useExplicit) {
      // Clear implicit ports
      inputPorts.clear();
      outputPorts.clear();

      // Sort inputs: Top-to-Bottom, then Left-to-Right
      explicitInputs.sort((a, b) {
        if ((a.position.dy - b.position.dy).abs() > 10) {
          return a.position.dy.compareTo(b.position.dy);
        }
        return a.position.dx.compareTo(b.position.dx);
      });

      // Sort outputs: Top-to-Bottom, then Left-to-Right
      explicitOutputs.sort((a, b) {
        if ((a.position.dy - b.position.dy).abs() > 10) {
          return a.position.dy.compareTo(b.position.dy);
        }
        return a.position.dx.compareTo(b.position.dx);
      });

      for (var inp in explicitInputs) {
        // The input port for the OUTSIDE world connects to the pin that drives the INTERNAL circuit.
        // CircuitInput has 1 output pin.
        // Wait. CircuitInput acts as a source in the internal circuit.
        // It's the "socket" where the outside wire plugs in.
        // So the "Port ID" should be the ID of the pin that is available inside.
        if (inp.outputs.isNotEmpty) {
          inputPorts.add(inp.outputs[0].id);
        }
        if (inp.label.isNotEmpty) {
          inputLabels.add(inp.label);
        } else {
          inputLabels.add("In ${inputPorts.length}");
        }
      }

      for (var out in explicitOutputs) {
        // CircuitOutput acts as a sink in the internal circuit.
        if (out.inputs.isNotEmpty) {
          outputPorts.add(out.inputs[0].id);
        }
        if (out.label.isNotEmpty) {
          outputLabels.add(out.label);
        } else {
          outputLabels.add("Out ${outputPorts.length}");
        }
      }
    }

    // 4. Normalize position
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
      inputPorts: inputPorts,
      outputPorts: outputPorts,
      inputLabels: inputLabels,
      outputLabels: outputLabels,
    );

    // Check for existing by name (case-insensitive)
    int existingIndex = customCircuits.indexWhere(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
    );

    if (existingIndex != -1) {
      debugPrint(
        "Overwriting existing blueprint: ${customCircuits[existingIndex].name} with $name",
      );
      customCircuits[existingIndex] = blueprint;
    } else {
      debugPrint("Saving new blueprint: $name");
      customCircuits.add(blueprint);
    }
    _sortBlueprints();
    _saveBlueprints();
    notifyListeners();
  }

  void instantiateCustomCircuit(SavedCircuit blueprint, Offset dropPos) {
    String id = const Uuid().v4();
    IntegratedCircuit ic = IntegratedCircuit(
      id: id,
      position: dropPos,
      blueprint: blueprint,
    );
    addComponent(ic);
  }

  void renameCustomCircuit(SavedCircuit oldCircuit, String newName) {
    int index = customCircuits.indexOf(oldCircuit);
    if (index != -1) {
      SavedCircuit newCircuit = SavedCircuit(
        name: newName,
        components: oldCircuit.components,
        connections: oldCircuit.connections,
        inputPorts: oldCircuit.inputPorts,
        outputPorts: oldCircuit.outputPorts,
        inputLabels: oldCircuit.inputLabels,
        outputLabels: oldCircuit.outputLabels,
      );
      customCircuits[index] = newCircuit;
      _saveBlueprints();
      notifyListeners();
    }
  }

  void deleteCustomCircuit(SavedCircuit circuit) {
    customCircuits.remove(circuit);
    _saveBlueprints();
    notifyListeners();
  }

  Future<void> importBlueprints() async {
    try {
      final file = await FileOps.pickFile();
      if (file == null) return;

      String content = await FileOps.readFile(file);
      if (content.isEmpty) return;

      List<dynamic> jsonList = jsonDecode(content);
      // Optional: Logic to merge or replace. For now, we append/overwrite by name?
      // Simple strategy: Clear and Replace, OR Append.
      // Given user might be loading their backup, appending might duplicate.
      // Let's deduce from context: "Restore reusable circuits".
      // Safest is to add unique ones or just add all and let user manage.
      // Duplicate names might be confusing though.
      // Let's add them, checking for name collisions is complex UI.

      for (var bp in jsonList) {
        // Check if exists?
        bool exists = customCircuits.any((c) => c.name == bp['name']);
        if (!exists) {
          customCircuits.add(SavedCircuit.fromJson(bp));
        } else {
          // Optional: update existing?
          // customCircuits.removeWhere((c) => c.name == bp['name']);
          // customCircuits.add(SavedCircuit.fromJson(bp));
        }
      }
      notifyListeners();
      print("Imported ${jsonList.length} blueprints.");
    } catch (e) {
      print("Error importing blueprints: $e");
    }
  }

  void unpackIntegratedCircuit(IntegratedCircuit ic) {
    debugPrint("Unpacking IC: ${ic.id}");

    // 1. Capture external connections BEFORE removing IC
    List<Connection> incoming = [];
    List<Connection> outgoing = [];

    for (var conn in connections) {
      if (conn.targetPinId.startsWith(ic.id)) incoming.add(conn);
      if (conn.sourcePinId.startsWith(ic.id)) outgoing.add(conn);
    }

    // 2. Remove IC logic
    components.remove(ic);
    for (var c in incoming) {
      connections.remove(c);
    }
    for (var c in outgoing) {
      connections.remove(c);
    }

    // 3. Prepare Internal Components with NEW IDs
    String groupId = const Uuid().v4();
    Map<String, String> idMap = {}; // Old Comp ID -> New Comp ID
    List<LogicComponent> newComponents = [];

    // Serialize current state to preserve flip-flop values etc.
    List<Map<String, dynamic>> compsJson = ic.internalComponents
        .map((c) => c.toJson())
        .toList();

    for (var compJson in compsJson) {
      String oldId = compJson['id'];
      String newId = const Uuid().v4();
      idMap[oldId] = newId;

      // Update JSON with new ID
      compJson['id'] = newId;

      // Adjust position to absolute
      if (compJson.containsKey('position_dx') &&
          compJson.containsKey('position_dy')) {
        double relX = compJson['position_dx'];
        double relY = compJson['position_dy'];
        compJson['position_dx'] = relX + ic.position.dx;
        compJson['position_dy'] = relY + ic.position.dy;
      }

      // Re-hydrate
      try {
        LogicComponent newComp = _deserializeComponent(compJson);
        newComp.icGroupId = groupId;
        newComp.icBlueprintName = ic.blueprint.name;
        newComponents.add(newComp);
      } catch (e) {
        debugPrint("Error deserializing component during unpack: $e");
      }
    }

    components.addAll(newComponents);

    // Select the new components to restore the "overlay" and give immediate control
    selectedComponentIds.clear();
    selectedComponentIds.addAll(newComponents.map((c) => c.id));

    // 4. Add Internal Connections with UPDATED IDs
    // Helper to find new pin ID given old pin ID (e.g. "oldId-in-0" -> "newId-in-0")
    String? remapPinId(String oldPinId) {
      for (var oldId in idMap.keys) {
        if (oldPinId.startsWith(oldId)) {
          String suffix = oldPinId.substring(oldId.length);
          String newId = idMap[oldId]!;
          return "$newId$suffix";
        }
      }
      return null;
    }

    for (var conn in ic.internalConnections) {
      String? newSource = remapPinId(conn.sourcePinId);
      String? newTarget = remapPinId(conn.targetPinId);

      if (newSource != null && newTarget != null) {
        connections.add(
          Connection(
            id: const Uuid().v4(),
            sourcePinId: newSource,
            targetPinId: newTarget,
          ),
        );
      }
    }

    // 5. Reconnect External Wires
    for (var conn in incoming) {
      if (!conn.targetPinId.contains("-in-")) continue;
      String indexStr = conn.targetPinId.split("-in-").last;
      int? index = int.tryParse(indexStr);

      if (index != null && index < ic.blueprint.inputPorts.length) {
        String oldInternalPinId = ic.blueprint.inputPorts[index];
        String? newInternalPinId = remapPinId(oldInternalPinId);
        if (newInternalPinId != null) {
          addConnection(conn.sourcePinId, newInternalPinId);
        }
      }
    }

    for (var conn in outgoing) {
      if (!conn.sourcePinId.contains("-out-")) continue;
      String indexStr = conn.sourcePinId.split("-out-").last;
      int? index = int.tryParse(indexStr);

      if (index != null && index < ic.blueprint.outputPorts.length) {
        String oldInternalPinId = ic.blueprint.outputPorts[index];
        String? newInternalPinId = remapPinId(oldInternalPinId);
        if (newInternalPinId != null) {
          addConnection(newInternalPinId, conn.targetPinId);
        }
      }
    }

    notifyListeners();
  }

  void repackIntegratedCircuit(String groupId, String blueprintName) {
    // 1. Identify components
    List<LogicComponent> groupComps = components
        .where((c) => c.icGroupId == groupId)
        .toList();

    if (groupComps.isEmpty) return;

    // 2. Identify internal connections
    // A connection is internal if both ends are on components in this group
    List<Connection> internalConnections = connections.where((conn) {
      bool sourceIn = groupComps.any((c) => conn.sourcePinId.startsWith(c.id));
      bool targetIn = groupComps.any((c) => conn.targetPinId.startsWith(c.id));
      return sourceIn && targetIn;
    }).toList();

    // 3. Identify Ports (Scanning anew allows interface changes)
    List<String> inputPorts = [];
    for (var c in groupComps) {
      for (var p in c.inputs) {
        bool isTarget = internalConnections.any(
          (conn) => conn.targetPinId == p.id,
        );
        if (!isTarget) inputPorts.add(p.id);
      }
    }

    List<String> outputPorts = [];
    for (var c in groupComps) {
      for (var p in c.outputs) {
        bool isSource = internalConnections.any(
          (conn) => conn.sourcePinId == p.id,
        );
        if (!isSource) outputPorts.add(p.id);
      }
    }

    // 4. Normalize
    double minX = double.infinity;
    double minY = double.infinity;
    for (var c in groupComps) {
      if (c.position.dx < minX) minX = c.position.dx;
      if (c.position.dy < minY) minY = c.position.dy;
    }

    List<Map<String, dynamic>> compJson = groupComps.map((c) {
      var json = c.toJson();
      json['position_dx'] = c.position.dx - minX;
      json['position_dy'] = c.position.dy - minY;
      return json;
    }).toList();

    List<Map<String, dynamic>> connJson = internalConnections
        .map((c) => c.toJson())
        .toList();

    // 5. Update or Create Blueprint
    SavedCircuit newBlueprint = SavedCircuit(
      name: blueprintName,
      components: compJson,
      connections: connJson,
      inputPorts: inputPorts,
      outputPorts: outputPorts,
    );

    int existingIdx = customCircuits.indexWhere((c) => c.name == blueprintName);
    if (existingIdx != -1) {
      customCircuits[existingIdx] = newBlueprint;
    } else {
      customCircuits.add(newBlueprint);
    }

    // 6. Instantiate new IC
    // We use the top-left of the group as the IC position
    Offset icPos = Offset(minX, minY);
    String icId = const Uuid().v4();
    IntegratedCircuit ic = IntegratedCircuit(
      id: icId,
      position: icPos,
      blueprint: newBlueprint,
    );

    // 7. Reconnect External Connections
    // We need to map [Old Component Pin ID] -> [New IC Pin ID]
    // The Input Ports list is ordered, so IC inputs are id-in-0, id-in-1...
    // The logic matches inputPorts[i] (which is Old Pin ID) to id-in-i

    // Find connections that link [User World] <-> [Group Component]
    // Incoming: World -> Group Component Pin (must be in inputPorts)
    List<Connection> incoming = connections.where((conn) {
      bool sourceOutside = !groupComps.any(
        (c) => conn.sourcePinId.startsWith(c.id),
      );
      bool targetInside = groupComps.any(
        (c) => conn.targetPinId.startsWith(c.id),
      );
      return sourceOutside && targetInside;
    }).toList();

    // Outgoing: Group Component Pin (must be in outputPorts) -> World
    List<Connection> outgoing = connections.where((conn) {
      bool sourceInside = groupComps.any(
        (c) => conn.sourcePinId.startsWith(c.id),
      );
      bool targetOutside = !groupComps.any(
        (c) => conn.targetPinId.startsWith(c.id),
      );
      return sourceInside && targetOutside;
    }).toList();

    // Clean up old components and connections
    for (var c in groupComps) {
      components.remove(c);
    }
    // remove connections involving them
    connections.removeWhere((conn) {
      return groupComps.any(
        (c) =>
            conn.sourcePinId.startsWith(c.id) ||
            conn.targetPinId.startsWith(c.id),
      );
    });

    // Add IC
    components.add(ic);

    // Rebuild external connections
    // Incoming
    for (var conn in incoming) {
      // conn.targetPinId was the internal pin. Find its index in inputPorts.
      int portIndex = inputPorts.indexOf(conn.targetPinId);
      if (portIndex != -1) {
        String icPinId = "$icId-in-$portIndex";
        addConnection(conn.sourcePinId, icPinId);
      }
    }

    // Outgoing
    for (var conn in outgoing) {
      int portIndex = outputPorts.indexOf(conn.sourcePinId);
      if (portIndex != -1) {
        String icPinId = "$icId-out-$portIndex";
        addConnection(icPinId, conn.targetPinId);
      }
    }

    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }
}
