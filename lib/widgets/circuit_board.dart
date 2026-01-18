import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../circuit_provider.dart';
import '../models/logic_component.dart'; // Needed for type
import '../models/connection.dart';
import '../models/io_devices.dart'; // For SegmentDisplay check
import '../models/saved_circuit.dart';
import '../models/integrated_circuit.dart';
import 'component_widget.dart';
import 'wire_painter.dart';
import 'grid_painter.dart';

class CircuitBoard extends StatefulWidget {
  const CircuitBoard({super.key});

  @override
  @override
  State<CircuitBoard> createState() => _CircuitBoardState();
}

// Intents
class DeleteIntent extends Intent {
  const DeleteIntent();
}

class SelectAllIntent extends Intent {
  const SelectAllIntent();
}

class SaveIntent extends Intent {
  const SaveIntent();
}

class OpenIntent extends Intent {
  const OpenIntent();
}

class CancelSelectionIntent extends Intent {
  const CancelSelectionIntent();
}

class MoveIntent extends Intent {
  final Offset delta;
  const MoveIntent(this.delta);
}

class _CircuitBoardState extends State<CircuitBoard> {
  final TransformationController _transformController =
      TransformationController();
  final GlobalKey _canvasKey = GlobalKey(); // Key for the internal Container
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CircuitProvider>(context);

    // Canvas size
    const double canvasWidth = 2000;
    const double canvasHeight = 2000;

