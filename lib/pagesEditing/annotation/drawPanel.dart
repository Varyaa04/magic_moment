import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/rendering.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import '../../database/editHistory.dart';
import '../../database/objectDao.dart' as dao;
import '../../database/objectsModels.dart';
import '../../database/magicMomentDatabase.dart';

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
  _DrawPanelState createState() => _DrawPanelState();
}

class _DrawPanelState extends State<DrawPanel> {
  late ui.Image _backgroundImage;
  final List<DrawingAction> _drawingActions = [];
  final List<DrawingAction> _undoStack = [];
  final List<Map<String, dynamic>> _history = [];
  int _historyIndex = -1;
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
    _loadDrawingsFromDb();
    _history.add({
      'image': widget.image,
      'action': 'Initial image',
      'operationType': 'init',
      'parameters': {},
    });
    _historyIndex = 0;
  }

  @override
  void dispose() {
    _backgroundImage.dispose();
    super.dispose();
  }

  Future<void> _loadDrawingsFromDb() async {
    try {
      final objectDao = dao.ObjectDao();
      final drawings = await objectDao.getDrawings(widget.imageId);
      debugPrint('Loaded ${drawings.length} drawings from DB for imageId: ${widget.imageId}');

      if (!mounted) return;

      setState(() {
        for (final d in drawings) {
          try {
            final points = (jsonDecode(d.drawingPath) as List)
                .map<Offset>((p) => Offset(p['x'] as double, p['y'] as double))
                .toList();
            _drawingActions.add(DrawingAction(
              points: points,
              color: Color(int.parse(d.color.replaceFirst('#', '0xff'))),
              strokeWidth: d.strokeWidth,
              isErasing: false,
            ));
          } catch (e) {
            debugPrint('Error parsing drawing path: $e');
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading drawings from DB: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.errorLoadDrawings ?? 'Failed to load drawings: $e')),
        );
      }
    }
  }

  Future<void> _saveDrawing() async {
    try {
      final boundary = _paintingKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception(AppLocalizations.of(context)?.error ?? 'Rendering error');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose(); // Освобождаем изображение
      if (byteData == null) {
        throw Exception(AppLocalizations.of(context)?.errorEncode ?? 'Image conversion error');
      }

      final pngBytes = byteData.buffer.asUint8List();
      debugPrint('Drawing saved with ${_drawingActions.length} actions');

      final history = EditHistory(
        historyId: null,
        imageId: widget.imageId,
        operationType: 'drawing',
        operationParameters: {
          'stroke_width': _currentStrokeWidth,
          'actions_count': _drawingActions.length,
        },
        operationDate: DateTime.now(),
        snapshotPath: kIsWeb ? null : '${Directory.systemTemp.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png',
        snapshotBytes: kIsWeb ? pngBytes : null,
      );
      final db = MagicMomentDatabase.instance;
      final historyId = await db.insertHistory(history);

      final objectDao = dao.ObjectDao();
      for (final action in _drawingActions) {
        final pathJson = jsonEncode(action.points.map((p) => {'x': p.dx, 'y': p.dy}).toList());
        await objectDao.insertDrawing(Drawing(
          imageId: widget.imageId,
          drawingPath: pathJson,
          color: '#${action.color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
          strokeWidth: action.strokeWidth,
          historyId: historyId,
        ));
      }

      if (!mounted) return;

      setState(() {
        if (_historyIndex < _history.length - 1) {
          _history.removeRange(_historyIndex + 1, _history.length);
        }
        _history.add({
          'image': pngBytes,
          'action': AppLocalizations.of(context)?.draw ?? 'Draw',
          'operationType': 'drawing',
          'parameters': {
            'stroke_width': _currentStrokeWidth,
            'actions_count': _drawingActions.length,
          },
        });
        _historyIndex++;
      });

      await _updateImage(
        pngBytes,
        action: AppLocalizations.of(context)?.draw ?? 'Draw',
        operationType: 'drawing',
        parameters: {
          'stroke_width': _currentStrokeWidth,
          'actions_count': _drawingActions.length,
        },
      );

      widget.onApply(pngBytes);
    } catch (e) {
      debugPrint('Error saving drawing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.errorSaveDrawing ?? 'Error saving drawing: $e')),
        );
      }
    } finally {
      widget.onCancel();
    }
  }

  Future<void> _loadImage() async {
    try {
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(widget.image, (ui.Image img) {
        completer.complete(img);
      });
      _backgroundImage = await completer.future;
      setState(() => _isInitialized = true);
      debugPrint('Background image loaded successfully');
    } catch (e) {
      debugPrint('Error loading background image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load image: $e')),
        );
      }
    }
  }

  Future<void> _updateImage(
      Uint8List newImage, {
        required String action,
        required String operationType,
        required Map<String, dynamic> parameters,
      }) async {
    try {
      await widget.onUpdateImage(
        newImage,
        action: action,
        operationType: operationType,
        parameters: parameters,
      );
      debugPrint('Image updated: $action');
    } catch (e) {
      debugPrint('Error in onUpdateImage: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update image: $e')),
        );
      }
      rethrow;
    }
  }

  Future<void> _undo() async {
    if (_historyIndex <= 0 || _drawingActions.isEmpty) return;

    try {
      setState(() {
        _historyIndex--;
        _drawingActions.clear();
        _undoStack.clear();
        _isErasing = false;
      });

      await _updateImage(
        _history[_historyIndex]['image'],
        action: 'Undo drawing',
        operationType: 'undo',
        parameters: {
          'previous_action': _history[_historyIndex + 1]['action'],
        },
      );
      debugPrint('Undo performed, history index: $_historyIndex');
    } catch (e) {
      debugPrint('Error undoing drawing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to undo: $e')),
        );
      }
    }
  }

  void _undoLastAction() {
    if (_drawingActions.isNotEmpty) {
      setState(() {
        _undoStack.add(_drawingActions.removeLast());
      });
      debugPrint('Undo last action, remaining actions: ${_drawingActions.length}');
    }
  }

  void _redoLastAction() {
    if (_undoStack.isNotEmpty) {
      setState(() {
        _drawingActions.add(_undoStack.removeLast());
      });
      debugPrint('Redo last action, total actions: ${_drawingActions.length}');
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
    final RenderBox? renderBox = _paintingKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final Offset localPosition = renderBox.globalToLocal(details.globalPosition);
    _lastPosition = localPosition;

    setState(() {
      _drawingActions.add(DrawingAction(
        points: [localPosition],
        color: _isErasing ? Colors.transparent : _currentColor,
        strokeWidth: _currentStrokeWidth,
        isErasing: _isErasing,
      ));
      debugPrint('Pan start at: $localPosition');
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final RenderBox? renderBox = _paintingKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || _drawingActions.isEmpty) return;
    final Offset localPosition = renderBox.globalToLocal(details.globalPosition);

    setState(() {
      _drawingActions.last.points.add(localPosition);
      _lastPosition = localPosition;
      debugPrint('Pan update to: $localPosition');
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    _lastPosition = null;
    debugPrint('Pan end, total points in last action: ${_drawingActions.isNotEmpty ? _drawingActions.last.points.length : 0}');
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(localizations),
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
                  : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      localizations?.loading ?? 'Loading...',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            _buildToolbar(localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(AppLocalizations? localizations) {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: widget.onCancel,
        tooltip: localizations?.cancel ?? 'Cancel',
      ),
      title: Text(localizations?.draw ?? 'Draw', style: const TextStyle(color: Colors.white)),
      actions: [
        IconButton(
          icon: Icon(Icons.undo, color: _historyIndex > 0 ? Colors.white : Colors.grey),
          onPressed: _historyIndex > 0 ? _undo : null,
          tooltip: localizations?.undo ?? 'Undo',
        ),
        IconButton(
          icon: Icon(Icons.redo, color: _undoStack.isEmpty ? Colors.grey : Colors.white),
          onPressed: _undoStack.isEmpty ? null : _redoLastAction,
          tooltip: localizations?.redo ?? 'Redo',
        ),
        IconButton(
          icon: const Icon(Icons.check, color: Colors.white),
          onPressed: _saveDrawing,
          tooltip: localizations?.apply ?? 'Apply',
        ),
      ],
    );
  }

  Widget _buildToolbar(AppLocalizations? localizations) {
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
                _buildEraserButton(localizations),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('${localizations?.size ?? 'Size'}:', style: const TextStyle(color: Colors.white)),
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

  Widget _buildEraserButton(AppLocalizations? localizations) {
    return Tooltip(
      message: localizations?.eraser ?? 'Eraser',
      child: GestureDetector(
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
    this.isErasing = false,
  });
}