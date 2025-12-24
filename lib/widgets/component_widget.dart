import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/logic_component.dart';
import '../models/gates.dart';
import '../models/io_devices.dart';
import '../circuit_provider.dart';
import 'gate_painter.dart';
import 'pin_widget.dart';

class ComponentWidget extends StatelessWidget {
  final LogicComponent component;

  const ComponentWidget({super.key, required this.component});

  @override
  Widget build(BuildContext context) {
    // Determine size based on inputs
    // Base height 60, but if inputs > 3, grow.
    double height = 60.0;
    if (component.inputs.length > 3) {
      height = component.inputs.length * 20.0;
    }
    double width = 60.0;
    if (component is SegmentDisplay) {
      // Needs to be bigger
      width = 80.0;
      height = 100.0;
    }

    return GestureDetector(
      onPanUpdate: (details) {
        // Update position in model
        // Note: details.delta is screen delta. InteractiveViewer scale might affect this?
        // Usually InteractiveViewer handles the scale if this is a child.
        // BUT, if we just update the model position, the parent Stack needs to rebuild.
        // We need to account for scale if we want precise tracking, but for simple dragging,
        // 1:1 delta usually feels "okay" if scale is 1. If zoomed out, it might feel slow.
        // We can access transformation controller if needed, but let's stick to simple delta.
        component.position += details.delta;
        // Force rebuild of parent (CircuitBoard) or use ValueNotifier/Provider
        // Since component.position is not "observable" easily, we call notifyListeners on Provider.
        // Doing this on every frame is heavy.
        // Better: Use a local ValueNotifier for drag, commit on end.
        // For now: Call provider.nofity which is expensive but correct.
        Provider.of<CircuitProvider>(context, listen: false).refresh();
      },
      onSecondaryTap: () {
        _showContextMenu(context);
      },
      child: Container(
        width: width + 20, // space for pins
        height: height,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Inputs
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: component.inputs.map((p) => PinWidget(pin: p)).toList(),
            ),
            // Body
            Expanded(
              child: Stack(
                children: [
                  CustomPaint(
                    painter: GatePainter(type: component.type),
                    child: Container(),
                  ),
                  // For Segment Display, draw the content
                  if (component is SegmentDisplay)
                    Center(
                      child: _buildSegmentDisplayContent(
                        component as SegmentDisplay,
                      ),
                    ),
                  // For LED, draw content
                  if (component is Led)
                    Center(
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: (component as Led).currentColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black),
                        ),
                      ),
                    ),
                  // For label
                  Center(
                    child: Text(
                      component.name,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  // For ConstantSource
                  if (component is ConstantSource)
                    Center(
                      child: Text(
                        (component as ConstantSource).state ? "1" : "0",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Outputs
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: component.outputs
                  .map((p) => PinWidget(pin: p))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentDisplayContent(SegmentDisplay display) {
    int val = display.inputValue;
    String text = val.toRadixString(16).toUpperCase();
    if (display.segments == 16) {
      // Check if ascii? For now just hex raw
      if (val < 127) text = String.fromCharCode(val);
    }
    return Text(
      text,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.green,
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                Provider.of<CircuitProvider>(
                  context,
                  listen: false,
                ).removeComponent(component.id);
                Navigator.pop(ctx);
              },
            ),
            if (component is MultiInputGate)
              ListTile(
                leading: const Icon(Icons.settings_input_component),
                title: const Text('Change Inputs'),
                trailing: DropdownButton<int>(
                  value: (component as MultiInputGate).inputCount,
                  items: [2, 3, 4, 8]
                      .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      (component as MultiInputGate).updateInputCount(val);
                      Provider.of<CircuitProvider>(
                        context,
                        listen: false,
                      ).refresh();
                      Navigator.pop(ctx);
                    }
                  },
                ),
              ),
            if (component is Oscillator)
              ListTile(
                leading: const Icon(Icons.speed),
                title: const Text('Frequency'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showFreqDialog(context, component as Oscillator);
                },
              ),
            if (component is ConstantSource)
              StatefulBuilder(
                builder: (context, setState) {
                  return ListTile(
                    leading: const Icon(Icons.power_settings_new),
                    title: const Text('Toggle High/Low'),
                    trailing: Switch(
                      value: (component as ConstantSource).state,
                      onChanged: (val) {
                        (component as ConstantSource).setState(val);
                        Provider.of<CircuitProvider>(
                          context,
                          listen: false,
                        ).refresh();
                        setState(() {});
                      },
                    ),
                  );
                },
              ),
            if (component is Led)
              ListTile(
                leading: const Icon(Icons.color_lens),
                title: const Text('Set Colors'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showColorDialog(context, component as Led);
                },
              ),
          ],
        );
      },
    );
  }

  void _showFreqDialog(BuildContext context, Oscillator osc) {
    TextEditingController controller = TextEditingController(
      text: osc.frequency.toString(),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Set Frequency (Hz)"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () {
              double? v = double.tryParse(controller.text);
              if (v != null) {
                osc.frequency = v;
                Provider.of<CircuitProvider>(context, listen: false).refresh();
              }
              Navigator.pop(ctx);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showColorDialog(BuildContext context, Led led) {
    // Hex string input for simplicity.
    // Format: 0xAARRGGBB
    TextEditingController highCtrl = TextEditingController(
      text: "0x${led.colorHigh.toRadixString(16).toUpperCase()}",
    );
    TextEditingController lowCtrl = TextEditingController(
      text: "0x${led.colorLow.toRadixString(16).toUpperCase()}",
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("LED Colors (0xAARRGGBB)"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: highCtrl,
              decoration: const InputDecoration(labelText: "High Color (Hex)"),
            ),
            TextField(
              controller: lowCtrl,
              decoration: const InputDecoration(labelText: "Low Color (Hex)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              int? h = int.tryParse(highCtrl.text);
              int? l = int.tryParse(lowCtrl.text);
              if (h != null && l != null) {
                led.colorHigh = h;
                led.colorLow = l;
                Provider.of<CircuitProvider>(context, listen: false).refresh();
              }
              Navigator.pop(ctx);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
