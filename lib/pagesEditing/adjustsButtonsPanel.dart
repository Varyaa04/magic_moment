import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import '../themeWidjets/sliderAdjusts.dart';

class AdjustPanel extends StatefulWidget {
  final Uint8List originalImage;
  final Function(Uint8List) onImageChanged;
  final VoidCallback onClose;
  final Function(Uint8List, {String? action, String? operationType, Map<String, dynamic>? parameters})? onUpdateImage;

  const AdjustPanel({
    required this.originalImage,
    required this.onImageChanged,
    required this.onClose,
    this.onUpdateImage,
    super.key,
  });

  @override
  State<AdjustPanel> createState() => _AdjustPanelState();
}

class _AdjustPanelState extends State<AdjustPanel> {
  late img.Image _originalImage;
  img.Image? _cachedImage;
  double _brightness = 0.0;
  double _contrast = 0.0;
  double _saturation = 0.0;
  double _exposure = 0.0;
  double _noise = 0.0;
  double _smooth = 0.0;
  Timer? _debounceTimer;
  bool _isProcessing = false;
  bool _isInitialized = false;
  final _adjustmentCache = <String, Uint8List>{};

  @override
  void initState() {
    super.initState();
    _initializeImage();
  }

  @override
  void dispose() {
    _adjustmentCache.clear();
    super.dispose();
  }

  Future<void> _initializeImage() async {
    try {
      final image = img.decodeImage(widget.originalImage);
      if (image == null) throw Exception('Failed to decode image');
      final resized = img.copyResize(image, width: min(image.width, 1200));
      setState(() {
        _originalImage = resized;
        _cachedImage = resized;
        _isInitialized = true;
      });
      widget.onImageChanged(widget.originalImage);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки изображения: $e')),
        );
        widget.onClose();
      }
    }
  }

  void _debounceApply() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), _applyAdjustments);
  }

  Future<void> _applyAdjustments() async {
    if (!_isInitialized || _isProcessing) return;
    final cacheKey = '$_brightness|$_contrast|$_saturation|$_exposure|$_noise|$_smooth';
    if (_adjustmentCache.containsKey(cacheKey)) {
      widget.onImageChanged(_adjustmentCache[cacheKey]!);
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final image = await compute(_processImage, {
        'image': _originalImage,
        'brightness': _brightness,
        'contrast': _contrast,
        'saturation': _saturation,
        'exposure': _exposure,
        'noise': _noise,
        'smooth': _smooth,
        'seed': DateTime.now().millisecondsSinceEpoch,
      });
      final result = img.encodePng(image);
      _adjustmentCache[cacheKey] = result;
      _cachedImage = image;
      widget.onImageChanged(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка применения: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _applyFinal() async {
    if (!_isInitialized || _isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final fullImage = img.decodeImage(widget.originalImage)!;
      final image = await compute(_processImage, {
        'image': fullImage,
        'brightness': _brightness,
        'contrast': _contrast,
        'saturation': _saturation,
        'exposure': _exposure,
        'noise': _noise,
        'smooth': _smooth,
        'seed': DateTime.now().millisecondsSinceEpoch,
      });
      final result = img.encodePng(image);
      await widget.onUpdateImage?.call(result,
        action: 'Автокоррекция или ручная настройка',
        operationType: 'adjustments',
        parameters: {
          'brightness': _brightness,
          'contrast': _contrast,
          'saturation': _saturation,
          'exposure': _exposure,
          'noise': _noise,
          'smooth': _smooth,
        },
      );
      widget.onImageChanged(result);
      widget.onClose();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка применения: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _reset() {
    setState(() {
      _brightness = 0;
      _contrast = 0;
      _saturation = 0;
      _exposure = 0;
      _noise = 0;
      _smooth = 0;
      _cachedImage = _originalImage;
    });
    widget.onImageChanged(widget.originalImage);
  }

  void _autoCorrect() {
    final image = _originalImage;
    int totalLuma = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = _originalImage.getPixel(x, y);
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;

        final luma = (0.299 * r + 0.587 * g + 0.114 * b).round();
        totalLuma += luma;
      }
    }

    final numPixels = image.width * image.height;
    final avgLuma = totalLuma ~/ numPixels;

    setState(() {
      _brightness = (128 - avgLuma).clamp(-30, 30).toDouble();
      _contrast = (avgLuma < 100) ? 30 : (avgLuma > 180 ? -10 : 0);
      _saturation = 0.2;
      _exposure = 0.05;
    });

    _debounceApply();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Stack(
      children: [
        if (_isProcessing)
          Container(color: Colors.black45, child: const Center(child: CircularProgressIndicator())),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t?.adjust ?? 'Настройки', style: const TextStyle(color: Colors.white, fontSize: 18)),
                    Row(children: [
                      IconButton(onPressed: _autoCorrect, icon: const Icon(Icons.auto_awesome, color: Colors.amber)),
                      IconButton(onPressed: _reset, icon: const Icon(Icons.refresh, color: Colors.white)),
                      IconButton(onPressed: _applyFinal, icon: const Icon(Icons.check, color: Colors.white)),
                      IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close, color: Colors.white)),
                    ])
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildSlider(Icons.brightness_6, t?.brightness ?? 'Яркость', _brightness, -100, 100, (v) => setState(() { _brightness = v; _debounceApply(); })),
                      _buildSlider(Icons.contrast, t?.contrast ?? 'Контраст', _contrast, -100, 100, (v) => setState(() { _contrast = v; _debounceApply(); })),
                      _buildSlider(Icons.color_lens, t?.saturation ?? 'Насыщенность', _saturation, -1, 1, (v) => setState(() { _saturation = v; _debounceApply(); })),
                      _buildSlider(Icons.exposure, t?.exposure ?? 'Экспозиция', _exposure, -1, 1, (v) => setState(() { _exposure = v; _debounceApply(); })),
                      _buildSlider(Icons.grain, t?.noise ?? 'Шум', _noise, 0, 100, (v) => setState(() { _noise = v; _debounceApply(); })),
                      _buildSlider(Icons.blur_on, t?.smooth ?? 'Сглаживание', _smooth, 0, 100, (v) => setState(() { _smooth = v; _debounceApply(); })),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(IconData icon, String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Row(children: [Icon(icon, color: Colors.white), const SizedBox(width: 6), Text(label, style: const TextStyle(color: Colors.white))]),
          SliderRow(
            icon: icon,
            value: value,
            min: min,
            max: max,
            divisions: (max - min).abs().toInt() * 10,
            label: value.toStringAsFixed(1),
            onChanged: _isProcessing ? null : onChanged,
            isProcessing: _isProcessing,
          ),
        ],
      ),
    );
  }
}

img.Image _processImage(Map<String, dynamic> params) {
  img.Image image = params['image'];
  double brightness = params['brightness'] / 100.0;
  double contrast = params['contrast'] / 100.0;
  double saturation = params['saturation'];
  double exposure = params['exposure'];
  double noise = params['noise'] / 100.0;
  double smooth = params['smooth'] / 100.0;
  int seed = params['seed'];

  image = img.adjustColor(
    image,
    brightness: brightness,
    contrast: contrast + 1.0,
    saturation: saturation + 1.0,
    exposure: exposure,
  );

  if (noise > 0.01) {
    image = img.noise(image, noise * 100, random: Random(seed), type: img.NoiseType.gaussian);
  }

  if (smooth > 0.01) {
    image = img.smooth(image, weight: smooth);
  }

  return image;
}
