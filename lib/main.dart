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
  late AndGate _AndGate1, _AndGate2;

  @override
  void initState() {
    super.initState();
    _AndGate1 = AndGate("and1", Offset(0, 0), inputCount: 3);
    _AndGate2 = AndGate("and2", Offset(0, 100), inputCount: 2);
  }

  void _toggleInput1(int index) {
    setState(() {
      _AndGate1.inputs[index].value = !_AndGate1.inputs[index].value;
      _AndGate1.calculateOutput({});
    });
  }

  void _toggleInput2(int index) {
    setState(() {
      _AndGate2.inputs[index].value = !_AndGate2.inputs[index].value;
      _AndGate2.calculateOutput({});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Interactive Input Toggles
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_AndGate1.inputs.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ElevatedButton(
                        onPressed: () => _toggleInput1(index),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _AndGate1.inputs[index].value
                              ? Colors.green
                              : Colors.grey,
                        ),
                        child: Text("In $index"),
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 50),
                // The Gate Widget
                AndWidget(gate: _AndGate1),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Interactive Input Toggles
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_AndGate2.inputs.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ElevatedButton(
                        onPressed: () => _toggleInput2(index),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _AndGate2.inputs[index].value
                              ? Colors.green
                              : Colors.grey,
                        ),
                        child: Text("In $index"),
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 50),
                // The Gate Widget
                AndWidget(gate: _AndGate2),
              ],
            ),
          ],
        ));
  }
}
