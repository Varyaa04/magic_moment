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
  final Color activeColor;
  final Color inactiveColor;

  const SliderRow({
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.label,
    this.onChanged,
    required this.isProcessing,
    required this.activeColor,
    required this.inactiveColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
              activeTrackColor: activeColor,
              inactiveTrackColor: inactiveColor,
              thumbColor: activeColor,
              overlayColor: activeColor.withOpacity(0.3),
              valueIndicatorColor: activeColor,
              valueIndicatorTextStyle: const TextStyle(color: Colors.white),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: label,
              onChanged: isProcessing ? null : onChanged,
            ),
          ),
        ),
      ],
    );
  }
}