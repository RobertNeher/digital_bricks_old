import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final double? minDistance;

  const SettingsPage({super.key, this.minDistance});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _showGrid = false;
  late double _minDistance;

  @override
  void initState() {
    super.initState();
    _minDistance = widget.minDistance ?? 50.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, _minDistance);
          },
        ),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Show Grid'),
            subtitle: const Text('Enable grid'),
            value: _showGrid,
            onChanged: (bool value) {
              setState(() {
                _showGrid = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Grid setting changed')),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Minimum Distance'),
            subtitle: Text('${_minDistance.round()} px'),
          ),
          Slider(
            value: _minDistance,
            min: 0,
            max: 200,
            divisions: 20,
            label: _minDistance.round().toString(),
            onChanged: (double value) {
              setState(() {
                _minDistance = value;
              });
            },
          ),
        ],
      ),
    );
  }
}
