import 'package:digital_bricks/src/and_gate.dart';
import 'package:digital_bricks/src/and_widget.dart';
import 'package:digital_bricks/src/or_gate.dart';
import 'package:digital_bricks/src/or_widget.dart';
import 'package:digital_bricks/src/oscillator.dart';
import 'package:digital_bricks/src/oscillator_widget.dart';
import 'package:digital_bricks/src/draggable_widget.dart';
import 'package:digital_bricks/src/logic_component.dart';
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

  String _generateId(String prefix) {
    return "$prefix${_idCounter++}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
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
