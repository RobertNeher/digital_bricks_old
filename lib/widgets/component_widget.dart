import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/logic_component.dart';
import '../models/gates.dart';
import '../models/io_devices.dart';
import '../models/circuit_io.dart';
import '../models/integrated_circuit.dart';
import '../circuit_provider.dart';
import 'gate_painter.dart';
import 'ic_painter.dart';
import 'color_picker_dialog.dart';
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
    // Fix for overflow: Increase height per pin and ensure enough space
    if (maxPins > 2) {
      height = maxPins * 24.0;
      if (height < 60) height = 60;
    }
    double width = 60.0;
    if (component is SegmentDisplay) {
      // Use parameterized size but ensure pins fit
      // Default aspect ratio for 16-seg is roughly 0.8 width/height
      // For 7-seg it's closer to 0.6.
      double fontH = (component as SegmentDisplay).fontSize;
      if (fontH < 30) fontH = 30; // Enforce minimum size

      double pinH = component.inputs.length * 24.0;
      height = fontH > pinH ? fontH : pinH;
      height += 10; // Extra padding

      bool is7Seg = (component as SegmentDisplay).segments == 7;
      double ratio = is7Seg ? 0.6 : 0.8;

      double bodyW = fontH * ratio;
      // Input Column: Dynamic
      double maxLabelW = 0;
      String maxLabel = (component.inputs.length - 1).toString();
      maxLabelW = maxLabel.length * 10.0;
      if (maxLabelW < 10.0) maxLabelW = 10.0;

      double inputW = 24.0 + 8.0 + maxLabelW;
      // Gap between inputs and body
      double gapW = 20.0;

      width = inputW + gapW + bodyW;
    }

    if (component is IntegratedCircuit) {
      var ic = component as IntegratedCircuit;
      double maxInW = 0;
      double maxOutW = 0;
      const double charWidth = 8.0;

      for (var l in ic.blueprint.inputLabels) {
        if (l.length * charWidth > maxInW) maxInW = l.length * charWidth;
      }
      for (var l in ic.blueprint.outputLabels) {
        if (l.length * charWidth > maxOutW) maxOutW = l.length * charWidth;
      }

      // Standard body width = 60.
      // Container width will be set to 'width + 20' later.
      // We want 'width + 20' to equal 'maxInW + 60 + maxOutW + 20 (for pins)'.
      // So 'width' should be 'maxInW + 60 + maxOutW'.
      width = 60.0 + maxInW + maxOutW;
    }

    Color? containerColor;
    if (component is SegmentDisplay) {
      containerColor = Color((component as SegmentDisplay).bodyColor);
    }

    return Container(
      width: width + 20, // space for pins and gap
      height: height,
      // Color removed here, applied via Stack if needed
      child: Stack(
        children: [
          if (containerColor != null)
            Positioned(
              left: 24.0, // Start after pins
              top: 0,
              bottom: 0,
              right: 0,
              child: Container(color: containerColor),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Inputs
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align to left edge
                children: component.inputs.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var p = entry.value;
                  Widget pinWidget = PinWidget(pin: p);

                  if (component is IntegratedCircuit) {
                    var ic = component as IntegratedCircuit;
                    String label = "";
                    if (idx < ic.blueprint.inputLabels.length) {
                      label = ic.blueprint.inputLabels[idx];
                    }
                    if (label.isNotEmpty) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          pinWidget,
                          const SizedBox(width: 4),
                          Text(label, style: const TextStyle(fontSize: 10)),
                        ],
                      );
                    }
                  } else if (component is SegmentDisplay) {
                    // Segment Display Input Labels (7-seg or 16-seg)
                    // 7-seg: 4 inputs (0..3)
                    // 16-seg: 7 inputs (0..6)
                    // Reverse order labels: Bottom is 0.

                    String label = (component.inputs.length - 1 - idx)
                        .toString();

                    Color textColor = Colors.black;
                    // If bodyColor is dark, use white text.
                    if (Color(
                          (component as SegmentDisplay).bodyColor,
                        ).computeLuminance() <
                        0.5) {
                      textColor = Colors.white;
                    }

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        pinWidget,
                        const SizedBox(
                          width: 8,
                        ), // Increased gap for better separation
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12, // Increased font size for readability
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    );
                  }
                  return pinWidget;
                }).toList(),
              ),
              if (component is SegmentDisplay) const SizedBox(width: 20),
              // Body
              Expanded(
                child: Consumer<CircuitProvider>(
                  builder: (context, provider, child) {
                    bool isSelected = provider.isSelected(component.id);
                    return GestureDetector(
                      onTap: () {
                        // Toggle selection
                        Provider.of<CircuitProvider>(
                          context,
                          listen: false,
                        ).toggleComponentSelection(component.id);
                      },
                      onPanUpdate: (details) {
                        final provider = Provider.of<CircuitProvider>(
                          context,
                          listen: false,
                        );

                        // If this component isn't selected, select it exclusively (drag logic usually)
                        // Or if it IS selected, move ALL selected.
                        if (!provider.isSelected(component.id)) {
                          // If dragging something unselected, select just it (classic behavior)
                          provider.selectComponent(component.id);
                        }

                        // Move all selected components
                        for (var id in provider.selectedComponentIds) {
                          var comp = provider.components.firstWhere(
                            (c) => c.id == id,
                          );
                          comp.position += details.delta;
                        }

                        provider.refresh();
                      },
                      onPanEnd: (details) {
                        final provider = Provider.of<CircuitProvider>(
                          context,
                          listen: false,
                        );
                        double gs = CircuitProvider.gridSize;

                        // Snap ALL selected components
                        for (var id in provider.selectedComponentIds) {
                          var comp = provider.components.firstWhere(
                            (c) => c.id == id,
                          );
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
                                (component is CircuitInput)
                                    ? (component as CircuitInput).label
                                    : (component is CircuitOutput)
                                    ? (component as CircuitOutput).label
                                    : component.name,
                                style: TextStyle(
                                  fontSize:
                                      (component is CircuitInput ||
                                          component is CircuitOutput)
                                      ? 12
                                      : 10,
                                  fontWeight:
                                      (component is CircuitInput ||
                                          component is CircuitOutput)
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            // For ConstantSource
                            if (component is ConstantSource)
                              Center(
                                child: Text(
                                  (component as ConstantSource).state
                                      ? "1"
                                      : "0",
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
                                          color: Colors.white.withAlpha(70),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 2,
                                          ),
                                          child: Text(
                                            (component as IntegratedCircuit)
                                                .blueprint
                                                .name,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            // For ButtonComponent
                            if (component is ButtonComponent)
                              Center(
                                child: GestureDetector(
                                  onTap: () {
                                    (component as ButtonComponent).toggle();
                                    Provider.of<CircuitProvider>(
                                      context,
                                      listen: false,
                                    ).refresh();
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color:
                                          (component as ButtonComponent)
                                              .isPressed
                                          ? Colors.green
                                          : Colors.grey[300],
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 2,
                                          offset:
                                              (component as ButtonComponent)
                                                  .isPressed
                                              ? const Offset(0, 0)
                                              : const Offset(2, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.touch_app,
                                      size: 24,
                                      color:
                                          (component as ButtonComponent)
                                              .isPressed
                                          ? Colors.white
                                          : Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Outputs
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment:
                    CrossAxisAlignment.end, // Align to right edge
                children: component.outputs.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var p = entry.value;
                  Widget pinWidget = PinWidget(pin: p);

                  if (component is IntegratedCircuit) {
                    var ic = component as IntegratedCircuit;
                    String label = "";
                    if (idx < ic.blueprint.outputLabels.length) {
                      label = ic.blueprint.outputLabels[idx];
                    }
                    if (label.isNotEmpty) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(label, style: const TextStyle(fontSize: 10)),
                          const SizedBox(width: 4),
                          pinWidget,
                        ],
                      );
                    }
                  }
                  return pinWidget;
                }).toList(),
              ),
            ],
          ),
        ],
      ), // Close Stack
    ); // Close Container
  }

  Widget _buildSegmentDisplayContent(SegmentDisplay display) {
    int val = display.inputValue;
    int mask;
    bool is7Seg = display.segments == 7;

    if (is7Seg) {
      mask = Segment7Patterns.getHexMask(val);
    } else {
      mask = SegmentPatterns.getMask(val);
    }

    double h = display.fontSize;
    // Adjust aspect ratio based on type
    double w = h * (is7Seg ? 0.6 : 0.8);

    return SizedBox(
      width: w,
      height: h,
      child: CustomPaint(
        painter: SegmentDisplayPainter(
          mask: mask,
          color: Color(display.color),
          backgroundColor: Color(display.backgroundColor),
          bodyColor: Color(display.bodyColor),
          is7Segment: is7Seg,
        ),
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
                title: const Text('Set Active Segment Color'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSegmentColorDialog(context, component as SegmentDisplay);
                },
              ),
              ListTile(
                leading: const Icon(Icons.format_paint),
                title: const Text('Set Inactive Segment Color'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSegmentBackgroundColorDialog(
                    context,
                    component as SegmentDisplay,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_box_outline_blank),
                title: const Text('Set Body Color'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSegmentBodyColorDialog(
                    context,
                    component as SegmentDisplay,
                  );
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
            if (component is CircuitInput || component is CircuitOutput)
              ListTile(
                leading: const Icon(Icons.label),
                title: const Text('Edit Label'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showLabelDialog(context, component);
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
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("LED Colors"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text("High Output Color"),
                  trailing: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Color(led.colorHigh),
                      border: Border.all(color: Colors.grey),
                      shape: BoxShape.circle,
                    ),
                  ),
                  onTap: () {
                    showColorPicker(context, Color(led.colorHigh), (c) {
                      setState(() {
                        led.colorHigh = c.value;
                      });
                      Provider.of<CircuitProvider>(
                        context,
                        listen: false,
                      ).refresh();
                    });
                  },
                ),
                ListTile(
                  title: const Text("Low Output Color"),
                  trailing: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Color(led.colorLow),
                      border: Border.all(color: Colors.grey),
                      shape: BoxShape.circle,
                    ),
                  ),
                  onTap: () {
                    showColorPicker(context, Color(led.colorLow), (c) {
                      setState(() {
                        led.colorLow = c.value;
                      });
                      Provider.of<CircuitProvider>(
                        context,
                        listen: false,
                      ).refresh();
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Done"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSegmentColorDialog(BuildContext context, SegmentDisplay display) {
    showColorPicker(context, Color(display.color), (c) {
      display.color = c.value;
      Provider.of<CircuitProvider>(context, listen: false).refresh();
    });
  }

  void _showSegmentBackgroundColorDialog(
    BuildContext context,
    SegmentDisplay display,
  ) {
    showColorPicker(context, Color(display.backgroundColor), (c) {
      display.backgroundColor = c.value;
      Provider.of<CircuitProvider>(context, listen: false).refresh();
    });
  }

  void _showSegmentBodyColorDialog(
    BuildContext context,
    SegmentDisplay display,
  ) {
    showColorPicker(context, Color(display.bodyColor), (c) {
      display.bodyColor = c.value;
      Provider.of<CircuitProvider>(context, listen: false).refresh();
    });
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
                if (s < 30) s = 30; // Enforce minimum
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

  void _showLabelDialog(BuildContext context, LogicComponent comp) {
    String currentLabel = "";
    if (comp is CircuitInput) currentLabel = comp.label;
    if (comp is CircuitOutput) currentLabel = comp.label;

    TextEditingController controller = TextEditingController(
      text: currentLabel,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Label"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Label"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              String newLabel = controller.text;
              if (comp is CircuitInput) comp.label = newLabel;
              if (comp is CircuitOutput) comp.label = newLabel;
              Provider.of<CircuitProvider>(context, listen: false).refresh();
              Navigator.pop(ctx);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
