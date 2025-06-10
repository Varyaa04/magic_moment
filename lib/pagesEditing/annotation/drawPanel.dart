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
import 'package:MagicMoment/themeWidjets/colorPicker.dart';
import 'package:universal_html/html.dart' as html
    if (dart.library.io) 'dart:io';

class DrawPanel extends StatefulWidget {
  final Uint8List image;
  final int imageId;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;
  final Function(Uint8List,
      {String? action,
      String? operationType,
      Map<String, dynamic>? parameters}) onUpdateImage;

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
      debugPrint(
          'Loaded ${drawings.length} drawings from DB for imageId: ${widget.imageId}');

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
          SnackBar(
              content: Text(AppLocalizations.of(context)?.errorLoadDrawings ??
                  'Failed to load drawings: $e')),
        );
      }
    }
  }

  Future<void> _saveDrawing() async {
    try {
      final boundary = _paintingKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception(
            AppLocalizations.of(context)?.error ?? 'Rendering error');
      }
      final image = await boundary.toImage(
          pixelRatio: MediaQuery.of(context).devicePixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) {
        throw Exception(AppLocalizations.of(context)?.errorEncode ??
            'Image conversion error');
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
        snapshotBytes: kIsWeb ? pngBytes : null,
      );
      final db = MagicMomentDatabase.instance;
      final historyId = await db.insertHistory(history);

      final objectDao = dao.ObjectDao();
      for (final action in _drawingActions) {
        final pathJson = jsonEncode(
            action.points.map((p) => {'x': p.dx, 'y': p.dy}).toList());
        await objectDao.insertDrawing(Drawing(
          imageId: widget.imageId,
          drawingPath: pathJson,
          color:
              '#${action.color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
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
    } catch (e, stackTrace) {
      debugPrint('Error saving drawing: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${AppLocalizations.of(context)?.error ?? 'Error'}: $e')),
        );
      }
    }
  }

  Future<Uint8List> _cropToImageBounds(
      Uint8List inputBytes, int targetWidth, int targetHeight) async {
    try {
      if (targetWidth <= 0 || targetHeight <= 0) {
        throw Exception(
            'Invalid target dimensions: $targetWidth x $targetHeight');
      }
      final codec = await ui.instantiateImageCodec(inputBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint();
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
        paint,
      );

      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(targetWidth, targetHeight);
      final byteData =
          await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      croppedImage.dispose();
      picture.dispose();

      if (byteData == null) {
        throw Exception('Failed to encode cropped image');
      }
      return byteData.buffer.asUint8List();
    } catch (e, stackTrace) {
      debugPrint('Error cropping image: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<void> _loadImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.image);
      final frame = await codec.getNextFrame();
      _backgroundImage = frame.image;
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
      final previousImage = _history[_historyIndex]['image'] as Uint8List?;
      if (previousImage == null) {
        throw Exception('Invalid history image data');
      }
      setState(() {
        _historyIndex--;
        _drawingActions.clear();
        _undoStack.clear();
        _isErasing = false;
      });

      await _updateImage(
        previousImage,
        action: 'Undo drawing',
        operationType: 'undo',
        parameters: {
          'previous_action': _history[_historyIndex + 1]['action'],
        },
      );
      debugPrint('Undo performed, history index: $_historyIndex');
    } catch (e, stackTrace) {
      debugPrint('Error undoing drawing: $e\n$stackTrace');
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
      debugPrint(
          'Undo last action, remaining actions: ${_drawingActions.length}');
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
    final RenderBox? renderBox =
        _paintingKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final Offset localPosition =
        renderBox.globalToLocal(details.globalPosition);
    _lastPosition = localPosition;

    setState(() {
      if (_isErasing) {
        _drawingActions.add(DrawingAction(
          points: [localPosition],
          color: Colors.transparent,
          strokeWidth: _currentStrokeWidth,
          isErasing: true,
        ));
      } else {
        _drawingActions.add(DrawingAction(
          points: [localPosition],
          color: _currentColor,
          strokeWidth: _currentStrokeWidth,
          isErasing: false,
        ));
      }
      debugPrint('Pan start at: $localPosition');
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final RenderBox? renderBox =
        _paintingKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || _drawingActions.isEmpty) return;
    final Offset localPosition =
        renderBox.globalToLocal(details.globalPosition);

    setState(() {
      if (_isErasing) {
        final objectDao = dao.ObjectDao();
        for (int i = _drawingActions.length - 1; i >= 0; i--) {
          if (_drawingActions[i].isErasing) continue;
          final points = _drawingActions[i].points;
          for (final point in points) {
            if ((point - localPosition).distance < _currentStrokeWidth) {
              objectDao.softDeleteDrawing(i);
              _drawingActions.removeAt(i);
              break;
            }
          }
        }
        _drawingActions.last.points.add(localPosition);
      } else {
        _drawingActions.last.points.add(localPosition);
      }
      _lastPosition = localPosition;
      debugPrint('Pan update to: $localPosition');
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    _lastPosition = null;
    if (_drawingActions.isNotEmpty) {
      final action = _drawingActions.last;
      final pathJson =
          jsonEncode(action.points.map((p) => {'x': p.dx, 'y': p.dy}).toList());
      final objectDao = dao.ObjectDao();
      objectDao.insertDrawing(Drawing(
        imageId: widget.imageId,
        drawingPath: pathJson,
        color:
            '#${action.color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        strokeWidth: action.strokeWidth,
        historyId: _historyIndex + 1,
      ));
    }
    debugPrint(
        'Pan end, total points in last action: ${_drawingActions.isNotEmpty ? _drawingActions.last.points.length : 0}');
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600; // Assume desktop if width > 600px

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(localizations, isDesktop),
            Expanded(
              child: _isInitialized
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        final maxWidth = constraints.maxWidth;
                        final maxHeight = constraints.maxHeight;
                        final imageAspectRatio =
                            _backgroundImage.width / _backgroundImage.height;
                        double canvasWidth = maxWidth;
                        double canvasHeight = maxWidth / imageAspectRatio;

                        if (canvasHeight > maxHeight) {
                          canvasHeight = maxHeight;
                          canvasWidth = maxHeight * imageAspectRatio;
                        }

                        return Center(
                          child: GestureDetector(
                            onPanStart: _handlePanStart,
                            onPanUpdate: _handlePanUpdate,
                            onPanEnd: _handlePanEnd,
                            child: Container(
                              width: canvasWidth,
                              height: canvasHeight,
                              child: RepaintBoundary(
                                key: _paintingKey,
                                child: CustomPaint(
                                  size: Size(canvasWidth, canvasHeight),
                                  painter: DrawingPainter(
                                    backgroundImage: _backgroundImage,
                                    drawingActions: _drawingActions,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 10),
                          Text(
                            localizations?.loading ?? 'Loading...',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
            ),
            _buildToolbar(localizations, isDesktop),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(AppLocalizations? localizations, bool isDesktop) {
    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.7),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.redAccent),
        onPressed: widget.onCancel,
        tooltip: localizations?.cancel ?? 'Cancel',
      ),
      title: Text(
        localizations?.draw ?? 'Draw',
        style: TextStyle(
          color: Colors.white,
          fontSize: isDesktop ? 10 : 10,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.undo,
            color: _historyIndex > 0 ? Colors.white : Colors.grey,
            size: isDesktop ? 20 : 20,
          ),
          onPressed: _historyIndex > 0 ? _undo : null,
          tooltip: localizations?.undo ?? 'Undo',
        ),
        IconButton(
          icon: Icon(
            Icons.redo,
            color: _undoStack.isEmpty ? Colors.grey : Colors.white,
            size: isDesktop ? 22 : 22,
          ),
          onPressed: _undoStack.isEmpty ? null : _redoLastAction,
          tooltip: localizations?.redo ?? 'Redo',
        ),
        IconButton(
          icon: Icon(
            Icons.check,
            color: Colors.green,
            size: isDesktop ? 22 : 22,
          ),
          onPressed: _saveDrawing,
          tooltip: localizations?.apply ?? 'Apply',
        ),
      ],
    );
  }

  Widget _buildToolbar(AppLocalizations? localizations, bool isDesktop) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = isDesktop ? 32.0 : 24.0;
    final fontSize = isDesktop ? 14.0 : 12.0;

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 16 : 8, vertical: isDesktop ? 6 : 2),
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
        mainAxisSize:
            MainAxisSize.min, // Ensure Column takes only necessary space
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
                      padding:
                          EdgeInsets.symmetric(horizontal: isDesktop ? 6 : 4),
                      child: _buildColorButton(color, buttonSize),
                    )),
                SizedBox(width: isDesktop ? 12 : 8),
                _buildColorPickerButton(localizations, buttonSize),
                SizedBox(width: isDesktop ? 12 : 8),
                _buildEraserButton(localizations, buttonSize),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 10 : 4),
            child: Row(
              children: [
                Text(
                  '${localizations?.size ?? 'Size'}:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                  ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Slider(
                    value: _currentStrokeWidth,
                    min: 1,
                    max: 30,
                    divisions: 29,
                    activeColor: Colors.blue,
                    inactiveColor: Colors.grey.withOpacity(0.5),
                    onChanged: _changeStrokeWidth,
                    label: _currentStrokeWidth.round().toString(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color, double buttonSize) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => _changeColor(color),
        borderRadius: BorderRadius.circular(buttonSize / 2),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: _currentColor == color && !_isErasing
                  ? Colors.blue
                  : Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPickerButton(
      AppLocalizations? localizations, double buttonSize) {
    return Tooltip(
      message: localizations?.color ?? 'Color Picker',
      child: GestureDetector(
        onTap: () async {
          final color = await showDialog<Color>(
            context: context,
            builder: (context) =>
                ColorPickerDialog(initialColor: _currentColor),
          );
          if (color != null) {
            _changeColor(color);
          }
        },
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: _currentColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(
            Icons.color_lens,
            size: buttonSize * 0.6,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEraserButton(
      AppLocalizations? localizations, double buttonSize) {
    return Tooltip(
      message: localizations?.eraser ?? 'Eraser',
      child: GestureDetector(
        onTap: _toggleEraser,
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: _isErasing ? Colors.blue : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(
            FluentIcons.eraser_20_filled,
            size: buttonSize * 0.6,
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
        backgroundImage.width.toDouble(), backgroundImage.height.toDouble());
    final fittedSizes = applyBoxFit(BoxFit.contain, imageSize, size);
    final dstRect = Alignment.center.inscribe(fittedSizes.destination, rect);

    canvas.save();
    canvas.clipRect(rect);
    paintImage(
      canvas: canvas,
      rect: dstRect,
      image: backgroundImage,
      fit: BoxFit.contain,
    );

    for (final action in drawingActions) {
      if (action.isErasing) continue;
      final paint = Paint()
        ..color = action.color
        ..strokeWidth = action.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..blendMode = BlendMode.srcOver;

      for (int i = 0; i < action.points.length - 1; i++) {
        canvas.drawLine(action.points[i], action.points[i + 1], paint);
      }
    }
    canvas.restore();
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

class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;

  const ColorPickerDialog({required this.initialColor, super.key});

  @override
  _ColorPickerDialogState createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        localizations?.color ?? 'Select Color',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 250,
              height: 250,
              margin: const EdgeInsets.only(bottom: 16),
              child: ColorPicker(
                pickerColor: _selectedColor,
                onColorChanged: (color) {
                  setState(() {
                    _selectedColor = color;
                  });
                },
                enableAlpha: true,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            localizations?.cancel ?? 'Cancel',
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedColor),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(localizations?.select ?? 'Select'),
        ),
      ],
    );
  }
}
