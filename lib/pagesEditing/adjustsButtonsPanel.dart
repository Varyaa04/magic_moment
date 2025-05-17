import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import '../database/editHistory.dart';
import '../database/magicMomentDatabase.dart';
import '../themeWidjets/sliderAdjusts.dart';

class AdjustPanel extends StatefulWidget {
  final Uint8List image;
  final int imageId;
  final Function(Uint8List) onImageChanged;
  final VoidCallback onClose;
  final Function(Uint8List, {String? action, String? operationType, Map<String, dynamic>? parameters})? onUpdateImage;

  const AdjustPanel({
    required this.image,
    required this.imageId,
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
  static const _previewWidth = 800;
  static const _maxCacheSize = 10;

  @override
  void initState() {
    super.initState();
    _initializeImage();
  }

  @override
  void dispose() {
    _adjustmentCache.clear();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeImage() async {
    try {
      if (widget.image.isEmpty) {
        throw Exception('Input image is empty');
      }
      final image = img.decodeImage(widget.image);
      if (image == null) throw Exception('Failed to decode image');
      final resized = img.copyResize(image, width: _previewWidth, interpolation: img.Interpolation.average);
      setState(() {
        _originalImage = resized;
        _cachedImage = resized;
        _isInitialized = true;
      });
      widget.onImageChanged(widget.image);
    } catch (e) {
      _handleError('Image initialization error: $e');

    }
  }

  void _debounceApply() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), _applyAdjustments);
  }

  Future<void> _applyAdjustments() async {
    if (!_isInitialized || _isProcessing) return;
    final cacheKey = '$_brightness|$_contrast|$_saturation|$_exposure|$_noise|$_smooth';
    if (_adjustmentCache.containsKey(cacheKey)) {
      widget.onImageChanged(_adjustmentCache[cacheKey]!);
      widget.onUpdateImage?.call(
        _adjustmentCache[cacheKey]!,
        action: AppLocalizations.of(context)?.adjust ?? 'Intermediate adjustment',
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
      final result = img.encodePng(image, level: 6);
      if (result.isEmpty) {
        throw Exception(AppLocalizations.of(context)?.errorEncode ?? 'Image encoding error');
      }
      if (_adjustmentCache.length >= _maxCacheSize) {
        _adjustmentCache.remove(_adjustmentCache.keys.first);
      }
      _adjustmentCache[cacheKey] = result;
      _cachedImage = image;
      widget.onImageChanged(result);
      widget.onUpdateImage?.call(
        result,
        action: AppLocalizations.of(context)?.adjust ?? 'Intermediate adjustment',
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
    } catch (e) {
      debugPrint('Error applying adjustments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.errorApplyAdjustments ?? 'Error applying adjustments: $e')),
        );
      }
      widget.onImageChanged(widget.image);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _applyFinal() async {
    if (!_isInitialized || _isProcessing) {
      widget.onImageChanged(widget.image);
      widget.onClose();
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final fullImage = img.decodeImage(widget.image);
      if (fullImage == null) {
        throw Exception(AppLocalizations.of(context)?.errorDecode ?? 'Failed to decode full image');
      }
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
      final result = img.encodePng(image, level: 6);
      if (result.isEmpty) {
        throw Exception(AppLocalizations.of(context)?.errorEncode ?? 'Image encoding error');
      }

      final history = EditHistory(
        historyId: null,
        imageId: widget.imageId,
        operationType: 'adjustments',
        operationParameters: {
          'brightness': _brightness,
          'contrast': _contrast,
          'saturation': _saturation,
          'exposure': _exposure,
          'noise': _noise,
          'smooth': _smooth,
        },
        operationDate: DateTime.now(),
        snapshotPath: kIsWeb ? null : '${Directory.systemTemp.path}/adjust_${DateTime.now().millisecondsSinceEpoch}.png',
        snapshotBytes: kIsWeb ? result : null,
      );
      final db = MagicMomentDatabase.instance;
      await db.insertHistory(history);

      await widget.onUpdateImage?.call(
        result,
        action: AppLocalizations.of(context)?.adjust ?? 'Final adjustment',
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
      debugPrint('Error applying final adjustments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.errorApplyAdjustments ?? 'Error applying final adjustments: $e')),
        );
      }
      widget.onImageChanged(widget.image);
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
      _adjustmentCache.clear();
    });
    widget.onImageChanged(widget.image);
  }

  void _autoCorrect() {
    final image = _originalImage;
    final histogram = List<int>.filled(256, 0);
    int totalLuma = 0;
    int numPixels = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luma = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b).round();
        histogram[luma]++;
        totalLuma += luma;
        numPixels++;
      }
    }

    final avgLuma = totalLuma / numPixels;
    final minLuma = histogram.indexWhere((v) => v > 0);
    final maxLuma = histogram.lastIndexWhere((v) => v > 0);

    setState(() {
      _brightness = (128 - avgLuma).clamp(-50, 50);
      _contrast = ((maxLuma - minLuma) < 100 ? 20 : (maxLuma - minLuma) > 200 ? -20 : 10);
      _saturation = 0.2;
      _exposure = 0.1;
      _noise = 0;
      _smooth = 0;
    });

