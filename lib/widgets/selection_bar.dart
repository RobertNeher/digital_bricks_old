import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/logic_component.dart';
import '../models/saved_circuit.dart';
import '../circuit_provider.dart';

class SelectionBar extends StatelessWidget {
  const SelectionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140, // Increased width for categories
      color: Colors.grey[200],
      child: ListView(
        children: [
          _buildCategory("Basic Circuits", [
            ComponentType.and,
            ComponentType.nand,
            ComponentType.or,
            ComponentType.nor,
            ComponentType.xor,
            ComponentType.nxor,
            ComponentType.inverter,
            ComponentType.constantSource,
          ]),
          _buildCategory("Flip-flops", [ComponentType.dFlipFlop]),
          _buildCategory("Input/Output", [
            ComponentType.oscillator,
            ComponentType.led,
            ComponentType.segment7,
            ComponentType.segment16,
          ]),
          Consumer<CircuitProvider>(
            builder: (context, provider, child) {
              return ExpansionTile(
                title: const Text(
                  "Custom",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                initiallyExpanded: true,
                tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                childrenPadding: EdgeInsets.zero,
                children: provider.customCircuits.map((blueprint) {
                  return Draggable<SavedCircuit>(
                    data: blueprint,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue),
                          color: Colors.white.withOpacity(0.8),
                        ),
                        child: Text(blueprint.name.toUpperCase()),
                      ),
                    ),
                    child: ListTile(
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.only(left: 16),
                      title: Text(
                        blueprint.name,
                        style: const TextStyle(fontSize: 11),
                      ),
                      leading: const Icon(Icons.snippet_folder, size: 16),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          // Spacer for bottom
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildCategory(String title, List<ComponentType> types) {
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      initiallyExpanded: true,
      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
      childrenPadding: EdgeInsets.zero,
      children: types.map((type) => _buildDraggable(type)).toList(),
    );
  }

  Widget _buildDraggable(ComponentType type) {
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
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.only(left: 16),
        title: Text(
          type.name.toUpperCase(),
          style: const TextStyle(fontSize: 11),
        ),
        leading: const Icon(Icons.drag_indicator, size: 16),
      ),
    );
  }
}
