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
  State<GateDemoPage> createState() => _AndGateDemoPageState();
}

class _AndGateDemoPageState extends State<GateDemoPage> {
  late AndGate _AndGate;

  @override
  void initState() {
    super.initState();
    _AndGate = AndGate("and1", Offset.zero, inputCount: 3);
  }

  void _toggleInput(int index) {
    setState(() {
      _AndGate.inputs[index].value = !_AndGate.inputs[index].value;
      _AndGate.calculateOutput({});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Interactive Input Toggles
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_AndGate.inputs.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ElevatedButton(
                          onPressed: () => _toggleInput(index),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _AndGate.inputs[index].value ? Colors.green : Colors.grey,
                          ),
                          child: Text("In $index"),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(width: 50),
                  // The Gate Widget
                  AndWidget(gate: _AndGate),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
