import 'package:digital_bricks/src/and_gate.dart';
import 'package:digital_bricks/src/and_widget.dart';
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
      home: GateDemoPage(title: "Digital Bricks"),
    );
  }
}

class GateDemoPage extends StatefulWidget {
  const GateDemoPage({super.key, required this.title});

  final String title;

  @override
  State<GateDemoPage> createState() => _GateDemoPageState();
}

class _GateDemoPageState extends State<GateDemoPage> {
  late AndGate _gate;
  double _inputCount = 2;

  @override
  void initState() {
    super.initState();
    _gate = AndGate("and1", Offset.zero, inputCount: _inputCount.round());
  }

  void _updateInputCount(double value) {
    setState(() {
      _inputCount = value;
      _gate.updateInputCount(_inputCount.round());
      // Reset inputs to false when resizing for safety/simplicity in this demo
      for (var pin in _gate.inputs) {
        pin.value = false;
      }
      _gate.calculateOutput({});
    });
  }

  void _toggleInput(int index) {
    setState(() {
      _gate.inputs[index].value = !_gate.inputs[index].value;
      _gate.calculateOutput({});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text("Number of Inputs: ${_inputCount.round()}"),
                Slider(
                  value: _inputCount,
                  min: 2,
                  max: 8,
                  divisions: 6,
                  label: _inputCount.round().toString(),
                  onChanged: _updateInputCount,
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Interactive Input Toggles
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_gate.inputs.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ElevatedButton(
                          onPressed: () => _toggleInput(index),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _gate.inputs[index].value ? Colors.green : Colors.grey,
                          ),
                          child: Text("In $index"),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(width: 50),
                  // The Gate Widget
                  AndWidget(gate: _gate),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
