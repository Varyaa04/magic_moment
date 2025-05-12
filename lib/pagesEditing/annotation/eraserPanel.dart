import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path/path.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as io;
import 'package:universal_html/html.dart' as html;

import 'removeBackground.dart';

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
    setState(() {
      final list = [offset];
      _isObjectRemovalMode ? _objectMaskPaths.add(list) : _eraserPaths.add(list);
    });
  }

  void _extendPath(Offset offset) {
    setState(() {
      final target = _isObjectRemovalMode ? _objectMaskPaths : _eraserPaths;
      target.last.add(offset);
    });
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
    widget.onCancel;
  }

  Future<void> _onRemoveBackgroundPressed() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = join(tempDir.path, 'eraser_temp.png');
      final file = await File(filePath).writeAsBytes(widget.image);
      final noBgFile = await removeBackground(file, 'cHoupRUPfmtWNYmiy6uu9t8Y');

      if (noBgFile != null && await noBgFile.exists()) {
        final pngBytes = await noBgFile.readAsBytes();
        await widget.onUpdateImage(
          pngBytes,
          action: 'Auto removed background',
          operationType: 'remove_bg',
          parameters: {},
        );
        widget.onApply(pngBytes);
      } else {
        ScaffoldMessenger.of(context as BuildContext).showSnackBar(
          const SnackBar(content: Text('Ошибка при удалении фона')),
        );
      }
    } catch (e) {
      debugPrint('Remove BG Error: $e');
    }
  }

  Future<void> _removeObject() async {
    final maskImage = await _generateMaskImage();
    final originalFile = await writeTempFile(widget.image, 'original.png');
    final maskFile = await writeTempFile(maskImage, 'mask.png');

    final response = await _callCleanupAPI(originalFile as File, maskFile as File);
    if (response != null) {
      await widget.onUpdateImage(
        response,
        action: 'Object removed',
        operationType: 'inpaint',
        parameters: {'paths': _objectMaskPaths.length},
      );
      widget.onApply(response);
    } else {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        const SnackBar(content: Text('Ошибка при удалении объекта')),
      );
    }
  }

  Future<Uint8List> _generateMaskImage() async {
    final mask = img.Image(width: _backgroundImage.width, height: _backgroundImage.height);
    img.fill(mask, color: img.ColorRgb8(0, 0, 0));

    for (final path in _objectMaskPaths) {
      for (final point in path) {
        img.drawCircle(
          mask,
          x: point.dx.toInt(),
          y: point.dy.toInt(),
          radius: (_strokeWidth / 2).toInt(),
          color: img.ColorRgb8(255, 255, 255),
        );
      }
    }

    return Uint8List.fromList(img.encodePng(mask));
  }

  Future<File?> writeTempFile(Uint8List bytes, String filename) async {
    if (kIsWeb) {
      // Веб: инициируем загрузку
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
      return null;
    } else {
      final dir = await getTemporaryDirectory();
      final file = File(join(dir.path, filename));
      return await file.writeAsBytes(bytes);
    }
  }


  Future<Uint8List?> _callCleanupAPI(File original, File mask) async {
    try {
      final uri = Uri.parse('https://api.replicate.com/v1/predictions');
      final headers = {
        'Authorization': 'Token r8_3bXdJUv0ltj5ecDzQMz5Sa5il2GQDHA1Orsyu',
        'Content-Type': 'application/json',
      };
      final body = jsonEncode({
        "version": "c413e5ff30c586ac26db8ecbf6ffbcdc6e378a2c4c3e28e12a6b343dddfd11f6",
        "input": {
          "image": "data:image/png;base64,${base64Encode(await original.readAsBytes())}",
          "mask": "data:image/png;base64,${base64Encode(await mask.readAsBytes())}"
        }
      });

      final response = await http.post(uri, headers: headers, body: body);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final statusUrl = json['urls']['get'];
        while (true) {
          final poll = await http.get(Uri.parse(statusUrl), headers: headers);
          final data = jsonDecode(poll.body);
          if (data['status'] == 'succeeded') {
            final imgUrl = data['output'];
            final imgResp = await http.get(Uri.parse(imgUrl));
            return imgResp.bodyBytes;
          } else if (data['status'] == 'failed') {
            break;
          }
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    } catch (e) {
      debugPrint('Cleanup API error: $e');
    }
    return null;
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Colors.black.withOpacity(0.6),
              elevation: 0,
              title: const Text(
                'Удаление объектов / Ластик',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onCancel,
              ),
              actions: [
                IconButton(icon: const Icon(Icons.undo), onPressed: _undo),
                IconButton(icon: const Icon(Icons.check), onPressed: _apply),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 60), // Отступ под AppBar
          Expanded(
            child: _isInitialized
                ? Center(
              child: GestureDetector(
                onPanStart: (d) => _startPath(d.localPosition),
                onPanUpdate: (d) => _extendPath(d.localPosition),
                child: AspectRatio(
                  aspectRatio: _backgroundImage.width / _backgroundImage.height,
                  child: RepaintBoundary(
                    key: _paintKey,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
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
                ),
              ),
            )
                : const Center(child: CircularProgressIndicator()),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 12,
                  spreadRadius: 4,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            height: 100,
            child: Row(
              children: [
                const Text('Толщина', style: TextStyle(color: Colors.white)),
                const SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    ),
                    child: Slider(
                      value: _strokeWidth,
                      min: 5,
                      max: 50,
                      activeColor: Colors.pinkAccent,
                      inactiveColor: Colors.grey[700],
                      onChanged: (val) => setState(() => _strokeWidth = val),
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Переключить режим',
                  child: IconButton(
                    icon: Icon(
                      _isObjectRemovalMode ? Icons.layers_clear : Icons.auto_fix_high,
                      color: _isObjectRemovalMode ? Colors.orangeAccent : Colors.tealAccent,
                    ),
                    onPressed: _toggleMode,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: ElevatedButton.icon(
                    key: ValueKey<bool>(_isObjectRemovalMode),
                    onPressed: _isObjectRemovalMode ? _removeObject : _onRemoveBackgroundPressed,
                    icon: Icon(
                      _isObjectRemovalMode ? Icons.cleaning_services : Icons.image_not_supported,
                      color: Colors.white,
                    ),
                    label: Text(
                      _isObjectRemovalMode ? 'Удалить объект' : 'Удалить фон',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isObjectRemovalMode ? Colors.orange : Colors.deepPurpleAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
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
    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..color = isObjectMode ? Colors.redAccent : const Color(0x00FFFFFF)
      ..blendMode = isObjectMode ? BlendMode.srcOver : BlendMode.clear;

    canvas.drawImage(backgroundImage, Offset.zero, Paint());
    final paths = isObjectMode ? objectMaskPaths : eraserPaths;
    for (final path in paths) {
      for (int i = 0; i < path.length - 1; i++) {
        canvas.drawLine(path[i], path[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
