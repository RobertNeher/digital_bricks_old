import 'dart:convert';
import 'dart:io';

import 'package:digital_bricks/src/about_page.dart';
import 'package:digital_bricks/src/and_gate.dart';
import 'package:digital_bricks/src/and_widget.dart';
import 'package:digital_bricks/src/or_gate.dart';
import 'package:digital_bricks/src/or_widget.dart';
import 'package:digital_bricks/src/oscillator.dart';
import 'package:digital_bricks/src/oscillator_widget.dart';
import 'package:digital_bricks/src/draggable_widget.dart';
import 'package:digital_bricks/src/logic_component.dart';
import 'package:digital_bricks/src/settings_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const DigitalBricksApp());
}

class DigitalBricksApp extends StatelessWidget {
  const DigitalBricksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: GateDemoPage(title: "Digital Bricks"),
    );
  }
}

class GateDemoPage extends StatefulWidget {
  const GateDemoPage({super.key, required this.title});

  final String title;

  @override
  State<GateDemoPage> createState() => _AndGateDemoPageState();
}

class _AndGateDemoPageState extends State<GateDemoPage> {
  final List<LogicComponent> _components = [];
  int _idCounter = 0;
  double _minDistance = 50.0;

  @override
  void initState() {
    super.initState();
    // Initialize with some demo components
    _components.add(
        AndGate(id: "and1", position: const Offset(300, 50), inputCount: 2));
    _components.add(
        OrGate(id: "or1", position: const Offset(300, 200), inputCount: 2));
  }

  void _addComponent(LogicComponent component) {
    setState(() {
      _components.add(component);
    });
  }

  void _repositionComponents() {
    bool moved;
    int iterations = 0;
    const int maxIterations = 100;

    do {
      moved = false;
      iterations++;
      for (int i = 0; i < _components.length; i++) {
        for (int j = i + 1; j < _components.length; j++) {
          final c1 = _components[i];
          final c2 = _components[j];

          // Simple distance check (center to center approx)
          // Assuming component size roughly 100x100 for simplicity of center calculation
          // Better approach: Use actual bounds if available, but center-center is a good start
          final center1 = c1.position + const Offset(50, 50);
          final center2 = c2.position + const Offset(50, 50);

          final distance = (center1 - center2).distance;

          // Minimum required distance (size + buffer)
          // Assuming size is approx 100, so min center-center distance should be 100 + _minDistance
          // Actually, let's treat _minDistance as the gap between edges.
          // If size is 100, then min center distance = 100 + _minDistance
          final minCenterDist = 100.0 + _minDistance;

          if (distance < minCenterDist) {
            // Move them apart
            final direction = (center1 - center2).direction;
            final moveDist = (minCenterDist - distance) / 2;

            final moveVec = Offset.fromDirection(direction, moveDist);

            setState(() {
              c1.position += moveVec;
              c2.position -= moveVec;
            });
            moved = true;
          }
        }
      }
    } while (moved && iterations < maxIterations);
  }

  String _generateId(String prefix) {
    return "$prefix${_idCounter++}";
  }

  Future<void> _saveCircuit() async {
    final List<Map<String, dynamic>> jsonList =
        _components.map((c) => c.toJson()).toList();
    final String jsonString = jsonEncode(jsonList);
    final File file = File('assets/digital_bricks.json');
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    await file.writeAsString(jsonString);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Circuit saved to assets/digital_bricks.json')));
    }
  }

  Future<void> _loadCircuit() async {
    final File file = File('assets/digital_bricks.json');
    if (await file.exists()) {
      final String jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      setState(() {
        _components.clear();
        for (var json in jsonList) {
          _components.add(
              LogicComponent.fromJson(json, setState: () => setState(() {})));
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Circuit loaded from assets/digital_bricks.json')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No saved circuit found')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Digital Bricks',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('Settings'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SettingsPage(minDistance: _minDistance),
                  ),
                );
                if (result != null && result is double) {
                  setState(() {
                    _minDistance = result;
                  });
                }
              },
            ),
            ListTile(
              title: const Text('About'),
              onTap: () {
                // Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AboutPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view),
            onPressed: _repositionComponents,
            tooltip: 'Reposition Components',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveCircuit,
            tooltip: 'Save Circuit',
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _loadCircuit,
            tooltip: 'Load Circuit',
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 120,
            color: Colors.grey[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text("Components",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildSidebarItem("AND Gate", "AND"),
                _buildSidebarItem("OR Gate", "OR"),
                _buildSidebarItem("Oscillator", "OSC"),
              ],
            ),
          ),
          // Workspace
          Expanded(
            child: DragTarget<String>(
              onAcceptWithDetails: (DragTargetDetails<String> details) {
                final renderBox = context.findRenderObject() as RenderBox;
                final localPosition = renderBox.globalToLocal(details.offset);

                LogicComponent? newComponent;
                if (details.data == "AND") {
                  newComponent = AndGate(
                      id: _generateId("and"),
                      position: localPosition,
                      inputCount: 2);
                } else if (details.data == "OR") {
                  newComponent = OrGate(
                      id: _generateId("or"),
                      position: localPosition,
                      inputCount: 2);
                } else if (details.data == "OSC") {
                  newComponent = Oscillator(
                      id: _generateId("osc"),
                      position: localPosition,
                      frequency: 1.0,
                      setState: () => setState(() {}));
                }

                if (newComponent != null) {
                  _addComponent(newComponent);
                }
              },
              builder: (context, List<String?> candidateData,
                  List<dynamic> rejectedData) {
                return Stack(
                  children: [
                    // Grid or background could go here
                    ..._components.map((component) {
                      Widget widget;
                      if (component is AndGate) {
                        widget = AndWidget(gate: component);
                      } else if (component is OrGate) {
                        widget = OrWidget(gate: component);
                      } else if (component is Oscillator) {
                        widget = OscillatorWidget(oscillator: component);
                      } else {
                        widget = const SizedBox();
                      }

                      return DraggableWidget(
                        component: component,
                        onDrag: () => setState(() {}),
                        child: widget,
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(String label, String type) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Draggable<String>(
        data: type,
        feedback: Material(
          child: Container(
            padding: const EdgeInsets.all(8),
            color: Colors.blue.withValues(alpha: 0.5),
            child: Text(label),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(5),
            color: Colors.white,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
