import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';

class EraserPanel extends StatefulWidget {
  final Uint8List image;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;

  const EraserPanel({
    required this.image,
    required this.onCancel,
    required this.onApply,
    Key? key,
  }) : super(key: key);

  @override
  _EraserPanelState createState() => _EraserPanelState();
}

class _EraserPanelState extends State<EraserPanel> {
  late ui.Image _backgroundImage;
  final List<DrawingAction> _drawingActions = [];
  final List<List<DrawingAction>> _undoStack = [];
  bool _isInitialized = false;
  bool _isErasing = false;
  double _currentStrokeWidth = 20.0;
  final GlobalKey _paintingKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final codec = await ui.instantiateImageCodec(widget.image);
    final frame = await codec.getNextFrame();
    setState(() {
      _backgroundImage = frame.image;
      _isInitialized = true;
    });
  }

  void _changeStrokeWidth(double width) {
    setState(() {
      _currentStrokeWidth = width;
    });
  }

  void _handlePanStart(DragStartDetails details) {
    final renderBox =
        _paintingKey.currentContext!.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    setState(() {
      _drawingActions.add(DrawingAction(
        points: [localPosition],
        strokeWidth: _currentStrokeWidth,
        isErasing: _isErasing,
      ));
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final renderBox =
        _paintingKey.currentContext!.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    setState(() {
      if (_drawingActions.isNotEmpty) {
        _drawingActions.last.points.add(localPosition);
      }
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _undoStack.add(List.from(_drawingActions));
    });
  }

  void _undo() {
    if (_undoStack.isNotEmpty) {
      setState(() {
        _drawingActions.clear();
        _undoStack.removeLast();
        if (_undoStack.isNotEmpty) {
          _drawingActions.addAll(_undoStack.last);
        }
      });
    }
  }

  Future<void> _applyChanges() async {
    try {
      final RenderRepaintBoundary boundary = _paintingKey.currentContext!
          .findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      widget.onApply(pngBytes);
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onCancel,
                color: Colors.white,
              ),
              title: const Text('Draw'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.undo),
                  onPressed: _undo,
                  color: _drawingActions.isEmpty ? Colors.grey : Colors.white,
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _applyChanges,
                  color: Colors.white,
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
              height: 70,
              color: Colors.black.withOpacity(0.7),
              child: Column(
                children: [
                  _buildToolButton(
                    icon: FluentIcons.eraser_20_filled,
                    label: appLocalizations?.eraser ?? 'Eraser',
                    isActive: _isErasing,
                    onPressed: () => setState(() => _isErasing = true),
                  ),
                  // Слайдер для размера
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(children: [
                      const Text('Size:',
                          style: TextStyle(color: Colors.white)),
                      Expanded(
                        child: Slider(
                          value: _currentStrokeWidth,
                          min: 5,
                          max: 50,
                          divisions: 9,
                          onChanged: _changeStrokeWidth,
                          activeColor: theme.primaryColor,
                          inactiveColor: theme.disabledColor,
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 80,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.primaryColor.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? theme.primaryColor : Colors.transparent,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color:
                          isActive ? theme.primaryColor : theme.iconTheme.color,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isActive
                        ? theme.primaryColor
                        : theme.textTheme.labelSmall?.color,
                  ),
                ),
              ],
            ),
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
    // Draw background image
    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH(0, 0, size.width, size.height),
      image: backgroundImage,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    // Draw all user actions
    for (final action in drawingActions) {
      final paint = Paint()
        ..strokeWidth = action.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..blendMode = action.isErasing ? BlendMode.clear : BlendMode.srcOver;

      if (action.points.length == 1) {
        // Draw a single point if there's only one point
        canvas.drawCircle(
          action.points.first,
          action.strokeWidth / 2,
          paint,
        );
      } else {
        // Draw lines between points
        for (int i = 0; i < action.points.length - 1; i++) {
          canvas.drawLine(action.points[i], action.points[i + 1], paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DrawingAction {
  List<Offset> points;
  double strokeWidth;
  bool isErasing;

  DrawingAction({
    required this.points,
    required this.strokeWidth,
    required this.isErasing,
  });
}
