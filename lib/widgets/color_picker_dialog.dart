import 'package:flutter/material.dart';

class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late HSVColor _currentHsv;

  @override
  void initState() {
    super.initState();
    _currentHsv = HSVColor.fromColor(widget.initialColor);
  }

  void _updateColor(HSVColor hsv) {
    setState(() {
      _currentHsv = hsv;
    });
    widget.onColorChanged(_currentHsv.toColor());
  }

  @override
  Widget build(BuildContext context) {
    Color currentColor = _currentHsv.toColor();

    return AlertDialog(
      title: const Text('Pick a Color'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview
            Container(
              height: 50,
              width: double.infinity,
              decoration: BoxDecoration(
                color: currentColor,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 20),
            // Hue Slider
            Row(
              children: [
                const Text('H'),
                Expanded(
                  child: Slider(
                    value: _currentHsv.hue,
                    min: 0.0,
                    max: 360.0,
                    onChanged: (val) => _updateColor(_currentHsv.withHue(val)),
                  ),
                ),
              ],
            ),
            // Saturation Slider
            Row(
              children: [
                const Text('S'),
                Expanded(
                  child: Slider(
                    value: _currentHsv.saturation,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (val) =>
                        _updateColor(_currentHsv.withSaturation(val)),
                  ),
                ),
              ],
            ),
            // Value Slider
            Row(
              children: [
                const Text('V'),
                Expanded(
                  child: Slider(
                    value: _currentHsv.value,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (val) =>
                        _updateColor(_currentHsv.withValue(val)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '#${currentColor.value.toRadixString(16).toUpperCase().substring(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

// Helper to confirm selection
Future<void> showColorPicker(
  BuildContext context,
  Color initialColor,
  ValueChanged<Color> onConfirm,
) async {
  Color picked = initialColor;
  await showDialog(
    context: context,
    builder: (ctx) => ColorPickerDialog(
      initialColor: initialColor,
      onColorChanged: (c) => picked = c,
    ),
  );
  onConfirm(picked);
}
