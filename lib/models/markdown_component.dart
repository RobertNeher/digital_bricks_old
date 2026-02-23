import 'package:flutter/material.dart';
import 'logic_component.dart';

class MarkdownComponent extends LogicComponent {
  String text;
  bool isEditing = false;

  MarkdownComponent({
    String? id,
    required Offset position,
    this.text = """# Circuit Name

## Description

This circuit is a simple AND gate that takes two inputs and produces one output.

## Inputs

- A
- B

## Outputs

- Q

## Truth Table

| A | B | Q |
|---|---|---|
| 0 | 0 | 0 |""",
  }) : super(
         id: id,
         name: "Text",
         position: position,
         type: ComponentType.markdownText,
       );

  @override
  void evaluate() {
    // Markdown components don't have logic to evaluate
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['text'] = text;
    return json;
  }
}
