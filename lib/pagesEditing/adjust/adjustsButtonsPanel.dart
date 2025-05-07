import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import '../../themeWidjets/sliderAdjusts.dart';

class AdjustPanel extends StatefulWidget {
  final Uint8List originalImage;
  final Function(Uint8List) onImageChanged;
  final VoidCallback onClose;
  final Function(Uint8List, {String action, String operationType, Map<String, dynamic> parameters})? onUpdateImage;

  const AdjustPanel({
    required this.originalImage,
    required this.onImageChanged,
    required this.onClose,
    this.onUpdateImage,
    super.key,
  });

  @override
  _AdjustPanelState createState() => _AdjustPanelState();
}

class _AdjustPanelState extends State<AdjustPanel> {
  late img.Image _originalImage;
  img.Image? _cachedImage;
  double _brightnessValue = 0.0;
  double _contrastValue = 0.0;
  double _saturationValue = 0.0;
  double _warmthValue = 0.0;
  double _noiseValue = 0.0;
  double _smoothValue = 0.0;

  Timer? _debounceTimer;
  bool _isProcessing = false;
  bool _isInitialized = false;

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
      // Downscale for faster previews
      final resized = img.copyResize(image, width: 512, interpolation: img.Interpolation.linear);
      setState(() {
        _originalImage = resized;
        _cachedImage = resized;
        _isInitialized = true;
      });
      widget.onImageChanged(widget.originalImage); // Set initial image
    } catch (e) {
      debugPrint('Error initializing image: $e, stack: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load image: $e')),
        );
        widget.onClose();
      }
    }
  }

  Future<void> _updateImage(
      Uint8List newImage, {
        required String action,
        required String operationType,
        required Map<String, dynamic> parameters,
      }) async {
    try {
      await widget.onUpdateImage?.call(
        newImage,
        action: action,
        operationType: operationType,
        parameters: parameters,
      );
    } catch (e) {
      debugPrint('Error updating image: $e, stack: ${StackTrace.current}');
    }
  }

  static img.Image _applyAllAdjustments(Map<String, dynamic> params) {
    img.Image image = params['image'];
    final brightness = params['brightness'].clamp(-100.0, 100.0) / 100.0;
    final contrast = (1.0 + params['contrast'].clamp(-100.0, 100.0) / 100.0).clamp(0.1, 3.0);
    final saturation = (1.0 + params['saturation'].clamp(-100.0, 100.0) / 100.0).clamp(0.0, 3.0);
    final warmth = params['warmth'].clamp(-100.0, 100.0) / 100.0;
    final noise = params['noise'].clamp(0.0, 100.0) / 100.0;
    final smooth = params['smooth'].clamp(0.0, 100.0) / 100.0;

    // Apply adjustments in a fixed order
    if (brightness != 0 || contrast != 1.0 || saturation != 1.0) {
      image = img.adjustColor(
        image,
        brightness: (brightness * 100).toInt(),
        contrast: contrast,
        saturation: saturation,
      );
    }

    if (warmth != 0) {
      // Perceptually balanced warmth adjustment
      final warmthFactor = warmth * 0.3;
      image = img.colorOffset(
        image,
        red: warmth > 0 ? (warmthFactor * 50).toInt() : 0,
        blue: warmth < 0 ? (-warmthFactor * 50).toInt() : 0,
      );
    }

    if (noise > 0.01) {
      image = img.noise(image, (noise * 30).toInt(), type: img.NoiseType.gaussian);
    }

    if (smooth > 0.01) {
      image = img.gaussianBlur(image, radius: (smooth * 3).toInt());
    }

    return image;
  }

  void _applyAdjustmentsDebounced() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 30), _applyAdjustments);
  }

  Future<void> _applyAdjustments() async {
    if (_isProcessing || !_isInitialized) return;

    final params = {
      'brightness': _brightnessValue,
      'contrast': _contrastValue,
      'saturation': _saturationValue,
      'warmth': _warmthValue,
      'noise': _noiseValue,
      'smooth': _smoothValue,
    };

    setState(() => _isProcessing = true);

    try {
      final result = await compute(_applyAllAdjustments, {
        'image': _originalImage, // Always start from original for consistency
        'brightness': _brightnessValue,
        'contrast': _contrastValue,
        'saturation': _saturationValue,
        'warmth': _warmthValue,
        'noise': _noiseValue,
        'smooth': _smoothValue,
      });

      // Use JPG for previews, PNG for final output
      final adjustedBytes = img.encodeJpg(result, quality: 85);
      setState(() {
        _cachedImage = result;
      });

      await _updateImage(
        adjustedBytes,
        action: 'Adjusted image',
        operationType: 'adjustments',
        parameters: params,
      );

      widget.onImageChanged(adjustedBytes);
    } catch (e) {
      debugPrint('Error applying adjustments: $e, stack: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply adjustments: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _applyFinalAdjustments() async {
    if (_isProcessing || !_isInitialized) return;

    setState(() => _isProcessing = true);

    try {
      final result = await compute(_applyAllAdjustments, {
        'image': img.decodeImage(widget.originalImage)!, // Use full-res original
        'brightness': _brightnessValue,
        'contrast': _contrastValue,
        'saturation': _saturationValue,
        'warmth': _warmthValue,
        'noise': _noiseValue,
        'smooth': _smoothValue,
      });

      // Use PNG for final output
      final finalBytes = img.encodePng(result);
      await _updateImage(
        finalBytes,
        action: 'Final adjusted image',
        operationType: 'adjustments',
        parameters: {
          'brightness': _brightnessValue,
          'contrast': _contrastValue,
          'saturation': _saturationValue,
          'warmth': _warmthValue,
          'noise': _noiseValue,
          'smooth': _smoothValue,
        },
      );

      widget.onImageChanged(finalBytes);
    } catch (e) {
      debugPrint('Error applying final adjustments: $e, stack: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save adjustments: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _resetAllAdjustments() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.reset ?? 'Reset Adjustments'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              _debounceTimer?.cancel();
              setState(() {
                _brightnessValue = 0.0;
                _contrastValue = 0.0;
                _saturationValue = 0.0;
                _warmthValue = 0.0;
                _noiseValue = 0.0;
                _smoothValue = 0.0;
                _isProcessing = false;
                _cachedImage = _originalImage;
              });
              widget.onImageChanged(widget.originalImage);
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)?.reset ?? 'Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Stack(
      children: [
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(200, 0, 0, 0),
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
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        appLocalizations?.adjust ?? 'Adjust',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _resetAllAdjustments,
                            tooltip: appLocalizations?.reset ?? 'Reset',
                            color: Colors.white,
                          ),
                          IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: _isProcessing ? null : _applyFinalAdjustments,
                            tooltip: appLocalizations?.apply ?? 'Apply',
                            color: Colors.white,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: widget.onClose,
                            tooltip: appLocalizations?.exit ?? 'Close',
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Sliders in ListView
                  SizedBox(
                    height: 140,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildSlider(
                          icon: Icons.brightness_4,
                          label: appLocalizations?.brightness ?? 'Brightness',
                          value: _brightnessValue,
                          onChanged: (value) {
                            setState(() => _brightnessValue = value);
                            _applyAdjustmentsDebounced();
                          },
                        ),
                        _buildSlider(
                          icon: Icons.contrast,
                          label: appLocalizations?.contrast ?? 'Contrast',
                          value: _contrastValue,
                          onChanged: (value) {
                            setState(() => _contrastValue = value);
                            _applyAdjustmentsDebounced();
                          },
                        ),
                        _buildSlider(
                          icon: Icons.gradient,
                          label: appLocalizations?.saturation ?? 'Saturation',
                          value: _saturationValue,
                          onChanged: (value) {
                            setState(() => _saturationValue = value);
                            _applyAdjustmentsDebounced();
                          },
                        ),
                        _buildSlider(
                          icon: Icons.thermostat,
                          label: appLocalizations?.warmth ?? 'Warmth',
                          value: _warmthValue,
                          onChanged: (value) {
                            setState(() => _warmthValue = value);
                            _applyAdjustmentsDebounced();
                          },
                        ),
                        _buildSlider(
                          icon: Icons.grain,
                          label: appLocalizations?.noise ?? 'Noise',
                          value: _noiseValue,
                          min: 0,
                          max: 50,
                          onChanged: (value) {
                            setState(() => _noiseValue = value);
                            _applyAdjustmentsDebounced();
                          },
                        ),
                        _buildSlider(
                          icon: Icons.blur_on,
                          label: appLocalizations?.smooth ?? 'Smooth',
                          value: _smoothValue,
                          min: 0,
                          max: 50,
                          onChanged: (value) {
                            setState(() => _smoothValue = value);
                            _applyAdjustmentsDebounced();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isProcessing)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
      ],
    );
  }

  Widget _buildSlider({
    required IconData icon,
    required String label,
    required double value,
    double min = -100,
    double max = 100,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
              Text(
                value.round().toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: 400,
            label: value.round().toString(),
            onChanged: _isProcessing ? null : onChanged,
            activeColor: Colors.blue,
            inactiveColor: Colors.grey,
          ),
        ],
      ),
    );
  }
}