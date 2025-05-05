import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/rendering.dart';

class DrawPanel extends StatefulWidget {
  final Uint8List image;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;

  const DrawPanel({
    required this.image,
    required this.onCancel,
    required this.onApply,
    super.key,
  });

  @override
  _DrawPanelState createState() => _DrawPanelState();
}

class _DrawPanelState extends State<DrawPanel> {
  late ui.Image _backgroundImage;
  final List<DrawingAction> _drawingActions = [];
  final List<DrawingAction> _undoStack = [];
  bool _isInitialized = false;
  Color _currentColor = Colors.red;
  double _currentStrokeWidth = 5.0;
  bool _isErasing = false;
  final GlobalKey _paintingKey = GlobalKey();
  Offset? _lastPosition;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(widget.image, (ui.Image img) {
      completer.complete(img);
    });
    _backgroundImage = await completer.future;
    setState(() => _isInitialized = true);
  }

  Future<void> _saveDrawing() async {
    try {
      final RenderRepaintBoundary boundary =
      _paintingKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();
      widget.onApply(pngBytes);
    } catch (e) {
      debugPrint('Error saving image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save drawing')),
      );
    }
  }

  void _undoLastAction() {
    if (_drawingActions.isNotEmpty) {
      setState(() {
        _undoStack.add(_drawingActions.removeLast());
      });
    }
  }

  void _redoLastAction() {
    if (_undoStack.isNotEmpty) {
      setState(() {
        _drawingActions.add(_undoStack.removeLast());
      });
    }
  }

  void _changeColor(Color color) {
    setState(() {
      _currentColor = color;
      _isErasing = false;
    });
  }

  void _changeStrokeWidth(double width) {
    setState(() {
      _currentStrokeWidth = width;
    });
  }

  void _toggleEraser() {
    setState(() {
      _isErasing = !_isErasing;
    });
  }

  void _handlePanStart(DragStartDetails details) {
    final RenderBox renderBox = _paintingKey.currentContext!.findRenderObject() as RenderBox;
    final Offset localPosition = renderBox.globalToLocal(details.globalPosition);
    _lastPosition = localPosition;

    setState(() {
      _drawingActions.add(DrawingAction(
        points: [localPosition],
        color: _isErasing ? Colors.transparent : _currentColor,
        strokeWidth: _currentStrokeWidth,
        isErasing: _isErasing,
      ));
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final RenderBox renderBox = _paintingKey.currentContext!.findRenderObject() as RenderBox;
    final Offset localPosition = renderBox.globalToLocal(details.globalPosition);

    setState(() {
      _drawingActions.last.points.add(localPosition);
      _lastPosition = localPosition;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    _lastPosition = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _isInitialized
                  ? GestureDetector(
                onPanStart: _handlePanStart,
                onPanUpdate: _handlePanUpdate,
                onPanEnd: _handlePanEnd,
                child: RepaintBoundary(
                  key: _paintingKey,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: DrawingPainter(
                      backgroundImage: _backgroundImage,
                      drawingActions: _drawingActions,
                    ),
                  ),
                ),
              )
                  : const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
            _buildToolbar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.7),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: widget.onCancel,
      ),
      title: const Text('Draw', style: TextStyle(color: Colors.white)),
      actions: [
        IconButton(
          icon: Icon(Icons.undo, color: _drawingActions.isEmpty ? Colors.grey : Colors.white),
          onPressed: _drawingActions.isEmpty ? null : _undoLastAction,
        ),
        IconButton(
          icon: Icon(Icons.redo, color: _undoStack.isEmpty ? Colors.grey : Colors.white),
          onPressed: _undoStack.isEmpty ? null : _redoLastAction,
        ),
        IconButton(
          icon: const Icon(Icons.check, color: Colors.white),
          onPressed: _saveDrawing,
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ...[
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.yellow,
                  Colors.white,
                  Colors.black,
                  Colors.grey,
                  Colors.purple,
                  Colors.pinkAccent,
                  Colors.lightBlueAccent,
                  Colors.lightGreenAccent,
                ].map((color) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildColorButton(color),
                )),
                const SizedBox(width: 8),
                _buildEraserButton(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Size:', style: TextStyle(color: Colors.white)),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: _currentStrokeWidth,
                    min: 1,
                    max: 30,
                    divisions: 29,
                    activeColor: Colors.blue,
                    inactiveColor: Colors.grey.withOpacity(0.5),
                    onChanged: _changeStrokeWidth,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () => _changeColor(color),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _currentColor == color && !_isErasing ? Colors.blue : Colors.white,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildEraserButton() {
    return GestureDetector(
      onTap: _toggleEraser,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: _isErasing ? Colors.blue : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(
          FluentIcons.eraser_20_filled,
          size: 16,
          color: _isErasing ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final ui.Image backgroundImage;
  final List<DrawingAction> drawingActions;

  DrawingPainter({
    required this.backgroundImage,
    required this.drawingActions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final imageSize = Size(
      backgroundImage.width.toDouble(),
      backgroundImage.height.toDouble(),
    );
    final FittedSizes fittedSizes = applyBoxFit(BoxFit.contain, imageSize, size);
    final Rect dstRect = Alignment.center.inscribe(fittedSizes.destination, rect);

    paintImage(
      canvas: canvas,
      rect: dstRect,
      image: backgroundImage,
      fit: BoxFit.contain,
    );

    canvas.clipRect(rect);

    for (final action in drawingActions) {
      final paint = Paint()
        ..color = action.color
        ..strokeWidth = action.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..blendMode = action.isErasing ? BlendMode.clear : BlendMode.srcOver;

      for (int i = 0; i < action.points.length - 1; i++) {
        canvas.drawLine(action.points[i], action.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DrawingAction {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isErasing;

  DrawingAction({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.isErasing,
  });
}