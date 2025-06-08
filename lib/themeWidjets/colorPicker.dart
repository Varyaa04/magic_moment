import 'package:flutter/material.dart';

// Компонент выбора цвета с компактным интерфейсом
class ColorPicker extends StatefulWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;
  final bool enableAlpha;

  const ColorPicker({
    Key? key,
    required this.pickerColor,
    required this.onColorChanged,
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

  // Обработка изменения оттенка
  void _onHueChanged(double hue) {
    setState(() {
      _hsvColor = _hsvColor.withHue(hue);
    });
    _notifyColorChanged();
  }

  // Обработка изменения насыщенности и яркости
  void _onSaturationValueChanged(Offset offset, Size size) {
    final saturation = (offset.dx / size.width).clamp(0.0, 1.0);
    final value = 1 - (offset.dy / size.height).clamp(0.0, 1.0);
    setState(() {
      _hsvColor = _hsvColor.withSaturation(saturation).withValue(value);
    });
    _notifyColorChanged();
  }

  // Обработка изменения прозрачности
  void _onAlphaChanged(double value) {
    setState(() {
      _alpha = value;
    });
    _notifyColorChanged();
  }

  // Уведомление о изменении цвета
  void _notifyColorChanged() {
    final color = _hsvColor.toColor().withOpacity(_alpha);
    widget.onColorChanged(color);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isDesktop = MediaQuery.of(context).size.width > 600;
    // Адаптивная высота области выбора цвета (60% от высоты экрана, но не более 250 и не менее 120)
    final double areaHeight = (screenHeight * 0.6).clamp(120.0, 250.0);
    // Компактные отступы и размеры для мобильных устройств
    final double padding = isDesktop ? 16.0 : 8.0;
    final double sliderHeight = isDesktop ? 24.0 : 20.0;
    final double thumbRadius = isDesktop ? 8.0 : 6.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Область выбора насыщенности и яркости
        SizedBox(
          height: areaHeight,
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
                        top: (1 - _hsvColor.value) * constraints.maxHeight - 6,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _hsvColor.toColor(),
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
        SizedBox(height: padding),

        // Ползунок оттенка
        Container(
          height: sliderHeight,
          constraints: const BoxConstraints(maxWidth: 300),
          margin: EdgeInsets.symmetric(horizontal: padding),
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
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: thumbRadius),
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
          SizedBox(height: padding),
          // Ползунок прозрачности
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Прозрачность',
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : 12,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Container(
                  height: sliderHeight,
                  constraints: const BoxConstraints(maxWidth: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        _hsvColor.toColor(),
                      ],
                    ),
                  ),
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 0,
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: thumbRadius),
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      min: 0.0,
                      max: 1.0,
                      divisions: 100,
                      value: _alpha,
                      onChanged: _onAlphaChanged,
                      activeColor: Colors.transparent,
                      inactiveColor: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// Отрисовка области насыщенности и яркости
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
  bool shouldRepaint(covariant SaturationValuePainter oldDelegate) =>
      oldDelegate.hue != hue;
}