import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class EraserPanel extends StatefulWidget {
  final Uint8List image;
  final int imageId;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;
  final Function(Uint8List, {String? action, String? operationType, Map<String, dynamic>? parameters}) onUpdateImage;

  const EraserPanel({
    required this.image,
    required this.imageId,
    required this.onCancel,
    required this.onApply,
    required this.onUpdateImage,
    super.key,
  });

  @override
  State<EraserPanel> createState() => _EraserPanelState();
}

class _EraserPanelState extends State<EraserPanel> {
  late ui.Image _backgroundImage;
  final GlobalKey _paintKey = GlobalKey();
  final List<List<Offset>> _eraserPaths = [];
  final List<List<Offset>> _objectMaskPaths = [];
  double _strokeWidth = 20.0;
  bool _isInitialized = false;
  bool _isObjectRemovalMode = false;
  String apikey = 'a137bd6b259ff34bb97c5730bdf33a5be641b0de';

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final codec = await ui.instantiateImageCodec(widget.image);
    final frame = await codec.getNextFrame();
    _backgroundImage = frame.image;
    setState(() => _isInitialized = true);
  }

  void _startPath(Offset offset) {
    final list = [offset];
    setState(() {
      _isObjectRemovalMode ? _objectMaskPaths.add(list) : _eraserPaths.add(list);
    });
  }

  void _extendPath(Offset offset) {
    final target = _isObjectRemovalMode ? _objectMaskPaths : _eraserPaths;
    setState(() => target.last.add(offset));
  }

  void _undo() {
    setState(() {
      if (_isObjectRemovalMode && _objectMaskPaths.isNotEmpty) {
        _objectMaskPaths.removeLast();
      } else if (_eraserPaths.isNotEmpty) {
        _eraserPaths.removeLast();
      }
    });
  }

  void _toggleMode() {
    setState(() {
      _isObjectRemovalMode = !_isObjectRemovalMode;
    });
  }

  Future<void> _apply() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(_backgroundImage, Offset.zero, Paint());

    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    for (final path in _eraserPaths) {
      for (int i = 0; i < path.length - 1; i++) {
        canvas.drawLine(path[i], path[i + 1], clearPaint);
      }
    }

    final imgFinal = await recorder.endRecording().toImage(
      _backgroundImage.width,
      _backgroundImage.height,
    );
    final byteData = await imgFinal.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    widget.onUpdateImage(
      pngBytes,
      action: 'Erased area',
      operationType: 'eraser',
      parameters: {
        'strokes': _eraserPaths.length,
        'width': _strokeWidth,
      },
    );

    widget.onApply(pngBytes);
    widget.onCancel();
  }


  Future<Uint8List?> _callPhotoRoomObjectRemovalAPI(Uint8List originalImage, Uint8List maskImage) async {
    final uri = Uri.parse('https://sdk.photoroom.com/v1/segment/inpaint');
    final request = http.MultipartRequest('POST', uri)
      ..headers['x-api-key'] = apikey
      ..files.add(http.MultipartFile.fromBytes('image_file', originalImage, filename: 'image.png'))
      ..files.add(http.MultipartFile.fromBytes('mask_file', maskImage, filename: 'mask.png'));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      debugPrint('PhotoRoom error: ${response.statusCode} ${response.body}');
      return null;
    }
  }

  Future<void> _removeObject() async {
    try {
      final maskImage = await _generateMaskImage();
      final response = await _callPhotoRoomObjectRemovalAPI(widget.image, maskImage);

      if (response != null && mounted) {
        widget.onUpdateImage(
          response,
          action: 'Object removed',
          operationType: 'inpaint',
          parameters: {'paths': _objectMaskPaths.length},
        );
        widget.onApply(response);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при удалении объекта')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Future<Uint8List> _generateMaskImage() async {
    final mask = img.Image(width: _backgroundImage.width, height: _backgroundImage.height);
    // Fill with black (0, 0, 0)
    for (int y = 0; y < mask.height; y++) {
      for (int x = 0; x < mask.width; x++) {
        mask.setPixel(x, y, img.ColorUint8(0));
      }
    }

    // Mark mask with white points
    for (final path in _objectMaskPaths) {
      for (final point in path) {
        img.drawCircle(
          mask,
          x: point.dx.toInt(),
          y: point.dy.toInt(),
          radius: (_strokeWidth / 2).toInt(),
          color: img.ColorUint8(255),
          antialias: true,
        );
      }
    }

    return Uint8List.fromList(img.encodePng(mask));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.6),
        title: Text(_isObjectRemovalMode ? 'Удаление объектов' : 'Ластик'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: widget.onCancel),
        actions: [
          IconButton(icon: const Icon(Icons.undo), onPressed: _undo),
          IconButton(icon: const Icon(Icons.check), onPressed: _apply),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 60),
          Expanded(
            child: _isInitialized
                ? GestureDetector(
              onPanStart: (d) => _startPath(d.localPosition),
              onPanUpdate: (d) => _extendPath(d.localPosition),
              child: AspectRatio(
                aspectRatio: _backgroundImage.width / _backgroundImage.height,
                child: RepaintBoundary(
                  key: _paintKey,
                  child: CustomPaint(
                    painter: _EraserPainter(
                      backgroundImage: _backgroundImage,
                      eraserPaths: _eraserPaths,
                      objectMaskPaths: _objectMaskPaths,
                      strokeWidth: _strokeWidth,
                      isObjectMode: _isObjectRemovalMode,
                    ),
                  ),
                ),
              ),
            )
                : const Center(child: CircularProgressIndicator()),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 100,
            color: Colors.black.withOpacity(0.75),
            child: Row(
              children: [
                const Text('Толщина', style: TextStyle(color: Colors.white)),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: _strokeWidth,
                    min: 5,
                    max: 50,
                    activeColor: Colors.pinkAccent,
                    inactiveColor: Colors.grey[700],
                    onChanged: (val) => setState(() => _strokeWidth = val),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isObjectRemovalMode ? Icons.auto_fix_high : FluentIcons.eraser_20_filled,
                    color: _isObjectRemovalMode ? Colors.orangeAccent : Colors.blueAccent,
                  ),
                  onPressed: _toggleMode,
                  tooltip: _isObjectRemovalMode ? 'Режим удаления объектов' : 'Режим ластика',
                ),
                const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _removeObject,
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('Удалить объект'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EraserPainter extends CustomPainter {
  final ui.Image backgroundImage;
  final List<List<Offset>> eraserPaths;
  final List<List<Offset>> objectMaskPaths;
  final double strokeWidth;
  final bool isObjectMode;

  _EraserPainter({
    required this.backgroundImage,
    required this.eraserPaths,
    required this.objectMaskPaths,
    required this.strokeWidth,
    required this.isObjectMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw original image
    canvas.drawImage(backgroundImage, Offset.zero, Paint());

    // Draw eraser or object mask paths
    final paths = isObjectMode ? objectMaskPaths : eraserPaths;
    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (isObjectMode) {
      // Object removal mode - draw red lines
      paint.color = Colors.red.withOpacity(0.7);
      paint.blendMode = BlendMode.srcOver;
    } else {
      // Eraser mode - draw transparent lines
      paint.color = const Color(0x00000000);
      paint.blendMode = BlendMode.clear;
    }

    for (final path in paths) {
      for (int i = 0; i < path.length - 1; i++) {
        canvas.drawLine(path[i], path[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}