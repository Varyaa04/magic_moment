import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'package:flutter/foundation.dart'; // Добавьте этот импорт

class BrightnessPanel extends StatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback onApply;
  final Uint8List originalImage;
  final Function(Uint8List) onImageChanged;

  const BrightnessPanel({
    required this.onCancel,
    required this.onApply,
    required this.originalImage,
    required this.onImageChanged,
    super.key,
  });

  @override
  _BrightnessPanelState createState() => _BrightnessPanelState();
}

class _BrightnessPanelState extends State<BrightnessPanel> {
  late img.Image _originalImage;
  double _brightnessValue = 0.0;
  double _contrastValue = 1.0;
  double _exposureValue = 0.0;
  Timer? _debounceTimer;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeImage();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
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

  void _applyAdjustmentsDebounced() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), _applyAdjustments);
  }

  Future<void> _applyAdjustments() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Создаем копию оригинального изображения
      var adjustedImage = img.Image.from(_originalImage);

      // Применяем корректировки в изолированном контексте
      final result = await compute(_applyAllAdjustments, {
        'image': adjustedImage,
        'brightness': _brightnessValue,
        'contrast': _contrastValue,
        'exposure': _exposureValue,
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

  static img.Image _applyAllAdjustments(Map<String, dynamic> params) {
    img.Image image = params['image'];
    double brightness = params['brightness'];
    double contrast = params['contrast'];
    double exposure = params['exposure'];

    if (brightness != 0) {
      image = img.adjustColor(image, brightness: brightness / 100.0);
    }
    if (contrast != 1.0) {
      image = img.adjustColor(image, contrast: contrast);
    }
    if (exposure != 0.0) {
      image = img.adjustColor(image, exposure: exposure);
    }

    return image;
  }

  void _resetAdjustments() {
    _debounceTimer?.cancel();
    setState(() {
      _brightnessValue = 0.0;
      _contrastValue = 1.0;
      _exposureValue = 0.0;
      _isProcessing = false;
    });
    widget.onImageChanged(widget.originalImage);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    return Stack(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: <Widget>[
              // Яркость
              _buildSliderRow(
                icon: Icons.brightness_5,
                value: _brightnessValue,
                min: -100,
                max: 100,
                divisions: 200,
                label: _brightnessValue.round().toString(),
                onChanged: (value) {
                  setState(() => _brightnessValue = value);
                  _applyAdjustmentsDebounced();
                },
              ),

              // Контраст
              _buildSliderRow(
                icon: Icons.contrast,
                value: _contrastValue,
                min: 0.5,
                max: 1.5,
                divisions: 100,
                label: _contrastValue.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() => _contrastValue = value);
                  _applyAdjustmentsDebounced();
                },
              ),

              // Экспозиция
              _buildSliderRow(
                icon: Icons.exposure,
                value: _exposureValue,
                min: -1.0,
                max: 1.0,
                divisions: 100,
                label: _exposureValue.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() => _exposureValue = value);
                  _applyAdjustmentsDebounced();
                },
              ),

              const SizedBox(height: 12),

              // Кнопки управления
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _resetAdjustments,
                    child: Text(
                      appLocalizations?.cancel ?? 'Сброс',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: widget.onCancel,
                        child: Text(
                          appLocalizations?.cancel ?? 'Отмена',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: _isProcessing
                            ? null
                            : () {
                          _debounceTimer?.cancel();
                          widget.onApply();
                        },
                        child: _isProcessing
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          appLocalizations?.save ?? 'Применить',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_isProcessing)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSliderRow({
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return IgnorePointer(
      ignoring: _isProcessing,
      child: Opacity(
        opacity: _isProcessing ? 0.5 : 1.0,
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                label: label,
                onChanged: onChanged,
              ),
            ),
            SizedBox(
              width: 40,
              child: Text(
                label,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}