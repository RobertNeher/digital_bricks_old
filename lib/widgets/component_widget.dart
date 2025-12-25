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
      onTap: () {
        // Toggle selection
        Provider.of<CircuitProvider>(
          context,
          listen: false,
        ).toggleComponentSelection(component.id);
      },
      onPanUpdate: (details) {
        final provider = Provider.of<CircuitProvider>(context, listen: false);

        // If this component isn't selected, select it exclusively (drag logic usually)
        // Or if it IS selected, move ALL selected.
        if (!provider.isSelected(component.id)) {
          // If dragging something unselected, select just it (classic behavior)
          provider.selectComponent(component.id);
        }

        // Move all selected components
        for (var id in provider.selectedComponentIds) {
          var comp = provider.components.firstWhere((c) => c.id == id);
          comp.position += details.delta;
        }

        provider.refresh();
      },
      onPanEnd: (details) {
        final provider = Provider.of<CircuitProvider>(context, listen: false);
        double gs = CircuitProvider.gridSize;

        // Snap ALL selected components
        for (var id in provider.selectedComponentIds) {
          var comp = provider.components.firstWhere((c) => c.id == id);
          double snapX = (comp.position.dx / gs).round() * gs;
          double snapY = (comp.position.dy / gs).round() * gs;
          comp.position = Offset(snapX, snapY);
        }

        provider.refresh();
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
              child: Consumer<CircuitProvider>(
                builder: (context, provider, child) {
                  bool isSelected = provider.isSelected(component.id);
                  return Container(
                    decoration: BoxDecoration(
                      border: isSelected
                          ? Border.all(color: Colors.blueAccent, width: 2)
                          : null,
                    ),
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
                  );
                },
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
    String text = "";
    if (display.segments == 16) {
      // 7-bit ASCII mode
      if (val >= 32 && val <= 126) {
        text = String.fromCharCode(val);
      } else {
        // Fallback to Hex for non-printable controls sc
        // so user sees *something* happens
        text = "0x${val.toRadixString(16).toUpperCase()}";
      }
    } else {
      // 7-segment (Hex mode)
      text = val.toRadixString(16).toUpperCase();
    }

    // Use configurable fontSize instead of FittedBox, as requested
    return Text(
      text,
      style: TextStyle(
        fontSize: display.fontSize,
        fontWeight: FontWeight.bold,
        color: Color(display.color),
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
            if (component is SegmentDisplay) ...[
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('Set Color'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSegmentColorDialog(context, component as SegmentDisplay);
                },
              ),
              ListTile(
                leading: const Icon(Icons.format_size),
                title: const Text('Set Font Size'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSegmentSizeDialog(context, component as SegmentDisplay);
                },
              ),
            ],
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

  void _showSegmentColorDialog(BuildContext context, SegmentDisplay display) {
    TextEditingController colorCtrl = TextEditingController(
      text: "0x${display.color.toRadixString(16).toUpperCase()}",
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Segment Color (0xAARRGGBB)"),
        content: TextField(
          controller: colorCtrl,
          decoration: const InputDecoration(labelText: "Color (Hex)"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              int? c = int.tryParse(colorCtrl.text);
              if (c != null) {
                display.color = c;
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

  void _showSegmentSizeDialog(BuildContext context, SegmentDisplay display) {
    TextEditingController sizeCtrl = TextEditingController(
      text: display.fontSize.toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Font Size"),
        content: TextField(
          controller: sizeCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Size (pixels)"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              double? s = double.tryParse(sizeCtrl.text);
              if (s != null) {
                display.fontSize = s;
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
