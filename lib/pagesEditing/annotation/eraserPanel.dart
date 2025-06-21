import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../database/editHistory.dart';
import '../../database/magicMomentDatabase.dart';
import '../../pagesSettings/classesSettings/app_localizations.dart';
import '../../themeWidjets/helpTooltip.dart';

Future<Uint8List> compressImageIsolate(Map<String, dynamic> params) async {
  final imageBytes = params['bytes'] as Uint8List;
  final image = img.decodeImage(imageBytes);
  if (image == null) throw Exception('Failed to decode image');
  final resized = img.copyResize(
    image,
    width: 800,
    maintainAspect: true,
    interpolation: img.Interpolation.cubic,
  );
  final output = img.encodePng(resized, level: 1);
  if (output.isEmpty) throw Exception('Failed to encode compressed image');
  return Uint8List.fromList(output);
}

class EraserPanel extends StatefulWidget {
  final Uint8List image;
  final int imageId;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;
  final Function(Uint8List,
      {String? action,
      String? operationType,
      Map<String, dynamic>? parameters}) onUpdateImage;

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
    final imageSize = Size(
        backgroundImage.width.toDouble(), backgroundImage.height.toDouble());
    final FittedSizes fittedSizes =
        applyBoxFit(BoxFit.contain, imageSize, size);
    final Rect dstRect =
        Alignment.center.inscribe(fittedSizes.destination, Offset.zero & size);

    paintImage(
      canvas: canvas,
      rect: dstRect,
      image: backgroundImage,
      fit: BoxFit.contain,
    );

