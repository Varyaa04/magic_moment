import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';

class DrawPanel extends StatefulWidget {
  final Uint8List currentImage;
  final Function(Uint8List) onImageChanged;
  final VoidCallback onCancel;
  final VoidCallback onApply;
  final bool isDrawingPanelVisible;

  const DrawPanel({
    required this.currentImage,
    required this.onImageChanged,
    required this.onCancel,
    required this.onApply,
    required this.isDrawingPanelVisible,
    Key? key,
  }) : super(key: key);

  @override
  _DrawPanelState createState() => _DrawPanelState();
}

class _DrawPanelState extends State<DrawPanel> {
  Color _drawColor = Colors.red;
  double _strokeWidth = 5.0;
  bool _isErasing = false;
  List<DrawingPoint> _points = [];
  final GlobalKey _imageKey = GlobalKey();
  Rect? _imageRect;
  ui.Image? _originalImage;

  @override
  void initState() {
    super.initState();
    _loadOriginalImage();
  }

  Future<void> _loadOriginalImage() async {
    final codec = await ui.instantiateImageCodec(widget.currentImage);
    final frame = await codec.getNextFrame();
    _originalImage = frame.image;
  }

  void _clearDrawing() {
    setState(() {
      _points = [];
    });
  }

  Future<void> _applyDrawing() async {
    if (_points.isEmpty) {
      widget.onCancel();
      return;
    }

    try {
      if (_originalImage == null) {
        await _loadOriginalImage();
      }

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, _originalImage!.width.toDouble(), _originalImage!.height.toDouble()));

      // Draw original image
      canvas.drawImage(_originalImage!, Offset.zero, Paint());

      // Draw all points
      for (int i = 0; i < _points.length - 1; i++) {
        if (!_points[i].end && !_points[i + 1].end) {
          final startPos = _convertToImageCoordinates(_points[i].position);
          final endPos = _convertToImageCoordinates(_points[i + 1].position);

          if (startPos != null && endPos != null) {
            canvas.drawLine(
              startPos,
              endPos,
              _points[i].paint,
            );
          }
        }
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(_originalImage!.width, _originalImage!.height);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      widget.onImageChanged(bytes);
      widget.onApply();
    } catch (e) {
      debugPrint('Error applying drawing: $e');
    }
  }

  Offset? _convertToImageCoordinates(Offset localOffset) {
    if (_imageRect == null || _originalImage == null) return null;

    // Calculate the scale factors
    final scaleX = _originalImage!.width / _imageRect!.width;
    final scaleY = _originalImage!.height / _imageRect!.height;

    // Convert to image coordinates
    final imageX = (localOffset.dx - _imageRect!.left) * scaleX;
    final imageY = (localOffset.dy - _imageRect!.top) * scaleY;

    return Offset(imageX, imageY);
  }

  void _updateImagePosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final offset = renderBox.localToGlobal(Offset.zero);
        setState(() {
          _imageRect = Rect.fromLTWH(
            offset.dx,
            offset.dy,
            renderBox.size.width,
            renderBox.size.height,
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    if (!widget.isDrawingPanelVisible) {
      return Container();
    }

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Drawing tools
          Row(
            children: [
              // Color selection
              ...['red', 'blue', 'green', 'yellow', 'purple', 'grey', 'white', 'black'].map((color) {
                final colorValue = _getColorFromString(color);
                return GestureDetector(
                  onTap: () {
                    if (!_isErasing) {
                      setState(() => _drawColor = colorValue);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colorValue,
                      border: _drawColor == colorValue && !_isErasing
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(width: 10),

              // Eraser
              IconButton(
                icon: Icon(Icons.auto_fix_high, color: _isErasing ? Colors.blue : Colors.white),
                onPressed: () => setState(() => _isErasing = !_isErasing),
              ),

              // Clear
              IconButton(
                icon: Icon(Icons.clear, color: Colors.white),
                onPressed: _clearDrawing,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Brush size
          Row(
            children: [
              Text(appLocalizations?.brushSize ?? 'Brush size:',
                  style: TextStyle(color: Colors.white)),
              Expanded(
                child: Slider(
                  value: _strokeWidth,
                  min: 1,
                  max: 20,
                  divisions: 19,
                  label: _strokeWidth.round().toString(),
                  onChanged: (value) => setState(() => _strokeWidth = value),
                ),
              ),
            ],
          ),

          // Drawing area
          Expanded(
            child: GestureDetector(
              onPanStart: (details) {
                _updateImagePosition();
                setState(() {
                  _points.add(DrawingPoint(
                    position: details.localPosition,
                    paint: Paint()
                      ..color = _isErasing ? Colors.transparent : _drawColor
                      ..strokeWidth = _strokeWidth
                      ..strokeCap = StrokeCap.round
                      ..blendMode = _isErasing ? BlendMode.clear : BlendMode.srcOver,
                  ));
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _points.add(DrawingPoint(
                    position: details.localPosition,
                    paint: Paint()
                      ..color = _isErasing ? Colors.transparent : _drawColor
                      ..strokeWidth = _strokeWidth
                      ..strokeCap = StrokeCap.round
                      ..blendMode = _isErasing ? BlendMode.clear : BlendMode.srcOver,
                  ));
                });
              },
              onPanEnd: (details) {
                setState(() {
                  _points.add(DrawingPoint(end: true, paint: Paint()));
                });
              },
              child: Stack(
                children: [
                  Center(
                    child: Image.memory(
                      key: _imageKey,
                      widget.currentImage,
                      fit: BoxFit.contain,
                    ),
                  ),
                  CustomPaint(
                    painter: _DrawingPainter(points: _points),
                    child: Container(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Apply/Cancel buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: Text(appLocalizations?.cancel ?? 'Cancel',
                    style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _points.isNotEmpty ? _applyDrawing : null,
                child: Text(appLocalizations?.apply ?? 'Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getColorFromString(String color) {
    switch (color) {
      case 'red': return Colors.red;
      case 'green': return Colors.green;
      case 'blue': return Colors.blue;
      case 'white': return Colors.white;
      case 'yellow': return Colors.yellow;
      case 'purple': return Colors.purple;
      case 'grey': return Colors.grey;
      case 'black': return Colors.black;
      default: return Colors.white;
    }
  }
}

class _DrawingPainter extends CustomPainter {
  final List<DrawingPoint> points;

  _DrawingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (!points[i].end && !points[i + 1].end) {
        canvas.drawLine(points[i].position, points[i + 1].position, points[i].paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DrawingPoint {
  Offset position;
  Paint paint;
  bool end;

  DrawingPoint({
    this.position = Offset.zero,
    required this.paint,
    this.end = false,
  });
}