import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'package:flutter/foundation.dart';
import '../../themeWidjets/sliderAdjusts.dart';

class NoisePanel extends StatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback onApply;
  final Uint8List originalImage;
  final Function(Uint8List) onImageChanged;

  const NoisePanel({
    required this.onCancel,
    required this.onApply,
    required this.originalImage,
    required this.onImageChanged,
    super.key,
  });

  @override
  _NoisePanelState createState() => _NoisePanelState();
}

class _NoisePanelState extends State<NoisePanel> {
  late img.Image _originalImage;
  double _noiseValue = 0.0;
  Timer? _debounceTimer;
  bool _isProcessing = false;
  final _adjustmentCache = <String, Uint8List>{};

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
      _originalImage = img.copyResize(image, width: image.width > 1200 ? 1200 : image.width);
    } catch (e) {
      debugPrint('Error initializing image: $e');
    }
  }

  void _applyAdjustmentsDebounced() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), _applyAdjustments);
  }

  void _applyAdjustments() async {
    if (_isProcessing) return;

    final cacheKey = _noiseValue.toStringAsFixed(2);
    if (_adjustmentCache.containsKey(cacheKey)) {
      widget.onImageChanged(_adjustmentCache[cacheKey]!);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final result = await compute(applyNoise, {
        'image': img.Image.from(_originalImage),
        'amount': _noiseValue / 100.0,
        'seed': DateTime.now().millisecondsSinceEpoch,
      });

      final adjustedBytes = img.encodePng(result);
      _adjustmentCache[cacheKey] = adjustedBytes;
      widget.onImageChanged(adjustedBytes);
    } catch (e) {
      debugPrint('Error applying noise: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  static img.Image applyNoise(Map<String, dynamic> params) {
    final image = params['image'] as img.Image;
    final amount = params['amount'] as double;

    final result = img.Image.from(image);
    final random = Random(params['seed'] as int);

    img.noise(result, amount * 100, random: random, type: img.NoiseType.gaussian);

    return result;
  }



  void _resetAdjustments() {
    _debounceTimer?.cancel();
    _adjustmentCache.clear();
    setState(() {
      _noiseValue = 0.0;
      _isProcessing = false;
    });
    widget.onImageChanged(widget.originalImage);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Container(
            height: 230,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Заголовок с кнопкой назад
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: Colors.white,
                      onPressed: widget.onCancel,
                    ),
                    Text(
                      appLocalizations?.noise ?? 'Зернистость',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                // Слайдер зернистости
                SliderRow(
                  icon: Icons.grain,
                  value: _noiseValue,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: '${_noiseValue.round()}%',
                  onChanged: (value) {
                    setState(() => _noiseValue = value);
                    _applyAdjustmentsDebounced();
                  },
                  isProcessing: _isProcessing,
                ),

                // Кнопки управления
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _resetAdjustments,
                      child: Text(
                        appLocalizations?.reset ?? 'Сброс',
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
                        const SizedBox(width: 10),
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
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : Text(
                            appLocalizations?.save ?? 'Применить',
                            style: const TextStyle(color: Colors.white),
                            selectionColor: Colors.grey,
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
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}