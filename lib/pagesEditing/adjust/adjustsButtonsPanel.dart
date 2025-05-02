import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'package:flutter/foundation.dart';
import '../../themeWidjets/sliderAdjusts.dart';

class AdjustPanel extends StatefulWidget {
  final Uint8List originalImage;
  final Function(Uint8List) onImageChanged;
  final VoidCallback onClose;

  const AdjustPanel({
    required this.originalImage,
    required this.onImageChanged,
    required this.onClose,
    super.key,
  });

  @override
  _AdjustPanelState createState() => _AdjustPanelState();
}

class _AdjustPanelState extends State<AdjustPanel> {
  late img.Image _originalImage;
  double _brightnessValue = 0.0;
  double _contrastValue = 0.0;
  double _exposureValue = 0.0;
  double _saturationValue = 0.0;
  double _warmthValue = 0.0;
  double _noiseValue = 0.0;
  double _smoothValue = 0.0;

  Timer? _debounceTimer;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeImage();
  }

  Future<void> _initializeImage() async {
    try {
      final image = img.decodeImage(widget.originalImage);
      if (image == null) throw Exception('Failed to decode image');
      _originalImage = img.copyResize(image, width: image.width);
    } catch (e) {
      debugPrint('Error initializing image: $e');
    }
  }

  static img.Image _applyAllAdjustments(Map<String, dynamic> params) {
    img.Image image = params['image'];
    double brightness = params['brightness'] / 100.0;
    double contrast = params['contrast'] / 100.0;
    double exposure = params['exposure'] / 100.0;
    double saturation = params['saturation'] / 100.0;
    double noise = params['noise'] / 100.0;
    double smooth = params['smooth'] / 100.0;
    double warmth = params['warmth'] / 100.0;

    // Применяем все корректировки
    image = img.adjustColor(image,
      brightness: brightness,
      contrast: contrast,
      exposure: exposure,
      saturation: saturation,
    );

    // Применяем теплоту (имитация изменения температуры)
    if (warmth > 0) {
      image = img.colorOffset(image, red: 1.0 + warmth*0.5, blue: 1.0 - warmth*0.3);
    } else if (warmth < 0) {
      image = img.colorOffset(image, red: 1.0 + warmth*0.3, blue: 1.0 - warmth*0.5);
    }

    // Применяем шум
    if (noise > 0) {
      img.noise(image, noise * 100, type: img.NoiseType.gaussian);
    }

    // Применяем сглаживание (упрощенная реализация)
    if (smooth > 0) {
      image = img.smooth(image, weight: smooth);
    }

    return image;
  }

  void _applyAdjustmentsDebounced() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), _applyAdjustments);
  }

  void _applyAdjustments() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final result = await compute(_applyAllAdjustments, {
        'image': img.Image.from(_originalImage),
        'brightness': _brightnessValue,
        'contrast': _contrastValue,
        'exposure': _exposureValue,
        'saturation': _saturationValue,
        'warmth': _warmthValue,
        'noise': _noiseValue,
        'smooth': _smoothValue,
      });

      final adjustedBytes = img.encodePng(result);
      widget.onImageChanged(adjustedBytes);
    } catch (e) {
      debugPrint('Error applying adjustments: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _resetAllAdjustments() {
    _debounceTimer?.cancel();
    setState(() {
      _brightnessValue = 0.0;
      _contrastValue = 0.0;
      _exposureValue = 0.0;
      _saturationValue = 0.0;
      _warmthValue = 0.0;
      _noiseValue = 0.0;
      _smoothValue = 0.0;
      _isProcessing = false;
    });
    widget.onImageChanged(widget.originalImage);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Positioned(
        bottom: -30,
        left: 0,
        right: 0,
        child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(139, 0, 0, 0),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                // Заголовок и кнопки управления
                Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    appLocalizations?.adjust ?? 'Регулировки',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _resetAllAdjustments,
                        tooltip: appLocalizations?.reset ?? 'Сброс',
                        color: Colors.white,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: widget.onClose,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Слайдеры регулировок
              Container(
                height: 100,
                child: PageView(
                  children: [
                    // Яркость
                    SliderRow(
                      icon: Icons.brightness_4,
                      value: _brightnessValue,
                      min: -100,
                      max: 100,
                      label: '${_brightnessValue.round()}',
                      onChanged: (value) {
                        setState(() => _brightnessValue = value);
                        _applyAdjustmentsDebounced();
                      },
                      divisions: 1,
                      isProcessing: true,
                    ),

                    // Контраст
                    SliderRow(
                      icon: Icons.contrast,
                      value: _contrastValue,
                      min: -100,
                      max: 100,
                      label: '${_contrastValue.round()}',
                      onChanged: (value) {
                        setState(() => _contrastValue = value);
                        _applyAdjustmentsDebounced();
                      },
                      divisions: 1,
                      isProcessing: true,
                    ),

                    // Экспозиция
                    SliderRow(
                      icon: Icons.exposure,
                      value: _exposureValue,
                      min: -100,
                      max: 100,
                      label: '${_exposureValue.round()}',
                      onChanged: (value) {
                        setState(() => _exposureValue = value);
                        _applyAdjustmentsDebounced();
                      },
                      divisions: 1,
                      isProcessing: true,
                    ),

                    // Насыщенность
                    SliderRow(
                      icon: Icons.gradient,
                      value: _saturationValue,
                      min: -100,
                      max: 100,
                      label: '${_saturationValue.round()}',
                      onChanged: (value) {
                        setState(() => _saturationValue = value);
                        _applyAdjustmentsDebounced();
                      },
                      divisions: 1,
                      isProcessing: true,
                    ),

                    // Теплота
                    SliderRow(
                      icon: Icons.thermostat,
                      value: _warmthValue,
                      min: -100,
                      max: 100,
                      label: '${_warmthValue.round()}',
                      onChanged: (value) {
                        setState(() => _warmthValue = value);
                        _applyAdjustmentsDebounced();
                      },
                      divisions: 1,
                      isProcessing: true,
                    ),

                      // Зернистость
                      SliderRow(
                        icon: Icons.grain,
                        value: _noiseValue,
                        min: 0,
                        max: 100,
                        label: '${_noiseValue.round()}',
                        onChanged: (value) {
                          setState(() => _noiseValue = value);
                          _applyAdjustmentsDebounced();
                        },divisions: 1, isProcessing: true,
                      ),

                      // Сглаживание
                      SliderRow(
                        icon: Icons.blur_on,
                        value: _smoothValue,
                        min: 0,
                        max: 100,
                        label: '${_smoothValue.round()}',
                        onChanged: (value) {
                          setState(() => _smoothValue = value);
                          _applyAdjustmentsDebounced();
                        },divisions: 1, isProcessing: true,
                      ),
                    ],
                  ),
                ),
              if (_isProcessing)
                const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}