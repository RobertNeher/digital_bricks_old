import 'package:flutter/material.dart';
import '../models/logic_component.dart';

class SelectionBar extends StatelessWidget {
  const SelectionBar({super.key});

  final List<ComponentType> availableTypes = const [
    ComponentType.and,
    ComponentType.nand,
    ComponentType.or,
    ComponentType.nor,
    ComponentType.xor,
    ComponentType.nxor,
    ComponentType.inverter,
    ComponentType.oscillator,
    ComponentType.led,
    ComponentType.segment7,
    ComponentType.segment16,
    ComponentType.constantSource,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      color: Colors.grey[200],
      child: ListView.builder(
        itemCount: availableTypes.length,
        itemBuilder: (context, index) {
          final type = availableTypes[index];
          return Draggable<ComponentType>(
            data: type,
            feedback: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                  color: Colors.white.withOpacity(0.8),
                ),
                child: Text(type.name.toUpperCase()),
              ),
            ),
            child: ListTile(
              title: Text(
                type.name.toUpperCase(),
                style: const TextStyle(fontSize: 12),
              ),
              leading: const Icon(Icons.check_box_outline_blank, size: 20),
            ),
          );
        },
      ),
    );
  }
}
