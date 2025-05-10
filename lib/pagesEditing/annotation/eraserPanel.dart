import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:MagicMoment/database/magicMomentDatabase.dart';
import 'package:MagicMoment/pagesEditing/image_utils.dart';

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
  double _strokeWidth = 20.0;
  bool _isInitialized = false;

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
    setState(() => _eraserPaths.add([offset]));
  }

  void _extendPath(Offset offset) {
    setState(() => _eraserPaths.last.add(offset));
  }

  void _undo() {
    if (_eraserPaths.isNotEmpty) {
      setState(() => _eraserPaths.removeLast());
    }
  }

  Future<void> _apply() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();
    canvas.drawImage(_backgroundImage, Offset.zero, paint);

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

    final img = await recorder.endRecording().toImage(
      _backgroundImage.width,
      _backgroundImage.height,
    );
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    await widget.onUpdateImage(
      pngBytes,
      action: 'Erased area',
      operationType: 'eraser',
      parameters: {
        'strokes': _eraserPaths.length,
        'width': _strokeWidth,
      },
    );

    widget.onApply(pngBytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          AppBar(
            backgroundColor: Colors.black,
            title: const Text('Eraser'),
            leading: IconButton(icon: const Icon(Icons.close), onPressed: widget.onCancel),
            actions: [
              IconButton(icon: const Icon(Icons.undo), onPressed: _undo),
              IconButton(icon: const Icon(Icons.check), onPressed: _apply),
            ],
          ),
          Expanded(
            child: _isInitialized
                ? GestureDetector(
              onPanStart: (d) => _startPath(d.localPosition),
              onPanUpdate: (d) => _extendPath(d.localPosition),
              child: RepaintBoundary(
                key: _paintKey,
                child: CustomPaint(
                  painter: _EraserPainter(
                    backgroundImage: _backgroundImage,
                    paths: _eraserPaths,
                    strokeWidth: _strokeWidth,
                  ),
                  child: Container(),
                ),
              ),
            )
                : const Center(child: CircularProgressIndicator()),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.grey[900],
            height: 70,
            child: Row(
              children: [
                const Text('Size', style: TextStyle(color: Colors.white)),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: _strokeWidth,
                    min: 5,
                    max: 50,
                    onChanged: (val) => setState(() => _strokeWidth = val),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _EraserPainter extends CustomPainter {
  final ui.Image backgroundImage;
  final List<List<Offset>> paths;
  final double strokeWidth;

  _EraserPainter({
    required this.backgroundImage,
    required this.paths,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(backgroundImage, Offset.zero, Paint());

    final paint = Paint()
      ..blendMode = BlendMode.clear
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final path in paths) {
      for (int i = 0; i < path.length - 1; i++) {
        canvas.drawLine(path[i], path[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


