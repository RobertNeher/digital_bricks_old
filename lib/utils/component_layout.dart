import 'package:flutter/material.dart';
import '../models/logic_component.dart';
import '../models/io_devices.dart';
import '../models/integrated_circuit.dart';

class ComponentLayout {
  // Constants tailored to match ComponentWidget rendering exactly
  static const double baseHeight = 60.0;
  static const double baseWidth = 60.0;
  // ComponentWidget uses 24.0 for height per pin when > 2 pins
  static const double heightPerPin = 24.0;
  static const double pinSize =
      12.0; // The inner circle size of PinWidget? No, visual size.
  // PinWidget container is 24x24, but the visual pin is 12x12 inside it.
  // We need to know the CENTER of the pin.
  // In ComponentWidget, PinWidget is in a Column with MainAxisAlignment.spaceEvenly.
  // The Column height is determined by getComponentSize.height.
  // The PinWidget takes up 24x24 space (DragTarget container).

  static Size getComponentSize(LogicComponent component) {
    double height = baseHeight;
    int maxPins = component.inputs.length > component.outputs.length
        ? component.inputs.length
        : component.outputs.length;

    // Logic from ComponentWidget:
    // if (maxPins > 2) { height = maxPins * 24.0; if (height < 60) height = 60; }
    if (maxPins > 2) {
      height = maxPins * heightPerPin;
      if (height < baseHeight) height = baseHeight;
    }

    double width = baseWidth;
    if (component is SegmentDisplay) {
      double fontH = component.fontSize;
      double pinH =
          component.inputs.length *
          20.0; // Wait, SegDisplay uses 20.0 in ComponentWidget logic??
      // Let's re-read ComponentWidget carefully.
      // Line 39: double pinH = component.inputs.length * 20.0;
      height = fontH > pinH ? fontH : pinH;
      width = fontH * 0.8;
    }

    if (component is IntegratedCircuit) {
      double maxInW = 0;
      double maxOutW = 0;
      const double charWidth = 8.0;

      for (var l in component.blueprint.inputLabels) {
        if (l.length * charWidth > maxInW) maxInW = l.length * charWidth;
      }
      for (var l in component.blueprint.outputLabels) {
        if (l.length * charWidth > maxOutW) maxOutW = l.length * charWidth;
      }
      width = 60.0 + maxInW + maxOutW;
    }

    return Size(width, height);
  }

  static Offset getPinPosition(
    LogicComponent component,
    int pinIndex,
    bool isInput,
  ) {
    Size size = getComponentSize(component);

    // Horizontal Position
    // ComponentWidget Structure:
    // Row [ Inputs (Column), Body (Expanded), Outputs (Column) ]
    // Container width = width + 20.
    // Inputs Column is at x=0 relative to Container.
    // Body starts after Inputs Column.
    // PinWidget is 24 width.
    // But wait, PinWidget is wrapped in a Row if there are labels (IntegratedCircuit).
    // Let's look at ComponentWidget layout again.

    // The main Container has width: width + 20.
    // Inside is a Row.
    // Child 1: Inputs Column. wrapped in mainAxisSize: min.
    // Child 2: Body (Expanded).
    // Child 3: Outputs Column. wrapped in mainAxisSize: min.

    // PinWidget itself has width 24. Structure: Center(Container(12,12)).
    // So the center of the pin is at local x=12, y=12 relative to PinWidget.

    // Logic for X:
    // If Input: It is in the first Column.
    // If it's an IC with labels, it's Row(PinWidget, SizedBox(4), Text).
    // The PinWidget is on the left.
    // So Pin Center X relative to component position = 12.0.
    // Wait, ComponentWidget renders PinWidget directly if no label.
    // If label (IC), it renders Row([PinWidget, Gap, Text]).
    // So PinWidget is still on the far left.
    // So for Inputs, Center X is roughly 12.0.

    // If Output: It is in the last Column.
    // If IC with label: Row([Text, Gap, PinWidget]).
    // The PinWidget is on the right.
    // The outer Container width is `size.width + 20`.
    // The right column is aligned to right edge? No, it's just the last child of a Row.
    // But Body is Expanded. So Input Column is at Left, Output Column is at Right.
    // So Output Column ends at `size.width + 20`.
    // PinWidget is 24 wide. Center is -12 from right edge.
    // So X = (size.width + 20) - 12.

    double centerX = isInput ? 12.0 : (size.width + 20.0 - 12.0);

    // Vertical Position
    // Column uses MainAxisAlignment.spaceEvenly.
    // Available height = size.height.
    // Items in Column.
    // Each item height is...
    // PinWidget height is 24.
    // If IC with label, Row height is defined by PinWidget (24) vs Text(fontSize 10). So 24 is max.
    // So we can assume item height is 24.

    // SpaceEvenly Logic:
    // space = (totalHeight - (count * itemHeight)) / (count + 1)
    // y[i] = space * (i + 1) + itemHeight * i + itemHeight / 2

    int count = isInput ? component.inputs.length : component.outputs.length;
    double itemHeight = 24.0;

    double space = (size.height - (count * itemHeight)) / (count + 1);
    // If overflow happened (negative space), Flutter flex behavior clamps to start/center?
    // ComponentWidget grew the height to ensure it fits, so space >= 0 usually.
    if (space < 0) space = 0;

    double centerY =
        space * (pinIndex + 1) + itemHeight * pinIndex + (itemHeight / 2);

    return component.position + Offset(centerX, centerY);
  }
}
