import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import 'models/logic_component.dart';
import 'models/gates.dart';
import 'models/io_devices.dart';
import 'models/connection.dart';
import 'models/pin.dart';
import 'utils/file_ops.dart';

class CircuitProvider extends ChangeNotifier {
  List<LogicComponent> components = [];
  List<Connection> connections = [];
  Timer? _simulationTimer;

  // Simulation constants
  static const int _tickRateMs = 50; // 20Hz update rate for UI/Sim

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
    connections.removeWhere(
      (c) => c.sourcePinId.startsWith(id) || c.targetPinId.startsWith(id),
    );
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
    connections.removeWhere((c) => c.id == connectionId);
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
        comp = SegmentDisplay(id: id, position: pos, segments: 7);
        break;
      case ComponentType.segment16:
        comp = SegmentDisplay(id: id, position: pos, segments: 16);
        break;
      case ComponentType.constantSource:
        bool state = json['state'] ?? true;
        comp = ConstantSource(id: id, position: pos, state: state);
        break;
    }

    return comp!;
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
    }

    if (comp != null) {
      addComponent(comp);
    }
  }

  void refresh() {
    notifyListeners();
  }
}
