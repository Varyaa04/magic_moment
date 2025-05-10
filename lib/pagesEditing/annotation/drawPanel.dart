import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:MagicMoment/database/magicMomentDatabase.dart';
import 'package:MagicMoment/pagesEditing/image_utils.dart';

class DrawPanel extends StatefulWidget {
  final Uint8List image;
  final int imageId;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;
  final Function(Uint8List, {String? action, String? operationType, Map<String, dynamic>? parameters}) onUpdateImage;

  const DrawPanel({
    required this.image,
    required this.imageId,
    required this.onCancel,
    required this.onApply,
    required this.onUpdateImage,
    super.key,
  });

  @override
  State<DrawPanel> createState() => _DrawPanelState();
}

class _DrawPanelState extends State<DrawPanel> {
  late ui.Image _backgroundImage;
  final List<DrawingAction> _drawingActions = [];
  final List<DrawingAction> _undoStack = [];
  bool _isInitialized = false;
  Color _currentColor = Colors.red;
  double _currentStrokeWidth = 5.0;
  final GlobalKey _paintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.image);
      final frame = await codec.getNextFrame();
      _backgroundImage = frame.image;
      setState(() => _isInitialized = true);
    } catch (e) {
      widget.onCancel();
    }
  }

  void _startDrawing(Offset position) {
    setState(() {
      _drawingActions.add(
        DrawingAction([
          position
        ], _currentColor, _currentStrokeWidth),
      );
    });
  }

  void _updateDrawing(Offset position) {
    setState(() {
      _drawingActions.last.points.add(position);
    });
  }

  void _undo() {
    if (_drawingActions.isNotEmpty) {
      setState(() {
        _undoStack.add(_drawingActions.removeLast());
      });
    }
  }

  void _redo() {
    if (_undoStack.isNotEmpty) {
      setState(() {
        _drawingActions.add(_undoStack.removeLast());
      });
    }
  }

  Future<void> _saveDrawing() async {
    final pngBytes = await saveImage(_paintKey);

    await widget.onUpdateImage(
      pngBytes,
      action: 'Drawn lines',
      operationType: 'drawing',
      parameters: {
        'count': _drawingActions.length,
      },
    );

    widget.onApply(pngBytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _isInitialized
                  ? GestureDetector(
                onPanStart: (details) => _startDrawing(details.localPosition),
                onPanUpdate: (details) => _updateDrawing(details.localPosition),
                child: RepaintBoundary(
                  key: _paintKey,
                  child: CustomPaint(
                    painter: DrawingPainter(
                      backgroundImage: _backgroundImage,
                      actions: _drawingActions,
                    ),
                    child: Container(),
                  ),
                ),
              )
                  : const Center(child: CircularProgressIndicator()),
            ),
            _buildToolbar(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() => AppBar(
    backgroundColor: Colors.black.withOpacity(0.7),
    leading: IconButton(
      icon: const Icon(Icons.close),
      onPressed: widget.onCancel,
    ),
    title: const Text('Draw'),
    actions: [
      IconButton(icon: const Icon(Icons.undo), onPressed: _undo),
      IconButton(icon: const Icon(Icons.redo), onPressed: _redo),
      IconButton(icon: const Icon(Icons.check), onPressed: _saveDrawing),
    ],
  );

  Widget _buildToolbar() => Container(
    padding: const EdgeInsets.all(8),
    color: Colors.grey[900],
    child: Row(
      children: [
        const Text('Color:', style: TextStyle(color: Colors.white)),
        const SizedBox(width: 10),
        ...[Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.white].map(
              (color) => GestureDetector(
            onTap: () => setState(() => _currentColor = color),
            child: Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Slider(
            value: _currentStrokeWidth,
            min: 1,
            max: 20,
            divisions: 19,
            onChanged: (val) => setState(() => _currentStrokeWidth = val),
          ),
        )
      ],
    ),
  );
}

class DrawingAction {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  DrawingAction(this.points, this.color, this.strokeWidth);
}

class DrawingPainter extends CustomPainter {
  final ui.Image backgroundImage;
  final List<DrawingAction> actions;

  DrawingPainter({required this.backgroundImage, required this.actions});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    canvas.drawImage(backgroundImage, Offset.zero, paint);

    for (final action in actions) {
      final paint = Paint()
        ..color = action.color
        ..strokeWidth = action.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < action.points.length - 1; i++) {
        canvas.drawLine(action.points[i], action.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}