    return FocusableActionDetector(
      focusNode: _focusNode,
      autofocus: true,
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.delete): const DeleteIntent(),
        const SingleActivator(LogicalKeyboardKey.backspace):
            const DeleteIntent(),
        const SingleActivator(LogicalKeyboardKey.keyA, control: true):
            const SelectAllIntent(),
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            const SaveIntent(),
        const SingleActivator(LogicalKeyboardKey.keyO, control: true):
            const OpenIntent(),
        const SingleActivator(LogicalKeyboardKey.escape):
            const CancelSelectionIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowUp): const MoveIntent(
          Offset(0, -20),
        ),
        const SingleActivator(LogicalKeyboardKey.arrowDown): const MoveIntent(
          Offset(0, 20),
        ),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): const MoveIntent(
          Offset(-20, 0),
        ),
        const SingleActivator(LogicalKeyboardKey.arrowRight): const MoveIntent(
          Offset(20, 0),
        ),
      },
      actions: <Type, Action<Intent>>{
        DeleteIntent: CallbackAction<DeleteIntent>(
          onInvoke: (intent) => provider.deleteSelectedComponents(),
        ),
        SelectAllIntent: CallbackAction<SelectAllIntent>(
          onInvoke: (intent) => provider.selectAll(),
        ),
        SaveIntent: CallbackAction<SaveIntent>(
          onInvoke: (intent) => provider.saveCurrentCircuit(),
        ),
        OpenIntent: CallbackAction<OpenIntent>(
          onInvoke: (intent) => provider.loadCircuit(),
        ),
        CancelSelectionIntent: CallbackAction<CancelSelectionIntent>(
          onInvoke: (intent) => provider.clearSelection(),
        ),
        MoveIntent: CallbackAction<MoveIntent>(
          onInvoke: (intent) => provider.moveSelectedComponents(intent.delta),
        ),
      },
      child: DragTarget<Object>(
        onAcceptWithDetails: (details) {
          _handleDrop(context, details.data, details.offset);
          _focusNode.requestFocus(); // Regain focus after drop
        },
        builder: (context, candidateData, rejectedData) {
          return Stack(
            children: [
              // Infinite Grid Layer (Background)
              Positioned.fill(
                child: CustomPaint(
                  painter: GridPainter(
                    gridSize: CircuitProvider.gridSize,
                    listenable: _transformController,
                    backgroundColor: Colors.grey[200]!,
                  ),
                ),
              ),

              // Interactive Workspace
              InteractiveViewer(
                transformationController: _transformController,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: 0.1,
                maxScale: 4.0,
                constrained: false,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onSecondaryTapUp: (details) {
                    _handleSecondaryTap(
                      context,
                      details.localPosition,
                      provider,
                    );
                  },
                  onTap: () {
                    provider.clearSelection();
                  },
                  child: Container(
                    key: _canvasKey,
                    width: canvasWidth,
                    height: canvasHeight,
                    color: Colors.transparent,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Wires (Bottom layer)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: WirePainter(
                              connections: provider.connections,
                              components: provider.components,
                            ),
                          ),
                        ),

                        // Components
                        ...provider.components.map((comp) {
                          return Positioned(
                            left: comp.position.dx,
                            top: comp.position.dy,
                            child: ComponentWidget(component: comp),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),

              // Selection Toolbar (Overlay)
              if (provider.selectedComponentIds.isNotEmpty)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.align_horizontal_left),
                            tooltip: "Align Left",
                            onPressed: () =>
                                provider.alignSelectedComponents('left'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.align_vertical_top),
                            tooltip: "Align Top",
                            onPressed: () =>
                                provider.alignSelectedComponents('top'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.save),
                            tooltip: "Save as Blueprint",
                            onPressed: () =>
                                _showSaveBlueprintDialog(context, provider),
                          ),
                          const SizedBox(width: 8),
                          Container(width: 1, height: 24, color: Colors.grey),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: "Delete Selected",
                            onPressed: () =>
                                provider.deleteSelectedComponents(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: "Clear Selection",
                            onPressed: () => provider.clearSelection(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _handleSecondaryTap(
    BuildContext context,
    Offset localPos,
    CircuitProvider provider,
  ) {
    // Check for wire hit
    for (var conn in provider.connections) {
      if (_isWireHit(conn, localPos, provider.components)) {
        _showWireContextMenu(context, conn.id);
        return;
      }
    }
  }

  bool _isWireHit(
    Connection conn,
    Offset tapPos,
    List<LogicComponent> components,
  ) {
    Offset? p1 = _getPinPos(conn.sourcePinId, components);
    Offset? p2 = _getPinPos(conn.targetPinId, components);

    if (p1 == null || p2 == null) return false;

    // Wire uses cubicTo. Checking hit on bezier is expensive.
    // Simplify: check distance to bounds or sample points?
    // Or check distance to the straight line? (Wont match curved wire well).
    // Or checking distance to the Bezier curve iteratively.

    // Let's use a simplified check: check points along the bezier curve
    // Bezier P0=p1, P1=(p1.x+d/2, p1.y), P2=(p2.x-d/2, p2.y), P3=p2
    double distX = (p2.dx - p1.dx).abs();
    Offset c1 = Offset(p1.dx + distX / 2, p1.dy);
    Offset c2 = Offset(p2.dx - distX / 2, p2.dy);

    // Check 20 steps
    for (double t = 0; t <= 1.0; t += 0.05) {
      Offset p = _evalCubicBezier(p1, c1, c2, p2, t);
      if ((p - tapPos).distance < 10.0) return true; // 10px tolerance
    }
    return false;
  }

  Offset _evalCubicBezier(
    Offset p0,
    Offset p1,
    Offset p2,
    Offset p3,
    double t,
  ) {
    double u = 1 - t;
    double tt = t * t;
    double uu = u * u;
    double uuu = uu * u;
    double ttt = tt * t;

    return p0 * uuu + p1 * (3 * uu * t) + p2 * (3 * u * tt) + p3 * ttt;
  }

  void _showWireContextMenu(BuildContext context, String connectionId) {
    // Get position for menu? showModalBottomSheet is easier
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text("Delete Connection"),
              onTap: () {
                Provider.of<CircuitProvider>(
                  context,
                  listen: false,
                ).removeConnection(connectionId);
                Navigator.pop(ctx);
              },
            ),
          ],
        );
      },
    );
  }

  // Reusing logic from WirePainter (should refactor later)
  Offset? _getPinPos(String pinId, List<LogicComponent> components) {
    for (var c in components) {
      for (int i = 0; i < c.inputs.length; i++) {
        if (c.inputs[i].id == pinId) return _calculatePinOffset(c, i, true);
      }
      for (int i = 0; i < c.outputs.length; i++) {
        if (c.outputs[i].id == pinId) return _calculatePinOffset(c, i, false);
      }
    }
    return null;
  }

  Offset _calculatePinOffset(LogicComponent c, int index, bool isInput) {
    double height = 60.0;
    if (c.inputs.length > 3) {
      height = c.inputs.length * 20.0;
    }
    double width = 60.0;
    if (c is SegmentDisplay) {
      // Logic matching ComponentWidget
      double fontH = c.fontSize;
      double pinH = c.inputs.length * 20.0;
      height = fontH > pinH ? fontH : pinH;
      width = fontH * 0.8;
    }

    if (c is IntegratedCircuit) {
      double maxInW = 0;
      double maxOutW = 0;
      const double charWidth = 8.0;

      for (var l in c.blueprint.inputLabels) {
        if (l.length * charWidth > maxInW) maxInW = l.length * charWidth;
      }
      for (var l in c.blueprint.outputLabels) {
        if (l.length * charWidth > maxOutW) maxOutW = l.length * charWidth;
      }
      width = 60.0 + maxInW + maxOutW;
    }
    double totalWidth = width + 20;

    int count = isInput ? c.inputs.length : c.outputs.length;
    double step = height / (count + 1);
    double y = c.position.dy + step * (index + 1);

    double x = c.position.dx;
    if (isInput) {
      x += 6;
    } else {
      x += totalWidth - 6;
    }

    return Offset(x, y);
  }

  void _handleDrop(BuildContext context, dynamic data, Offset dropPos) {
    // dropPos is in global screen coordinates.
    // We need to convert it to the local coordinate system of the Container (Canvas).

    final RenderBox? renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final Offset localPos = renderBox.globalToLocal(dropPos);

      // Snap to grid
      double gs = CircuitProvider.gridSize;
      double snapX = (localPos.dx / gs).round() * gs;
      double snapY = (localPos.dy / gs).round() * gs;

      if (data is ComponentType) {
        Provider.of<CircuitProvider>(
          context,
          listen: false,
        ).addComponentByType(data, Offset(snapX, snapY));
      } else if (data is SavedCircuit) {
        Provider.of<CircuitProvider>(
          context,
          listen: false,
        ).instantiateCustomCircuit(data, Offset(snapX, snapY));
      }
    }
  }

  void _showSaveBlueprintDialog(
    BuildContext context,
    CircuitProvider provider,
  ) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Save Custom Blueprint"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Blueprint Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.saveSelectionAsCustom(controller.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
