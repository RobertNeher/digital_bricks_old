import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../circuit_provider.dart';
import '../widgets/selection_bar.dart';
import '../widgets/circuit_board.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch provider to show stats or just for access?
    // Actions need access.

    return Scaffold(
      appBar: AppBar(
        title: const Text("Digital Bricks"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              final provider = Provider.of<CircuitProvider>(
                context,
                listen: false,
              );
              if (provider.currentFilePath != null) {
                // Show confirmation
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Confirm Overwrite"),
                    content: Text(
                      "Overwrite current file?\n${provider.currentFilePath}",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx); // Cancel
                          // Maybe open Save As?
                          provider.saveCircuitAs();
                        },
                        child: const Text("Save As..."),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          provider.saveCurrentCircuit();
                        },
                        child: const Text("Overwrite"),
                      ),
                    ],
                  ),
                );
              } else {
                provider.saveCircuitAs();
              }
            },
            tooltip: "Save Circuit",
          ),
          IconButton(
            icon: const Icon(Icons.save_as),
            onPressed: () => Provider.of<CircuitProvider>(
              context,
              listen: false,
            ).saveCircuitAs(),
            tooltip: "Save As",
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () => Provider.of<CircuitProvider>(
              context,
              listen: false,
            ).loadCircuit(),
            tooltip: "Load Circuit",
          ),
          // Maybe a "Clear" button?
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // TODO: clear
              // For now just manually select all?
              // Provider doesn't have clear.
            },
          ),
        ],
      ),
      body: Row(
        children: const [
          SelectionBar(),
          Expanded(child: CircuitBoard()),
        ],
      ),
    );
  }
}
