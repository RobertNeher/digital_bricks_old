import 'package:digital_bricks/src/and_gate.dart';
import 'package:digital_bricks/src/and_widget.dart';
import 'package:digital_bricks/src/oscillator.dart';
import 'package:digital_bricks/src/oscillator_widget.dart';
import 'package:digital_bricks/src/draggable_widget.dart';
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
  late Oscillator _oscillator;

  @override
  void initState() {
    super.initState();
    _AndGate1 = AndGate(id: "and1", position: Offset(0, 0), inputCount: 3);
    _AndGate2 = AndGate(id: "and2", position: Offset(250, 0), inputCount: 2);
    _oscillator = Oscillator(
        id: "oscillator",
        position: Offset(0, 200),
        frequency: 0.5,
        setState: () => setState(() {}));
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
        body: Stack(
          children: [
            Positioned(
              top: _AndGate1.position.dy,
              left: _AndGate1.position.dx,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _AndGate1.position += details.delta;
                  });
                },
                child: AndWidget(gate: _AndGate1),
              ),
            ),
            Positioned(
              top: _AndGate2.position.dy,
              left: _AndGate2.position.dx,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _AndGate2.position += details.delta;
                  });
                },
                child: AndWidget(gate: _AndGate2),
              ),
            ),
            Positioned(
              top: _oscillator.position.dy,
              left: _oscillator.position.dx,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _oscillator.position += details.delta;
                  });
                },
                child: OscillatorWidget(oscillator: _oscillator),
              ),
            ),
            DraggableWidget(
              component: _oscillator,
              onDrag: () => setState(() {}),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // The Gate Widget
                  OscillatorWidget(oscillator: _oscillator),
                ],
              ),
            ),
          ],
        ));
  }
}
