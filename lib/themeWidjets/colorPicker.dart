import 'package:flutter/material.dart';
import 'dart:math' as math;

class ColorPicker extends StatefulWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;
  final double pickerAreaHeightPercent;
  final bool enableAlpha;

  const ColorPicker({
    Key? key,
    required this.pickerColor,
    required this.onColorChanged,
    this.pickerAreaHeightPercent = 0.7,
    this.enableAlpha = false,
  }) : super(key: key);

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late HSVColor _hsvColor;
  late double _alpha;

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(widget.pickerColor);
    _alpha = widget.pickerColor.opacity;
  }

  void _onHueChanged(double hue) {
    setState(() {
      _hsvColor = _hsvColor.withHue(hue);
    });
    _notifyColorChanged();
  }

  void _onSaturationValueChanged(Offset offset, Size size) {
    final saturation = (offset.dx / size.width).clamp(0.0, 1.0);
    final value = 1 - (offset.dy / size.height).clamp(0.0, 1.0);
    setState(() {
      _hsvColor = _hsvColor.withSaturation(saturation).withValue(value);
    });
    _notifyColorChanged();
  }

  void _onAlphaChanged(double value) {
    setState(() {
      _alpha = value;
    });
    _notifyColorChanged();
  }

  void _notifyColorChanged() {
    final color = _hsvColor.toColor().withOpacity(_alpha);
    widget.onColorChanged(color);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final double areaHeight = screenHeight * widget.pickerAreaHeightPercent;
    final double clampedHeight = areaHeight.clamp(150.0, 300.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color area
          SizedBox(
            height: clampedHeight,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onPanDown: (details) => _onSaturationValueChanged(
                      details.localPosition, constraints.biggest),
                  onPanUpdate: (details) => _onSaturationValueChanged(
                      details.localPosition, constraints.biggest),
                  child: CustomPaint(
                    painter: SaturationValuePainter(hue: _hsvColor.hue),
                    child: Stack(
                      children: [
                        Positioned(
                          left: _hsvColor.saturation * constraints.maxWidth - 6,
                          top:
                          (1 - _hsvColor.value) * constraints.maxHeight - 6,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Hue slider
          Container(
            height: 24,
            constraints: const BoxConstraints(maxWidth: 360),
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF0000),
                  Color(0xFFFFFF00),
                  Color(0xFF00FF00),
                  Color(0xFF00FFFF),
                  Color(0xFF0000FF),
                  Color(0xFFFF00FF),
                  Color(0xFFFF0000),
                ],
              ),
            ),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                min: 0,
                max: 360,
                value: _hsvColor.hue,
                onChanged: _onHueChanged,
                activeColor: Colors.transparent,
                inactiveColor: Colors.transparent,
              ),
            ),
          ),

          if (widget.enableAlpha) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Opacity'),
                  Slider(
                    min: 0.0,
                    max: 1.0,
                    divisions: 100,
                    value: _alpha,
                    onChanged: _onAlphaChanged,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
class SaturationValuePainter extends CustomPainter {
  final double hue;

  SaturationValuePainter({required this.hue});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final paintSaturation = Paint()
      ..shader = LinearGradient(
        colors: [
          HSVColor.fromAHSV(1, hue, 0, 1).toColor(),
          HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
        ],
      ).createShader(rect);

    final paintValue = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black,
        ],
      ).createShader(rect);

    canvas.drawRect(rect, paintSaturation);
    canvas.drawRect(rect, paintValue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
