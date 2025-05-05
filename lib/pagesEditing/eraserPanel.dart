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
    super.key,
  });

  @override
  _EraserPanelState createState() => _EraserPanelState();
}

class _EraserPanelState extends State<EraserPanel> {
  late ui.Image _backgroundImage;
  final List<DrawingAction> _drawingActions = [];
  final List<List<DrawingAction>> _undoStack = [];
  bool _isInitialized = false;
  bool _isProcessing = false;
  double _currentStrokeWidth = 20.0;
  final GlobalKey _paintingKey = GlobalKey();

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
        _backgroundImage = frame.image;
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error loading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid image format')),
        );
        widget.onCancel();
      }
    }
  }

  void _changeStrokeWidth(double width) {
    setState(() {
      _currentStrokeWidth = width;
    });
  }

  void _handlePanStart(DragStartDetails details) {
    final renderBox = _paintingKey.currentContext!.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    setState(() {
      _drawingActions.add(DrawingAction(
        points: [localPosition],
        strokeWidth: _currentStrokeWidth,
      ));
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final renderBox = _paintingKey.currentContext!.findRenderObject() as RenderBox;
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

  void _clearAll() {
    setState(() {
      _drawingActions.clear();
      _undoStack.clear();
    });
  }

  Future<void> _applyChanges() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      final RenderRepaintBoundary boundary =
      _paintingKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      widget.onApply(pngBytes);
    } catch (e) {
      debugPrint('Error capturing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save image')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(theme, appLocalizations),
                Expanded(
                  child: _isInitialized
                      ? GestureDetector(
                    onPanStart: _handlePanStart,
                    onPanUpdate: _handlePanUpdate,
                    onPanEnd: _handlePanEnd,
                    child: CustomPaint(
                      key: _paintingKey,
                      size: Size.infinite,
                      painter: EraserPainter(
                        backgroundImage: _backgroundImage,
                        drawingActions: _drawingActions,
                      ),
                    ),
                  )
                      : const Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
                _buildToolbar(theme, appLocalizations),
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

  Widget _buildAppBar(ThemeData theme, AppLocalizations? appLocalizations) {
    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.7),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: widget.onCancel,
        tooltip: appLocalizations?.cancel ?? 'Cancel',
      ),
      title: Text(
        appLocalizations?.eraser ?? 'Eraser',
        style: const TextStyle(color: Colors.white),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.undo, color: Colors.white),
          onPressed: _undoStack.isEmpty ? null : _undo,
          tooltip: appLocalizations?.undo ?? 'Undo',
        ),
        IconButton(
          icon: const Icon(Icons.check, color: Colors.white),
          onPressed: _isProcessing ? null : _applyChanges,
          tooltip: appLocalizations?.apply ?? 'Apply',
        ),
      ],
    );
  }

  Widget _buildToolbar(ThemeData theme, AppLocalizations? appLocalizations) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, spreadRadius: 1),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildToolButton(
                icon: FluentIcons.eraser_20_filled,
                label: appLocalizations?.eraser ?? 'Eraser',
                isActive: true,
                onPressed: () {},
              ),
              _buildToolButton(
                icon: Icons.delete_sweep,
                label: appLocalizations?.clearAll ?? 'Clear All',
                isActive: false,
                onPressed: _drawingActions.isEmpty ? null : _clearAll,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                appLocalizations?.size ?? 'Size:',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _currentStrokeWidth,
                  min: 5,
                  max: 50,
                  divisions: 9,
                  activeColor: theme.primaryColor,
                  inactiveColor: theme.disabledColor,
                  label: _currentStrokeWidth.round().toString(),
                  onChanged: _changeStrokeWidth,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback? onPressed,
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
                    color: isActive ? theme.primaryColor.withOpacity(0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? theme.primaryColor : Colors.transparent,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: isActive ? theme.primaryColor : theme.iconTheme.color,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isActive ? theme.primaryColor : theme.textTheme.labelSmall?.color,
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

class EraserPainter extends CustomPainter {
  final ui.Image backgroundImage;
  final List<DrawingAction> drawingActions;

  EraserPainter({
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

    // Draw erasing actions
    for (final action in drawingActions) {
      final paint = Paint()
        ..strokeWidth = action.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..blendMode = BlendMode.clear;

      if (action.points.length == 1) {
        // Draw a single point
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
  final List<Offset> points;
  final double strokeWidth;

  DrawingAction({
    required this.points,
    required this.strokeWidth,
  });
}