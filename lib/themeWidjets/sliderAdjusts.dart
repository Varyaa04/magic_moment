import 'package:flutter/material.dart';

class SliderRow extends StatelessWidget {
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String label;
  final ValueChanged<double>? onChanged;
  final bool isProcessing;

  const SliderRow({
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.label,
    this.onChanged,
    required this.isProcessing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: label,
            onChanged: isProcessing ? null : onChanged,
            activeColor: Colors.blue,
            inactiveColor: Colors.grey,
          ),
        ),
      ],
    );
  }
}