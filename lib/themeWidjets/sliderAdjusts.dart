import 'package:flutter/material.dart';

// Компонент строки со слайдером для настройки параметров изображения
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
    final isDesktop = MediaQuery.of(context).size.width > 600;
    // Адаптивные размеры для слайдера
    final trackHeight = isDesktop ? 6.0 : 5.0;
    final thumbRadius = isDesktop ? 10.0 : 8.0;
    final overlayRadius = isDesktop ? 20.0 : 16.0;

    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: isDesktop ? 24.0 : 20.0,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: trackHeight,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: thumbRadius),
              overlayShape: RoundSliderOverlayShape(overlayRadius: overlayRadius),
              valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
              activeTrackColor: activeColor,
              inactiveTrackColor: inactiveColor.withOpacity(0.5),
              thumbColor: activeColor,
              overlayColor: activeColor.withOpacity(0.3),
              valueIndicatorColor: activeColor.withOpacity(0.8),
              valueIndicatorTextStyle: TextStyle(
                color: Colors.white,
                fontSize: isDesktop ? 14.0 : 12.0,
              ),
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