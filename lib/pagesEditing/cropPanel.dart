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
      final codec = await ui.instantiateImageCodec(widget.image, targetWidth: 1024);
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
    final screenSize = MediaQuery.of(context).size;
    final maxWidth = screenSize.width * 0.9;
    final maxHeight = screenSize.height * 0.6;
    final imageAspect = _imageSize.width / _imageSize.height;

    double width = _imageSize.width;
    double height = _imageSize.height;

    // Scale to fit within screen
    if (width > maxWidth) {
      width = maxWidth;
      height = width / imageAspect;
    }
    if (height > maxHeight) {
      height = maxHeight;
      width = height * imageAspect;
    }

    // Center the crop rect
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

      double newWidth = _cropRect.width;
      double newHeight = newWidth / ratio;

      if (newHeight > _imageSize.height - _cropRect.top) {
        newHeight = _imageSize.height - _cropRect.top;
        newWidth = newHeight * ratio;
      }

      if (newWidth > _imageSize.width - _cropRect.left) {
        newWidth = _imageSize.width - _cropRect.left;
        newHeight = newWidth / ratio;
      }

      final centerX = _cropRect.left + _cropRect.width / 2;
      final centerY = _cropRect.top + _cropRect.height / 2;

      _cropRect = Rect.fromLTWH(
        centerX - newWidth / 2,
        centerY - newHeight / 2,
        newWidth,
        newHeight,
      );
    });
  }

  void _updateCropRect(Offset delta, DragHandle handle) {
    setState(() {
      Rect newRect = _cropRect;
      final ratio = _aspectRatios[_selectedAspectRatio];

      switch (handle) {
        case DragHandle.topLeft:
          newRect = _cropRect.translate(delta.dx, delta.dy);
          newRect = Rect.fromLTWH(
            newRect.left,
            newRect.top,
            newRect.width - delta.dx,
            newRect.height - delta.dy,
          );
          if (ratio != null) {
            newRect = _constrainAspectRatio(newRect, ratio, handle);
          }
          break;
        case DragHandle.topRight:
          newRect = _cropRect.translate(0, delta.dy);
          newRect = Rect.fromLTWH(
            newRect.left,
            newRect.top,
            newRect.width + delta.dx,
            newRect.height - delta.dy,
          );
          if (ratio != null) {
            newRect = _constrainAspectRatio(newRect, ratio, handle);
          }
          break;
        case DragHandle.bottomLeft:
          newRect = _cropRect.translate(delta.dx, 0);
          newRect = Rect.fromLTWH(
            newRect.left,
            newRect.top,
            newRect.width - delta.dx,
            newRect.height + delta.dy,
          );
          if (ratio != null) {
            newRect = _constrainAspectRatio(newRect, ratio, handle);
          }
          break;
        case DragHandle.bottomRight:
          newRect = Rect.fromLTWH(
            newRect.left,
            newRect.top,
            newRect.width + delta.dx,
            newRect.height + delta.dy,
          );
          if (ratio != null) {
            newRect = _constrainAspectRatio(newRect, ratio, handle);
          }
          break;
        case DragHandle.center:
          newRect = _cropRect.translate(delta.dx, delta.dy);
          break;
      }

      // Constrain within image bounds
      newRect = Rect.fromLTWH(
        newRect.left.clamp(0, _imageSize.width - newRect.width),
        newRect.top.clamp(0, _imageSize.height - newRect.height),
        newRect.width.clamp(10, _imageSize.width - newRect.left),
        newRect.height.clamp(10, _imageSize.height - newRect.top),
      );

      _cropRect = newRect;
    });
  }

  Rect _constrainAspectRatio(Rect rect, double ratio, DragHandle handle) {
    double newWidth = rect.width;
    double newHeight = newWidth / ratio;

    if (newHeight > _imageSize.height - rect.top) {
      newHeight = _imageSize.height - rect.top;
      newWidth = newHeight * ratio;
    }

    if (newWidth > _imageSize.width - rect.left) {
      newWidth = _imageSize.width - rect.left;
      newHeight = newWidth / ratio;
    }

    // Adjust position based on handle
    double left = rect.left;
    double top = rect.top;

    switch (handle) {
      case DragHandle.topLeft:
        left = rect.right - newWidth;
        top = rect.bottom - newHeight;
        break;
      case DragHandle.topRight:
        top = rect.bottom - newHeight;
        break;
      case DragHandle.bottomLeft:
        left = rect.right - newWidth;
        break;
      case DragHandle.bottomRight:
        break;
      case DragHandle.center:
        final centerX = rect.left + rect.width / 2;
        final centerY = rect.top + rect.height / 2;
        left = centerX - newWidth / 2;
        top = centerY - newHeight / 2;
        break;
    }

    return Rect.fromLTWH(left, top, newWidth, newHeight);
  }

  Future<void> _applyCrop() async {
    if (_isProcessing || _uiImage == null) return;

    setState(() => _isProcessing = true);
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final srcRect = _cropRect;
      final dstRect = Rect.fromLTWH(0, 0, srcRect.width, srcRect.height);

      canvas.drawImageRect(_uiImage!, srcRect, dstRect, Paint()..filterQuality = FilterQuality.high);

      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(srcRect.width.toInt(), srcRect.height.toInt());
      final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert cropped image to bytes');
      }

      final bytes = byteData.buffer.asUint8List();
      await widget.onUpdateImage(
        bytes,
        action: 'Applied crop',
        operationType: 'crop',
        parameters: {
          'template': _selectedAspectRatio,
          'aspect_ratio': _aspectRatios[_selectedAspectRatio] != null
              ? _aspectRatios[_selectedAspectRatio].toString()
              : 'Freeform',
          'crop_rect': {
            'left': _cropRect.left,
            'top': _cropRect.top,
            'width': _cropRect.width,
            'height': _cropRect.height,
          },
        },
      );

      widget.onApply(bytes);
    } catch (e) {
      debugPrint('Error applying crop: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error applying crop: $e')),
        );
      }
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
                        : GestureDetector(
                      onPanUpdate: (details) => _updateCropRect(details.delta, DragHandle.center),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.memory(
                            widget.image,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          CustomPaint(
                            painter: CropPainter(_cropRect, _imageSize),
                            child: Stack(
                              children: [
                                Positioned(
                                  left: _cropRect.left - 15,
                                  top: _cropRect.top - 15,
                                  child: GestureDetector(
                                    onPanUpdate: (details) => _updateCropRect(details.delta, DragHandle.topLeft),
                                    child: _buildHandle(),
                                  ),
                                ),
                                Positioned(
                                  left: _cropRect.right - 15,
                                  top: _cropRect.top - 15,
                                  child: GestureDetector(
                                    onPanUpdate: (details) => _updateCropRect(details.delta, DragHandle.topRight),
                                    child: _buildHandle(),
                                  ),
                                ),
                                Positioned(
                                  left: _cropRect.left - 15,
                                  top: _cropRect.bottom - 15,
                                  child: GestureDetector(
                                    onPanUpdate: (details) => _updateCropRect(details.delta, DragHandle.bottomLeft),
                                    child: _buildHandle(),
                                  ),
                                ),
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
                    onPressed: _isProcessing ? null : () => _applyAspectRatio(ratio),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: _selectedAspectRatio == ratio ? Colors.blue : Colors.grey[800],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Text(ratio, style: const TextStyle(fontSize: 14)),
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