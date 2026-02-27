import 'package:flutter/material.dart';
import '../models/logic_component.dart';
import '../models/io_devices.dart';
import '../models/integrated_circuit.dart';
import '../models/markdown_component.dart';

class ComponentLayoutMetadata {
  final double totalWidth;
  final double totalHeight;
  final double inputColWidth;
  final double bodyWidth;
  final double outputColWidth;

  ComponentLayoutMetadata({
    required this.totalWidth,
    required this.totalHeight,
    required this.inputColWidth,
    required this.bodyWidth,
    required this.outputColWidth,
  });

  Size get size => Size(totalWidth, totalHeight);
}

class ComponentLayout {
  static const double baseHeight = 60.0;
  static const double baseWidth = 60.0;
  static const double heightPerPin = 24.0;
  static const double pinSize = 24.0; // The container size in PinWidget

  static ComponentLayoutMetadata getLayoutMetadata(LogicComponent component) {
    // 1. Calculate Body Dimensions
    double bodyHeight = baseHeight;
    int maxPins = component.inputs.length > component.outputs.length
        ? component.inputs.length
        : component.outputs.length;

    if (maxPins > 2) {
      bodyHeight = maxPins * heightPerPin;
      if (bodyHeight < baseHeight) bodyHeight = baseHeight;
    }

    if (component.type == ComponentType.dFlipFlop ||
        component.type == ComponentType.rsFlipFlop ||
        component.type == ComponentType.jkFlipFlop) {
      bodyHeight += 20.0;
    }

    double bodyWidth = baseWidth;
    if (component is MarkdownComponent) {
      bodyWidth = 250.0;
      final textPainter = TextPainter(
        text: TextSpan(
          text: component.text,
          style: const TextStyle(fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: bodyWidth - 24);
      double multiplier = component.text.contains('|') ? 4.0 : 2.0;
      bodyHeight = (textPainter.height * multiplier) + 80.0;
    } else if (component is SegmentDisplay) {
      double fontH = component.fontSize;
      if (fontH < 30) fontH = 30;
      double pinH = component.inputs.length * heightPerPin;
      bodyHeight = fontH > pinH ? fontH : pinH;
      bodyHeight += 10;
      bodyWidth = fontH * (component.segments == 7 ? 0.6 : 0.8);
    }

    // 2. Calculate Column Widths (Pins + Labels)
    double inputColWidth = pinSize;
    double outputColWidth = pinSize;

    if (component is IntegratedCircuit) {
      double maxInL = 0;
      double maxOutL = 0;
      const double charW = 7.0; // Consistent with ComponentWidget
      for (var l in component.blueprint.inputLabels) {
        if (l.length * charW > maxInL) maxInL = l.length * charW;
      }
      for (var l in component.blueprint.outputLabels) {
        if (l.length * charW > maxOutL) maxOutL = l.length * charW;
      }
      inputColWidth += maxInL + 4;
      outputColWidth += maxOutL + 4;
    } else if (component is SegmentDisplay) {
      inputColWidth += 24.0;
    }

    double totalWidth = inputColWidth + bodyWidth + outputColWidth;

    return ComponentLayoutMetadata(
      totalWidth: totalWidth,
      totalHeight: bodyHeight,
      inputColWidth: inputColWidth,
      bodyWidth: bodyWidth,
      outputColWidth: outputColWidth,
    );
  }

  static Size getComponentSize(LogicComponent component) {
    return getLayoutMetadata(component).size;
  }

  static Offset getPinPosition(
    LogicComponent component,
    int pinIndex,
    bool isInput,
  ) {
    final meta = getLayoutMetadata(component);

    // X position: Center of PinWidget (24x24)
    // For Inputs: Far left of inputColumn, Pin is first.
    // For Outputs: Far right of outputColumn, Pin is last.
    double centerX = isInput
        ? (pinSize / 2)
        : (meta.totalWidth - (pinSize / 2));

    // Y position: spaceEvenly Column
    int count = isInput ? component.inputs.length : component.outputs.length;
    double space = (meta.totalHeight - (count * pinSize)) / (count + 1);
    if (space < 0) space = 0;

    double centerY =
        space * (pinIndex + 1) + pinSize * pinIndex + (pinSize / 2);

    return component.position + Offset(centerX, centerY);
  }
}