    canvas.clipRect(Offset.zero & size);

    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (isObjectMode) {
      paint.color = Colors.red.withOpacity(0.8);
      paint.blendMode = BlendMode.srcOver;
      for (final path in objectMaskPaths) {
        for (int i = 0; i < path.length - 1; i++) {
          canvas.drawLine(path[i], path[i + 1], paint);
        }
      }
    } else {
      paint.color = Colors.white.withOpacity(0.6);
      paint.blendMode = BlendMode.srcOver;
      for (final path in eraserPaths) {
        for (int i = 0; i < path.length - 1; i++) {
          canvas.drawLine(path[i], path[i + 1], paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _EraserPanelState extends State<EraserPanel> {
  ui.Image? _backgroundImage;
  final GlobalKey _paintKey = GlobalKey();
  final List<List<Offset>> _eraserPaths = [];
  final List<List<Offset>> _objectMaskPaths = [];
  final List<Map<String, dynamic>> _history = [];
  int _historyIndex = -1;
  double _strokeWidth = 20.0;
  bool _isInitialized = false;
  bool _isObjectRemovalMode = false;
  bool _isProcessing = false;
  bool _isActive = true;
  String? _errorMessage;
  String? get _clipDropApiKey => dotenv.env['CLIPDROP_API_KEY'];
  late Size _imageSize;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _isActive = false;
    _backgroundImage?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    debugPrint(
        'Initializing EraserPanel with image size: ${widget.image.length} bytes');
    if (mounted) {
      setState(() => _isProcessing = true);
    }
    try {
      if (widget.image.isEmpty) {
        throw Exception(
            AppLocalizations.of(context)?.noImages ?? 'No image provided');
      }
      await _loadImage();
      _history.add({
        'image': widget.image,
        'action': AppLocalizations.of(context)?.eraser ?? 'Initial image',
        'operationType': 'init',
        'parameters': {},
      });
      _historyIndex = 0;
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isProcessing = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Initialization error: $e\n$stackTrace');
      if (mounted) {
        _showError(e.toString());
      }
    }
  }

  Future<void> _loadImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.image);
      final frame = await codec.getNextFrame();
      _backgroundImage = frame.image;
      _imageSize = Size(_backgroundImage!.width.toDouble(),
          _backgroundImage!.height.toDouble());
      debugPrint(
          'Image loaded: ${_backgroundImage!.width}x${_backgroundImage!.height}');
      codec.dispose();
    } catch (e, stackTrace) {
      debugPrint('Error loading image: $e\n$stackTrace');
      throw Exception(AppLocalizations.of(context)?.errorLoadImage ??
          'Failed to load image: $e');
    }
  }

  Future<void> _removeObject() async {
    if (_isProcessing || !_isInitialized || _objectMaskPaths.isEmpty || !mounted) return;
    setState(() => _isProcessing = true);

    try {
      final resizedImage = await _resizeImage(widget.image, maxWidth: 1024);
      final resizedImageDecoded = img.decodeImage(resizedImage);
      if (resizedImageDecoded == null) {
        throw Exception('Failed to decode resized image');
      }
      final resizedWidth = resizedImageDecoded.width;
      final resizedHeight = resizedImageDecoded.height;

      final List<List<Map<String, double>>> serializedPaths = _objectMaskPaths
          .map((path) => path.map((offset) => {'dx': offset.dx, 'dy': offset.dy}).toList())
          .toList();

      final maskBytes = await compute(_generateMaskImageIsolate, {
        'width': resizedWidth,
        'height': resizedHeight,
        'paths': serializedPaths,
        'strokeWidth': _strokeWidth,
        'originalWidth': _imageSize.width,
        'originalHeight': _imageSize.height,
      });
      if (maskBytes.isEmpty) {
        throw Exception('Empty mask generated');
      }

      final resultBytes = await _callObjectRemovalAPI(resizedImage, maskBytes, attempt: 1);
      if (resultBytes == null || resultBytes.isEmpty) {
        throw Exception('Failed to process object removal');
      }

      final croppedBytes = await compute(_cropToImageBoundsIsolate, {
        'inputBytes': resultBytes,
        'targetWidth': _imageSize.width.toInt(),
        'targetHeight': _imageSize.height.toInt(),
      });
      if (croppedBytes.isEmpty) {
        throw Exception('Empty bytes after cropping');
      }

      String? snapshotPath;
      List<int>? snapshotBytes;
      if (!kIsWeb) {
        final tempDir = await Directory.systemTemp.createTemp();
        snapshotPath = '${tempDir.path}/object_removal_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(snapshotPath);
        await file.writeAsBytes(croppedBytes);
        if (!await file.exists()) {
          throw Exception('Failed to save snapshot to file: $snapshotPath');
        }
      } else {
        snapshotBytes = croppedBytes;
      }

      final history = EditHistory(
        imageId: widget.imageId,
        operationType: 'object_removal',
        operationParameters: {
          'strokes': _objectMaskPaths.length,
          'width': _strokeWidth,
        },
        operationDate: DateTime.now(),
        snapshotPath: snapshotPath,
        snapshotBytes: snapshotBytes,
      );
      final db = MagicMomentDatabase.instance;
      final historyId = await db.insertHistory(history);
      if (historyId == null || historyId <= 0) {
        throw Exception('Failed to save edit history');
      }

      if (!mounted) return;

      setState(() {
        if (_historyIndex < _history.length - 1) {
          _history.removeRange(_historyIndex + 1, _history.length);
        }
        _history.add({
          'image': croppedBytes,
          'action': AppLocalizations.of(context)?.objectRemoval ?? 'Object removal',
          'operationType': 'object_removal',
          'parameters': {
            'strokes': _objectMaskPaths.length,
            'width': _strokeWidth,
            'historyId': historyId,
          },
        });
        _historyIndex++;
        _objectMaskPaths.clear();
      });

      // Применяем изменения
      await _updateImage(
        newImage: croppedBytes,
        action: AppLocalizations.of(context)?.objectRemoval ?? 'Object removed',
        operationType: 'object_removal',
        parameters: {
          'strokes': _objectMaskPaths.length,
          'width': _strokeWidth,
          'historyId': historyId,
        },
      );

      // Вызываем onApply
      widget.onApply(croppedBytes);

      // Корректный переход: закрываем панель после успешного применения
      if (mounted) {
        _isActive = false; // Предотвращаем дальнейшие обновления
        debugPrint('Navigating back from EraserPanel after object removal');
        widget.onCancel(); // Закрываем панель
      }
    } catch (e, stackTrace) {
      debugPrint('Object removal error: $e\n$stackTrace');
      if (mounted) {
        _showError('${AppLocalizations.of(context)?.error ?? 'Error'}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<Uint8List> _resizeImage(Uint8List imageBytes,
      {int maxWidth = 1024}) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image for resizing');
    }
    if (image.width <= maxWidth) return imageBytes;
    final resized = img.copyResize(
      image,
      width: maxWidth,
      maintainAspect: true,
      interpolation: img.Interpolation.cubic,
    );
    final resizedBytes = img.encodePng(resized, level: 1);
    return Uint8List.fromList(resizedBytes);
  }

  static Future<Uint8List> _cropToImageBoundsIsolate(
      Map<String, dynamic> params) async {
    final inputBytes = params['inputBytes'] as Uint8List;
    final targetWidth = params['targetWidth'] as int;
    final targetHeight = params['targetHeight'] as int;

    final image = img.decodeImage(inputBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    debugPrint('Before crop: ${image.width}x${image.height}');

    final resized = img.copyResize(
      image,
      width: targetWidth,
      height: targetHeight,
      maintainAspect: true,
      interpolation: img.Interpolation.cubic,
    );

    final xOffset =
        ((resized.width - targetWidth) / 2).round().clamp(0, resized.width);
    final yOffset =
        ((resized.height - targetHeight) / 2).round().clamp(0, resized.height);
    final cropWidth = targetWidth.clamp(0, resized.width - xOffset);
    final cropHeight = targetHeight.clamp(0, resized.height - yOffset);

    final cropped = img.copyCrop(
      resized,
      x: xOffset,
      y: yOffset,
      width: cropWidth,
      height: cropHeight,
    );

    debugPrint('After crop: ${cropped.width}x${cropped.height}');

    final outputBytes = img.encodePng(cropped, level: 1);
    if (outputBytes.isEmpty) {
      throw Exception('Failed to encode cropped image');
    }
    return Uint8List.fromList(outputBytes);
  }

  static Future<Uint8List> _generateMaskImageIsolate(
      Map<String, dynamic> params) async {
    final width = params['width'] as int;
    final height = params['height'] as int;
    final paths =
        params['paths'] as List<List<Map<String, double>>>;
    final strokeWidth = params['strokeWidth'] as double;
    final originalWidth = params['originalWidth'] as double;
    final originalHeight = params['originalHeight'] as double;

    final mask = img.Image(width: width, height: height);

// Инициализация маски черным цветом
    for (int y = 0; y < mask.height; y++) {
      for (int x = 0; x < mask.width; x++) {
        mask.setPixel(x, y, img.ColorRgb8(0, 0, 0));
      }
    }

// Масштабирование путей под новые размеры
    final scaleX = width / originalWidth;
    final scaleY = height / originalHeight;
    final scaledStrokeWidth = strokeWidth * scaleX;

    for (final path in paths) {
      for (int i = 0; i < path.length - 1; i++) {
        final point1 = path[i];
        final point2 = path[i + 1];

        img.drawLine(
          mask,
          x1: (point1['dx']! * scaleX).toInt().clamp(0, mask.width - 1),
          y1: (point1['dy']! * scaleY).toInt().clamp(0, mask.height - 1),
          x2: (point2['dx']! * scaleX).toInt().clamp(0, mask.width - 1),
          y2: (point2['dy']! * scaleY).toInt().clamp(0, mask.height - 1),
          color: img.ColorRgb8(255, 255, 255),
          thickness: scaledStrokeWidth.round(),
          antialias: true,
        );
      }
    }

    final maskBytes = img.encodePng(mask, level: 1);
    if (maskBytes.isEmpty) {
      throw Exception('Не удалось закодировать маску');
    }
    debugPrint('Маска создана, размер: ${maskBytes.length} байт');
    return Uint8List.fromList(maskBytes);
  }

  Future<Uint8List?> _callObjectRemovalAPI(
      Uint8List imageBytes, Uint8List maskBytes,
      {int attempt = 1, int maxAttempts = 3}) async {
    try {
      final imageDecoded = img.decodeImage(imageBytes);
      final maskDecoded = img.decodeImage(maskBytes);
      if (imageDecoded == null || maskDecoded == null) {
        throw Exception('Failed to decode image or mask for validation');
      }
      if (imageDecoded.width != maskDecoded.width ||
          imageDecoded.height != maskDecoded.height) {
        throw Exception(
            'Image (${imageDecoded.width}x${imageDecoded.height}) and mask (${maskDecoded.width}x${maskDecoded.height}) dimensions do not match');
      }

      final apiKey = _clipDropApiKey;
      if (apiKey == null || apiKey.isEmpty) {
        debugPrint('API key is missing or empty');
        throw Exception('ClipDrop API key not configured in .env file');
      }
      final uri = Uri.parse('https://clipdrop-api.co/cleanup/v1');
      final request = http.MultipartRequest('POST', uri)
        ..headers['x-api-key'] = apiKey
        ..files.add(http.MultipartFile.fromBytes('image_file', imageBytes,
            filename: 'image.png'))
        ..files.add(http.MultipartFile.fromBytes('mask_file', maskBytes,
            filename: 'mask.png'));

      debugPrint('Sending request to ClipDrop API (attempt $attempt)...');
      debugPrint('Image size: ${imageBytes.length} bytes');
      debugPrint('Mask size: ${maskBytes.length} bytes');

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('API response status: ${response.statusCode}');
      debugPrint('Response headers: ${response.headers}');
      debugPrint('Response body length: ${response.bodyBytes.length}');

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        if (bytes.isEmpty) {
          debugPrint('Empty response from ClipDrop API');
          throw Exception('Empty response from ClipDrop API');
        }
        final decodedImage = img.decodeImage(bytes);
        if (decodedImage == null) {
          debugPrint('Invalid image data from ClipDrop API');
          throw Exception('Invalid image data returned from ClipDrop API');
        }
        debugPrint('API result received, size: ${bytes.length} bytes');
        return bytes;
      } else if (response.statusCode == 429 && attempt < maxAttempts) {
        debugPrint('Rate limit hit, retrying after ${attempt * 2} seconds...');
        await Future.delayed(Duration(seconds: attempt * 2));
        return _callObjectRemovalAPI(imageBytes, maskBytes,
            attempt: attempt + 1, maxAttempts: maxAttempts);
      } else {
        debugPrint('API error: ${response.statusCode} - ${response.body}');
        throw Exception(
            'ClipDrop API error: ${response.statusCode}: ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('ClipDrop API error (attempt $attempt): $e\n$stackTrace');
      if (attempt < maxAttempts) {
        debugPrint('Retrying after ${attempt * 2} seconds...');
        await Future.delayed(Duration(seconds: attempt * 2));
        return _callObjectRemovalAPI(imageBytes, maskBytes,
            attempt: attempt + 1, maxAttempts: maxAttempts);
      }
      throw Exception('Failed to remove object: $e');
    }
  }

  Future<void> _applyEraser() async {
    if (_isProcessing || !_isInitialized || _eraserPaths.isEmpty || !mounted) return;
    setState(() => _isProcessing = true);

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, _imageSize.width, _imageSize.height));
      canvas.drawPaint(Paint()..color = Colors.transparent);
      if (_backgroundImage == null) {
        throw Exception('Background image is null');
      }
      canvas.drawImage(_backgroundImage!, Offset.zero, Paint());

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

      final picture = recorder.endRecording();
      final imgFinal = await picture.toImage(_imageSize.width.toInt(), _imageSize.height.toInt());
      final byteData = await imgFinal.toByteData(format: ui.ImageByteFormat.png);
      imgFinal.dispose();
      picture.dispose();

      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }

      final pngBytes = byteData.buffer.asUint8List();
      if (pngBytes.isEmpty) {
        throw Exception('Empty image bytes');
      }

      String? snapshotPath;
      List<int>? snapshotBytes;
      if (!kIsWeb) {
        final tempDir = await Directory.systemTemp.createTemp();
        snapshotPath = '${tempDir.path}/eraser_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(snapshotPath);
        await file.writeAsBytes(pngBytes);
        if (!await file.exists()) {
          throw Exception('Failed to save snapshot to file: $snapshotPath');
        }
      } else {
        snapshotBytes = pngBytes;
      }

      final history = EditHistory(
        imageId: widget.imageId,
        operationType: 'eraser',
        operationParameters: {
          'strokes': _eraserPaths.length,
          'width': _strokeWidth,
        },
        operationDate: DateTime.now(),
        snapshotPath: snapshotPath,
        snapshotBytes: snapshotBytes,
      );
      final db = MagicMomentDatabase.instance;
      final historyId = await db.insertHistory(history);
      if (historyId == null || historyId <= 0) {
        throw Exception('Failed to save edit history');
      }

      if (!mounted) return;

      setState(() {
        if (_historyIndex < _history.length - 1) {
          _history.removeRange(_historyIndex + 1, _history.length);
        }
        _history.add({
          'image': pngBytes,
          'action': AppLocalizations.of(context)?.eraser ?? 'Eraser',
          'operationType': 'eraser',
          'parameters': {
            'strokes': _eraserPaths.length,
            'width': _strokeWidth,
            'historyId': historyId,
          },
        });
        _historyIndex++;
        _eraserPaths.clear();
      });

      // Применяем изменения
      await _updateImage(
        newImage: pngBytes,
        action: AppLocalizations.of(context)?.eraser ?? 'Area erased',
        operationType: 'eraser',
        parameters: {
          'strokes': _eraserPaths.length,
          'width': _strokeWidth,
          'historyId': historyId,
        },
      );

      // Вызываем onApply
      widget.onApply(pngBytes);

      if (mounted) {
        _isActive = false; // Предотвращаем дальнейшие обновления
        debugPrint('Navigating back from EraserPanel after eraser application');
        widget.onCancel(); // Закрываем панель
      }
    } catch (e, stackTrace) {
      debugPrint('Eraser application error: $e\n$stackTrace');
      if (mounted) {
        _showError('${AppLocalizations.of(context)?.error ?? 'Error'}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _startPath(Offset offset) {
    final RenderBox? box =
        _paintKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localPosition = _normalizeOffset(offset, box);
    final list = [localPosition];
    if (mounted) {
      setState(() {
        if (_isObjectRemovalMode) {
          _objectMaskPaths.add(list);
        } else {
          _eraserPaths.add(list);
        }
      });
    }
  }

  void _extendPath(Offset offset) {
    final RenderBox? box =
        _paintKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localPosition = _normalizeOffset(offset, box);
    final target = _isObjectRemovalMode ? _objectMaskPaths : _eraserPaths;
    if (mounted) {
      setState(() {
        target.last.add(localPosition);
      });
    }
  }

  Offset _normalizeOffset(Offset globalOffset, RenderBox box) {
    final localOffset = box.globalToLocal(globalOffset);
    final fittedSizes = applyBoxFit(BoxFit.contain, _imageSize, box.size);
    final dstRect = Alignment.center
        .inscribe(fittedSizes.destination, Offset.zero & box.size);

    final scaleX = _imageSize.width / dstRect.width;
    final scaleY = _imageSize.height / dstRect.height;
    final normalizedX = (localOffset.dx - dstRect.left) * scaleX;
    final normalizedY = (localOffset.dy - dstRect.top) * scaleY;

    return Offset(
      normalizedX.clamp(0, _imageSize.width),
      normalizedY.clamp(0, _imageSize.height),
    );
  }

  Future<void> _undo() async {
    if (_historyIndex <= 0 || _isProcessing || !_isInitialized) return;
    if (mounted) {
      setState(() => _isProcessing = true);
    }

    try {
      final previousImage = _history[_historyIndex - 1]['image'] as Uint8List?;
      if (previousImage == null || previousImage.isEmpty) {
        throw Exception('Invalid history data');
      }

      final codec = await ui.instantiateImageCodec(previousImage);
      final frame = await codec.getNextFrame();
      final newImage = frame.image;
      codec.dispose();

      if (!mounted) return;

      setState(() {
        _historyIndex--;
        _eraserPaths.clear();
        _objectMaskPaths.clear();
        _backgroundImage?.dispose();
        _backgroundImage = newImage;
        _imageSize =
            Size(newImage.width.toDouble(), newImage.height.toDouble());
      });

      await _updateImage(
        newImage: previousImage,
        action: AppLocalizations.of(context)?.undo ?? 'Undo',
        operationType: 'undo',
        parameters: {
          'previous_action': _history[_historyIndex + 1]['action'],
        },
      );
      debugPrint('Undo performed, history index: $_historyIndex');
    } catch (e, stackTrace) {
      debugPrint('Undo error: $e\n$stackTrace');
      if (mounted) {
        _showError(
            '${AppLocalizations.of(context)?.error ?? 'Error'}: Failed to undo');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _resetChanges() {
    if (!mounted) return;
    setState(() {
      _eraserPaths.clear();
      _objectMaskPaths.clear();
      _strokeWidth = 20.0;
      _isObjectRemovalMode = false;
      _isActive = false;
    });
    debugPrint('Navigating back from EraserPanel via resetChanges');
    widget.onCancel();
  }

  void _setEraserMode() {
    if (mounted) {
      setState(() {
        _isObjectRemovalMode = false;
        _objectMaskPaths.clear();
      });
    }
  }

  void _setObjectRemovalMode() {
    if (mounted) {
      setState(() {
        _isObjectRemovalMode = true;
        _eraserPaths.clear();
      });
    }
  }

  Future<Uint8List> _applyMaskToImage(
      Uint8List imageBytes, Uint8List maskBytes) async {
    try {
      final original = img.decodeImage(imageBytes);
      final mask = img.decodeImage(maskBytes);

      if (original == null || mask == null) {
        throw Exception('Failed to decode images');
      }

      if (original.width != mask.width || original.height != mask.height) {
        throw Exception('Image and mask dimensions mismatch');
      }

      final result = img.Image(width: original.width, height: original.height);

      for (int y = 0; y < original.height; y++) {
        for (int x = 0; x < original.width; x++) {
          final maskPixel = mask.getPixel(x, y);
          if (maskPixel.r > 128) {
            result.setPixel(x, y, original.getPixel(x, y));
          } else {
            result.setPixel(x, y, img.ColorRgba8(0, 0, 0, 0));
          }
        }
      }

      final output = img.encodePng(result, level: 1);
      if (output.isEmpty) {
        throw Exception('Failed to encode resulting image');
      }
      return Uint8List.fromList(output);
    } catch (e, stackTrace) {
      debugPrint('Mask application error: $e\n$stackTrace');
      throw Exception('Failed to apply mask: $e');
    }
  }

  Future<void> _updateImage({
    required Uint8List newImage,
    required String action,
    required String operationType,
    required Map<String, dynamic> parameters,
  }) async {
    try {
      if (newImage.isEmpty) {
        throw Exception('Empty image bytes');
      }
      if (mounted && _isActive) {
        await widget.onUpdateImage(
          newImage,
          action: action,
          operationType: operationType,
          parameters: parameters,
        );
        debugPrint('Image updated: $action, size: ${newImage.length} bytes');
      } else {
        debugPrint(
            'Skipped _updateImage: panel is inactive or disposed, action: $action');
      }
    } catch (e, stackTrace) {
      debugPrint('Image update error: $e\n$stackTrace');
      if (mounted) {
        _showError(
            '${AppLocalizations.of(context)?.error ?? 'Error'}: Failed to update image');
      }
      rethrow;
    }
  }

  void _showError(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)?.errorTitle ?? 'Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)?.ok ?? 'OK'),
            ),
            TextButton(
              onPressed: () {
                widget.onCancel();
              },
              child: Text(AppLocalizations.of(context)?.close ?? 'Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final theme = Theme.of(context);

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black.withOpacity(0.8),
        body: SafeArea(
          child: Center(
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
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black.withOpacity(0.8),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _resetChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    localizations?.close ?? 'Close',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(theme, localizations, isDesktop),
                Expanded(
                  child: _backgroundImage == null
                      ? Center(
                          child: Text(
                            localizations?.invalidImage ??
                                'Failed to load image',
                            style: const TextStyle(color: Colors.white),
                          ),
                        )
                      : GestureDetector(
                          onPanStart: (details) =>
                              _startPath(details.globalPosition),
                          onPanUpdate: (details) =>
                              _extendPath(details.globalPosition),
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: RepaintBoundary(
                              key: _paintKey,
                              child: CustomPaint(
                                size: _imageSize,
                                painter: _EraserPainter(
                                  backgroundImage: _backgroundImage!,
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
                _buildBottomPanel(theme, localizations, isDesktop),
              ],
            ),
            if (_isProcessing)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        localizations?.loading ?? 'Processing...',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(
      ThemeData theme, AppLocalizations? localizations, bool isDesktop) {
    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.7),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close,
            color: Colors.redAccent, size: isDesktop ? 28 : 24),
        onPressed: _resetChanges,
        tooltip: localizations?.cancel ?? 'Cancel',
      ),
      title: Text(
        localizations?.eraser ?? 'Eraser',
        style: TextStyle(
          color: Colors.white,
          fontSize: isDesktop ? 18 : 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      actions: [
        HelpTooltip(
          message: localizations?.eraserHelp ??
              'Two modes available:\n'
                  '1. Eraser - removes parts of the image\n'
                  '2. Object Removal - AI-powered object removal\n\n'
                  'Adjust brush size with the slider.\n'
                  'Press Apply when finished.',
          iconSize: isDesktop ? 28 : 24,
        ),
        IconButton(
          icon: Icon(
            Icons.check,
            color: _isProcessing || !_isInitialized
                ? Colors.grey[400]
                : Colors.green,
            size: isDesktop ? 28 : 24,
          ),
          onPressed: _isProcessing || !_isInitialized
              ? null
              : (_isObjectRemovalMode ? _removeObject : _applyEraser),
          tooltip: localizations?.apply ?? 'Apply',
        ),
      ],
    );
  }

  Widget _buildBottomPanel(
      ThemeData theme, AppLocalizations? localizations, bool isDesktop) {
    return Container(
      height: isDesktop ? 120 : 100,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 16,
        vertical: isDesktop ? 12 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${localizations?.size ?? 'Size'}:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isDesktop ? 14 : 12,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: _strokeWidth,
                    min: 5,
                    max: isDesktop ? 100 : 50,
                    divisions: isDesktop ? 95 : 45,
                    activeColor: Colors.blue,
                    inactiveColor: Colors.grey[700],
                    label: _strokeWidth.round().toString(),
                    onChanged: _isProcessing
                        ? null
                        : (value) {
                            if (mounted) {
                              setState(() => _strokeWidth = value);
                            }
                          },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildModeButton(
                    icon: Icons.brush,
                    label: localizations?.eraser ?? 'Eraser',
                    isActive: !_isObjectRemovalMode,
                    onTap: _setEraserMode,
                    isDesktop: isDesktop,
                  ),
                ),
                Expanded(
                  child: _buildModeButton(
                    icon: Icons.auto_fix_high,
                    label: localizations?.removeObject ?? 'Object Removal',
                    isActive: _isObjectRemovalMode,
                    onTap: _setObjectRemovalMode,
                    isDesktopPadding: true,
                    isDesktop: isDesktop,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDesktop,
    bool isDesktopPadding = false,
  }) {
    return GestureDetector(
      onTap: _isProcessing ? null : onTap,
      child: Container(
        margin: isDesktopPadding
            ? EdgeInsets.only(left: isDesktop ? 8.0 : 4.0)
            : EdgeInsets.zero,
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 16 : 8,
          vertical: isDesktop ? 8 : 6,
        ),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.withOpacity(0.7) : Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey[400],
              size: isDesktop ? 24 : 16,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey[400],
                  fontSize: isDesktop ? 14 : 10,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
