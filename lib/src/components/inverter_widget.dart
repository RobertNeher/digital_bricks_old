import 'package:digital_bricks/src/components/inverter.dart';
import 'package:flutter/material.dart';

class InverterWidget extends StatelessWidget {
  final Inverter gate;
  final Function(int)? onInputTap;
  final Function(int)? onOutputTap;

  const InverterWidget({
    super.key,
    required this.gate,
    this.onInputTap,
    this.onOutputTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.blue[100],
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Gate Body (Symbolic)
          const Positioned(
            left: 40,
            top: 3,
            child: Center(
              child: Text(
                "1",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
              ),
            ),
          ),
          // Inputs (Left side)
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(gate.inputs.length, (index) {
              return GestureDetector(
                onTap: () => onInputTap?.call(index),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color:
                            gate.inputs.first.value ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text("In", style: TextStyle(fontSize: 10)),
                  ],
                ),
              );
            }),
          ),
          // Output (Right side)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => onOutputTap?.call(0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Out", style: TextStyle(fontSize: 10)),
                    const SizedBox(width: 4),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: gate.outputs.first.value
                            ? Colors.green
                            : Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
