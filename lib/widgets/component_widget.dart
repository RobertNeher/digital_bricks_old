import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/logic_component.dart';
import '../models/gates.dart';
import '../models/io_devices.dart';
import '../models/integrated_circuit.dart';
import '../circuit_provider.dart';
import 'gate_painter.dart';
import 'ic_painter.dart';
import 'pin_widget.dart';
import 'segment_display_painter.dart';
import '../utils/segment_patterns.dart';

class ComponentWidget extends StatelessWidget {
  final LogicComponent component;

  const ComponentWidget({super.key, required this.component});

  @override
  Widget build(BuildContext context) {
    // Determine size based on inputs
    // Base height 60, but if inputs > 3, grow.
    double height = 60.0;
    int maxPins = component.inputs.length > component.outputs.length
        ? component.inputs.length
        : component.outputs.length;
    if (maxPins > 3) {
      height = maxPins * 20.0;
    }
    double width = 60.0;
    if (component is SegmentDisplay) {
      // Use parameterized size but ensure pins fit
      // Default aspect ratio for 16-seg is roughly 0.8 width/height
      double fontH = (component as SegmentDisplay).fontSize;
      double pinH = component.inputs.length * 20.0;
      height = fontH > pinH ? fontH : pinH;
      width = fontH * 0.8;
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
                        // For IntegratedCircuit
                        if (component is IntegratedCircuit)
                          Center(
                            child: Container(
                              width: 50,
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.blueGrey[100],
                                border: Border.all(color: Colors.black),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: CustomPaint(
                                        painter: ICPainter(
                                          (component as IntegratedCircuit)
                                              .internalComponents,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Container(
                                      color: Colors.white.withOpacity(0.7),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      child: Text(
                                        (component as IntegratedCircuit)
                                            .blueprint
                                            .name,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
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

    if (display.segments == 16) {
      // Real 16-segment rendering
      int mask = SegmentPatterns.getMask(val);

      double h = display.fontSize;
      double w = h * 0.8;

      return SizedBox(
        width: w,
        height: h,
        child: CustomPaint(
          painter: SegmentDisplayPainter(
            mask: mask,
            color: Color(display.color),
          ),
        ),
      );
    } else {
      // 7-segment (Hex mode)
      String text = val.toRadixString(16).toUpperCase();
      return Text(
        text,
        style: TextStyle(
          fontSize: display.fontSize,
          fontWeight: FontWeight.bold,
          color: Color(display.color),
        ),
      );
    }
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
            if (component is IntegratedCircuit)
              ListTile(
                leading: const Icon(Icons.open_in_full),
                title: const Text('Unpack Circuit'),
                onTap: () {
                  Provider.of<CircuitProvider>(
                    context,
                    listen: false,
                  ).unpackIntegratedCircuit(component as IntegratedCircuit);
                  Navigator.pop(ctx);
                },
              ),
            // Debug info
            // ListTile(title: Text("Grp: ${component.icGroupId}, BP: ${component.icBlueprintName}")),
            if (component.icGroupId != null &&
                component.icBlueprintName != null)
              ListTile(
                leading: const Icon(Icons.compress),
                title: Text('Repack ${component.icBlueprintName}'),
                onTap: () {
                  Provider.of<CircuitProvider>(
                    context,
                    listen: false,
                  ).repackIntegratedCircuit(
                    component.icGroupId!,
                    component.icBlueprintName!,
                  );
                  Navigator.pop(ctx);
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
