import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class DrawPanel extends StatefulWidget {
  final Uint8List image;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;

  const DrawPanel({
    required this.image,
    required this.onCancel,
    required this.onApply,
    Key? key,
  }) : super(key: key);

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
      if (_isErasing) {
        _currentColor = Colors.transparent;
      }
    });
  }

  void _handlePanStart(DragStartDetails details) {
    final RenderBox renderBox = _paintingKey.currentContext!.findRenderObject() as RenderBox;
    final Offset localPosition = renderBox.globalToLocal(details.globalPosition);

    if (!_isErasing) {
      setState(() {
        _drawingActions.add(DrawingAction(
          points: [localPosition],
          color: _currentColor,
          strokeWidth: _currentStrokeWidth,
          isErasing: false,
        ));
      });
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final RenderBox renderBox = _paintingKey.currentContext!.findRenderObject() as RenderBox;
    final Offset localPosition = renderBox.globalToLocal(details.globalPosition);

    if (!_isErasing) {
      setState(() {
        _drawingActions.last.points.add(localPosition);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
        child: Container(
          color: Colors.black.withOpacity(0.8),
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onCancel,
                ),
                title: const Text('Draw', style: TextStyle(color: Colors.white)),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.undo, color: Colors.white),
                    onPressed: _undoLastAction,
                    color: _drawingActions.isEmpty ? Colors.grey : Colors.white,
                  ),
                  IconButton(
                    icon: const Icon(Icons.redo, color: Colors.white),
                    onPressed: _redoLastAction,
                    color: _undoStack.isEmpty ? Colors.grey : Colors.white,
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.white),
                    onPressed: _saveDrawing,
                  ),
                ],
              ),
              Expanded(
                child: _isInitialized
                    ? GestureDetector(
                  onPanStart: _handlePanStart,
                  onPanUpdate: _handlePanUpdate,
                  child: CustomPaint(
                    key: _paintingKey,
                    size: Size.infinite,
                    painter: DrawingPainter(
                      backgroundImage: _backgroundImage,
                      drawingActions: _drawingActions,
                    ),
                  ),
                )
                    : const Center(child: CircularProgressIndicator()),
              ),
              // Панель инструментов для рисования
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // Выбор цвета и размера кисти
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildColorButton(Colors.red),
                        _buildColorButton(Colors.blue),
                        _buildColorButton(Colors.green),
                        _buildColorButton(Colors.yellow),
                        _buildColorButton(Colors.white),
                        _buildColorButton(Colors.black),
                        _buildColorButton(Colors.grey),
                        _buildColorButton(Colors.purple),
                        _buildColorButton(Colors.pinkAccent),
                        _buildColorButton(Colors.lightBlueAccent),
                        _buildColorButton(Colors.lightGreenAccent),
                        IconButton(
                          icon: Icon(
                            FluentIcons.eraser_20_filled,
                            color: _isErasing ? Colors.blue : Colors.white,
                          ),
                          onPressed: _toggleEraser,
                        ),
                      ],
                    ),
                    // Слайдер для размера кисти
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const Text('Size:', style: TextStyle(color: Colors.white)),
                          Expanded(
                            child: Slider(
                              value: _currentStrokeWidth,
                              min: 1,
                              max: 30,
                              activeColor: Colors.blue,
                              inactiveColor: Colors.grey,
                              onChanged: _changeStrokeWidth,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () => _changeColor(color),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _currentColor == color && !_isErasing ? Colors.blue : Colors.transparent,
            width: 2,
          ),
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
    // Рисуем фоновое изображение
    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH(0, 0, size.width, size.height),
      image: backgroundImage,
      fit: BoxFit.contain,
    );

    // Рисуем все действия пользователя
    for (final action in drawingActions) {
      final paint = Paint()
        ..color = action.color
        ..strokeWidth = action.strokeWidth
        ..strokeCap = StrokeCap.round
        ..blendMode = action.isErasing ? BlendMode.clear : BlendMode.srcOver;

      for (int i = 0; i < action.points.length - 1; i++) {
        canvas.drawLine(action.points[i], action.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
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