    _debounceApply();
  }

  void _handleError(String message) {
    debugPrint(message);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.error ?? message),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Stack(
          children: [
            if (_isProcessing)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t?.processingImage ?? 'Processing Image...',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t?.adjust ?? 'Adjust',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 18 : 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            _buildIconButton(
                              icon: Icons.auto_awesome,
                              color: Colors.amber,
                              tooltip: t?.autoCorrect ?? 'Auto Correct',
                              onPressed: _isProcessing ? () {} : _autoCorrect,
                              isMobile: isMobile,
                            ),
                            const SizedBox(width: 8),
                            _buildIconButton(
                              icon: Icons.refresh,
                              color: Colors.white70,
                              tooltip: t?.reset ?? 'Reset',
                              onPressed: _isProcessing ? () {} : _reset,
                              isMobile: isMobile,
                            ),
                            const SizedBox(width: 8),
                            _buildIconButton(
                              icon: Icons.check,
                              color: Colors.green,
                              tooltip: t?.apply ?? 'Apply',
                              onPressed: _isProcessing ? () {} : () => _applyFinal(),
                              isMobile: isMobile,
                            ),
                            const SizedBox(width: 8),
                            _buildIconButton(
                              icon: Icons.close,
                              color: Colors.redAccent,
                              tooltip: t?.close ?? 'Close',
                              onPressed: widget.onClose,
                              isMobile: isMobile,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: isMobile ? 90 : 110,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        children: [
                          _buildSlider(
                            icon: Icons.brightness_6,
                            label: t?.brightness ?? 'Brightness',
                            value: _brightness,
                            min: -100,
                            max: 100,
                            onChanged: (v) => setState(() {
                              _brightness = v;
                              _debounceApply();
                            }),
                          ),
                          _buildSlider(
                            icon: Icons.contrast,
                            label: t?.contrast ?? 'Contrast',
                            value: _contrast,
                            min: -100,
                            max: 100,
                            onChanged: (v) => setState(() {
                              _contrast = v;
                              _debounceApply();
                            }),
                          ),
                          _buildSlider(
                            icon: Icons.color_lens,
                            label: t?.saturation ?? 'Saturation',
                            value: _saturation,
                            min: -1,
                            max: 1,
                            onChanged: (v) => setState(() {
                              _saturation = v;
                              _debounceApply();
                            }),
                          ),
                          _buildSlider(
                            icon: Icons.exposure,
                            label: t?.exposure ?? 'Exposure',
                            value: _exposure,
                            min: -1,
                            max: 1,
                            onChanged: (v) => setState(() {
                              _exposure = v;
                              _debounceApply();
                            }),
                          ),
                          _buildSlider(
                            icon: Icons.grain,
                            label: t?.noise ?? 'Noise',
                            value: _noise,
                            min: 0,
                            max: 50,
                            onChanged: (v) => setState(() {
                              _noise = v;
                              _debounceApply();
                            }),
                          ),
                          _buildSlider(
                            icon: Icons.blur_on,
                            label: t?.smooth ?? 'Smooth',
                            value: _smooth,
                            min: 0,
                            max: 50,
                            onChanged: (v) => setState(() {
                              _smooth = v;
                              _debounceApply();
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSlider({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Container(
          width: isMobile ? 110 : 140,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white70, size: isMobile ? 18 : 20),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isMobile ? 12 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SliderRow(
                icon: icon,
                value: value,
                min: min,
                max: max,
                divisions: ((max - min).abs() * 10).toInt(),
                label: value.toStringAsFixed(1),
                onChanged: _isProcessing ? null : onChanged,
                isProcessing: _isProcessing,
                activeColor: Colors.blueAccent,
                inactiveColor: Colors.grey[700]!,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
    required bool isMobile,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: color,
              size: isMobile ? 20 : 24,
            ),
          ),
        ),
      ),
    );
  }
}

img.Image _processImage(Map<String, dynamic> params) {
  img.Image image = params['image'];
  double brightness = params['brightness'].clamp(-100.0, 100.0) * 0.5 / 100.0;
  double contrast = params['contrast'].clamp(-100.0, 100.0) * 0.5 / 100.0;
  double saturation = params['saturation'].clamp(-1.0, 1.0);
  double exposure = params['exposure'].clamp(-1.0, 1.0);
  double noise = params['noise'].clamp(0.0, 50.0) / 100.0;
  double smooth = params['smooth'].clamp(0.0, 50.0) / 100.0;
  int seed = params['seed'];

  try {
    image = img.adjustColor(
      image,
      brightness: brightness,
      contrast: contrast + 1.0,
      saturation: saturation + 1.0,
      exposure: exposure,
    );

    if (noise > 0.01) {
      image = img.noise(image, noise * 50, random: Random(seed), type: img.NoiseType.gaussian);
    }

    if (smooth > 0.01) {
      image = img.gaussianBlur(image, radius: (smooth * 2).toInt());
    }
  } catch (e) {
    debugPrint('Image processing error: $e');
  }

  return image;
}