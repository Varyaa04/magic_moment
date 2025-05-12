import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class CropPanel extends StatefulWidget {
  final Uint8List image;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;
  final Function(Uint8List, {String? action, String? operationType, Map<String, dynamic>? parameters}) onUpdateImage;

  const CropPanel({
    required this.image,
    required this.onCancel,
    required this.onApply,
    required this.onUpdateImage,
    super.key,
  });

  @override
  _CropPanelState createState() => _CropPanelState();
}

class _CropPanelState extends State<CropPanel> {
  Rect _cropRect = Rect.zero;
  Size _imageSize = Size.zero;
  bool _isProcessing = false;
  String _selectedAspectRatio = 'Freeform';
  ui.Image? _uiImage;
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  final Map<String, double?> _aspectRatios = {
    'Freeform': null,
    '1:1': 1.0,
    '4:3': 4 / 3,
    '3:4': 3 / 4,
    '16:9': 16 / 9,
    '9:16': 9 / 16,
  };

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.image);
      final frame = await codec.getNextFrame();
      setState(() {
        _uiImage = frame.image;
        _imageSize = Size(_uiImage!.width.toDouble(), _uiImage!.height.toDouble());
        _initializeCropRect();
      });
    } catch (e) {
      debugPrint('Error loading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load image: $e')),
        );
        widget.onCancel();
      }
    }
  }

  void _initializeCropRect() {
    // Start with a centered rect that's 80% of image size
    final width = _imageSize.width * 0.8;
    final height = _imageSize.height * 0.8;
    final left = (_imageSize.width - width) / 2;
    final top = (_imageSize.height - height) / 2;

    _cropRect = Rect.fromLTWH(left, top, width, height);
    _applyAspectRatio(_selectedAspectRatio);
  }

  void _applyAspectRatio(String aspectRatio) {
    setState(() {
      _selectedAspectRatio = aspectRatio;
      final ratio = _aspectRatios[aspectRatio];
      if (ratio == null) return;

      final center = _cropRect.center;
      double newWidth, newHeight;

      if (_cropRect.width / _cropRect.height > ratio) {
        // Current rect is wider than desired ratio - adjust height
        newHeight = _cropRect.width / ratio;
        newWidth = _cropRect.width;
      } else {
        // Current rect is taller than desired ratio - adjust width
        newWidth = _cropRect.height * ratio;
        newHeight = _cropRect.height;
      }

      // Ensure the new rect fits within image bounds
      newWidth = newWidth.clamp(10, _imageSize.width);
      newHeight = newHeight.clamp(10, _imageSize.height);

      _cropRect = Rect.fromCenter(
        center: center,
        width: newWidth,
        height: newHeight,
      );

      // Adjust if the rect goes outside image bounds
      _cropRect = Rect.fromLTWH(
        _cropRect.left.clamp(0, _imageSize.width - _cropRect.width),
        _cropRect.top.clamp(0, _imageSize.height - _cropRect.height),
        _cropRect.width,
        _cropRect.height,
      );
    });
  }

  void _updateCropRect(Offset delta, DragHandle handle) {
    setState(() {
      final ratio = _aspectRatios[_selectedAspectRatio];
      Rect newRect = _cropRect;

      switch (handle) {
        case DragHandle.topLeft:
          if (ratio != null) {
            delta = _constrainDeltaForAspectRatio(delta, ratio, handle);
          }
          newRect = Rect.fromLTRB(
            (_cropRect.left + delta.dx).clamp(0, _cropRect.right - 10),
            (_cropRect.top + delta.dy).clamp(0, _cropRect.bottom - 10),
            _cropRect.right,
            _cropRect.bottom,
          );
          break;
        case DragHandle.topRight:
          if (ratio != null) {
            delta = _constrainDeltaForAspectRatio(delta, ratio, handle);
          }
          newRect = Rect.fromLTRB(
            _cropRect.left,
            (_cropRect.top + delta.dy).clamp(0, _cropRect.bottom - 10),
            (_cropRect.right + delta.dx).clamp(_cropRect.left + 10, _imageSize.width),
            _cropRect.bottom,
          );
          break;
        case DragHandle.bottomLeft:
          if (ratio != null) {
            delta = _constrainDeltaForAspectRatio(delta, ratio, handle);
          }
          newRect = Rect.fromLTRB(
            (_cropRect.left + delta.dx).clamp(0, _cropRect.right - 10),
            _cropRect.top,
            _cropRect.right,
            (_cropRect.bottom + delta.dy).clamp(_cropRect.top + 10, _imageSize.height),
          );
          break;
        case DragHandle.bottomRight:
          if (ratio != null) {
            delta = _constrainDeltaForAspectRatio(delta, ratio, handle);
          }
          newRect = Rect.fromLTRB(
            _cropRect.left,
            _cropRect.top,
            (_cropRect.right + delta.dx).clamp(_cropRect.left + 10, _imageSize.width),
            (_cropRect.bottom + delta.dy).clamp(_cropRect.top + 10, _imageSize.height),
          );
          break;
        case DragHandle.center:
          final newLeft = (_cropRect.left + delta.dx).clamp(0, _imageSize.width - _cropRect.width);
          final newTop = (_cropRect.top + delta.dy).clamp(0, _imageSize.height - _cropRect.height);
          newRect = _cropRect.shift(Offset(newLeft - _cropRect.left, newTop - _cropRect.top));
          break;
      }

      _cropRect = newRect;
    });
  }

  Offset _constrainDeltaForAspectRatio(Offset delta, double ratio, DragHandle handle) {
    double dx = delta.dx;
    double dy = delta.dy;

    switch (handle) {
      case DragHandle.topLeft:
      case DragHandle.bottomRight:
        if (dx.abs() > dy.abs() * ratio) {
          dy = dx / ratio * (handle == DragHandle.topLeft ? -1 : 1);
        } else {
          dx = dy * ratio * (handle == DragHandle.topLeft ? -1 : 1);
        }
        break;
      case DragHandle.topRight:
      case DragHandle.bottomLeft:
        if (dx.abs() > dy.abs() * ratio) {
          dy = dx / ratio * (handle == DragHandle.topRight ? -1 : 1);
        } else {
          dx = dy * ratio * (handle == DragHandle.topRight ? -1 : 1);
        }
        break;
      case DragHandle.center:
        break;
    }

    return Offset(dx, dy);
  }

  Future<void> _applyCrop() async {
    if (_isProcessing || _uiImage == null) return;

    setState(() => _isProcessing = true);
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final srcRect = _cropRect;
      final dstRect = Rect.fromLTWH(0, 0, srcRect.width, srcRect.height);

      canvas.drawImageRect(_uiImage!, srcRect, dstRect, Paint());

      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(srcRect.width.toInt(), srcRect.height.toInt());
      final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to convert cropped image to bytes');

      final bytes = byteData.buffer.asUint8List();

      await widget.onUpdateImage(
        bytes,
        action: 'Applied crop',
        operationType: 'crop',
        parameters: {
          'template': _selectedAspectRatio,
          'aspect_ratio': _aspectRatios[_selectedAspectRatio]?.toString() ?? 'Freeform',
          'crop_rect': {
            'left': _cropRect.left,
            'top': _cropRect.top,
            'width': _cropRect.width,
            'height': _cropRect.height,
          },
        },
      );

      widget.onApply(bytes);
      widget.onCancel;
    } catch (e) {
      widget.onCancel;
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: _uiImage == null
                        ? const CircularProgressIndicator(color: Colors.white)
                        : FittedBox(
                      child: SizedBox(
                        width: _imageSize.width,
                        height: _imageSize.height,
                        child: GestureDetector(
                          onPanUpdate: (details) => _updateCropRect(details.delta, DragHandle.center),
                          child: Stack(
                            children: [
                              CustomPaint(
                                painter: ImagePainter(_uiImage!),
                              ),
                              CustomPaint(
                                painter: CropPainter(_cropRect, _imageSize),
                                child: Stack(
                                  children: [
                                    // Top-left handle
                                    Positioned(
                                      left: _cropRect.left - 15,
                                      top: _cropRect.top - 15,
                                      child: GestureDetector(
                                        onPanUpdate: (details) => _updateCropRect(details.delta, DragHandle.topLeft),
                                        child: _buildHandle(),
                                      ),
                                    ),
                                    // Top-right handle
                                    Positioned(
                                      left: _cropRect.right - 15,
                                      top: _cropRect.top - 15,
                                      child: GestureDetector(
                                        onPanUpdate: (details) => _updateCropRect(details.delta, DragHandle.topRight),
                                        child: _buildHandle(),
                                      ),
                                    ),
                                    // Bottom-left handle
                                    Positioned(
                                      left: _cropRect.left - 15,
                                      top: _cropRect.bottom - 15,
                                      child: GestureDetector(
                                        onPanUpdate: (details) => _updateCropRect(details.delta, DragHandle.bottomLeft),
                                        child: _buildHandle(),
                                      ),
                                    ),
                                    // Bottom-right handle
                                    Positioned(
                                      left: _cropRect.right - 15,
                                      top: _cropRect.bottom - 15,
                                      child: GestureDetector(
                                        onPanUpdate: (details) => _updateCropRect(details.delta, DragHandle.bottomRight),
                                        child: _buildHandle(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _buildControls(),
              ],
            ),
            if (_isProcessing)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue, width: 2),
    ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withOpacity(0.9),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _aspectRatios.keys.map((ratio) {
                return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton(
                  child: Text(ratio, style: const TextStyle(fontSize: 14)),
                  onPressed: _isProcessing ? null : () => _applyAspectRatio(ratio),
                style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _selectedAspectRatio == ratio ? Colors.blue : Colors.grey[800],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _isProcessing ? null : widget.onCancel,
                child: const Text('Cancel', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
              TextButton(
                onPressed: _isProcessing ? null : _applyCrop,
                child: const Text('Apply', style: TextStyle(color: Colors.blue, fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum DragHandle { topLeft, topRight, bottomLeft, bottomRight, center }

class ImagePainter extends CustomPainter {
  final ui.Image image;

  ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(image, Offset.zero, Paint());
  }

  @override
  bool shouldRepaint(ImagePainter oldDelegate) => oldDelegate.image != image;
}

class CropPainter extends CustomPainter {
  final Rect cropRect;
  final Size imageSize;

  CropPainter(this.cropRect, this.imageSize);

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Draw overlay outside crop area
    canvas.drawRect(Rect.fromLTWH(0, 0, imageSize.width, cropRect.top), overlayPaint);
    canvas.drawRect(Rect.fromLTWH(0, cropRect.bottom, imageSize.width, imageSize.height - cropRect.bottom), overlayPaint);
    canvas.drawRect(Rect.fromLTWH(0, cropRect.top, cropRect.left, cropRect.height), overlayPaint);
    canvas.drawRect(Rect.fromLTWH(cropRect.right, cropRect.top, imageSize.width - cropRect.right, cropRect.height), overlayPaint);

    // Draw crop border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(cropRect, borderPaint);

    // Draw grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final thirdWidth = cropRect.width / 3;
    final thirdHeight = cropRect.height / 3;

    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(cropRect.left + thirdWidth * i, cropRect.top),
        Offset(cropRect.left + thirdWidth * i, cropRect.bottom),
        gridPaint,
      );
      canvas.drawLine(
        Offset(cropRect.left, cropRect.top + thirdHeight * i),
        Offset(cropRect.right, cropRect.top + thirdHeight * i),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CropPainter oldDelegate) =>
      oldDelegate.cropRect != cropRect || oldDelegate.imageSize != imageSize;
}