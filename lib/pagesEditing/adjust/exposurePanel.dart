import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'package:flutter/foundation.dart';
import '../../themeWidjets/sliderAdjusts.dart';

class ExposurePanel extends StatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback onApply;
  final Uint8List originalImage;
  final Function(Uint8List) onImageChanged;

  const ExposurePanel({
    required this.onCancel,
    required this.onApply,
    required this.originalImage,
    required this.onImageChanged,
    super.key,
  });

  @override
  _ExposurePanelState createState() => _ExposurePanelState();
}

class _ExposurePanelState extends State<ExposurePanel> {
  late img.Image _originalImage;
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

  void _applyAdjustments() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final result = await compute(_applyAllAdjustments, {
        'image': img.Image.from(_originalImage),
        'exposure': _exposureValue,
      });

      final adjustedBytes = img.encodePng(result);
      widget.onImageChanged(adjustedBytes); // Это вызовет _updateImage в EditPage
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
    double exposure = params['exposure'];

    return img.adjustColor(image, exposure: exposure);
  }

  void _resetAdjustments() {
    _debounceTimer?.cancel();
    setState(() {
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
          height: 140,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: <Widget>[
              // Экспозиция
              SliderRow(
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
                isProcessing: _isProcessing,
              ),
              const SizedBox(height: 10),

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
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }
}