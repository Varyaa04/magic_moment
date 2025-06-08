import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:MagicMoment/database/editHistory.dart';
import 'package:MagicMoment/database/magicMomentDatabase.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'package:path_provider/path_provider.dart';

class RotatePanel extends StatefulWidget {
  final Uint8List image;
  final int imageId;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;
  final Function(Uint8List,
      {String? action,
      String? operationType,
      Map<String, dynamic>? parameters}) onUpdateImage;

  const RotatePanel({
    required this.image,
    required this.imageId,
    required this.onCancel,
    required this.onApply,
    required this.onUpdateImage,
    super.key,
  });

  @override
  _RotatePanelState createState() => _RotatePanelState();
}

class _RotatePanelState extends State<RotatePanel> {
  Size _originalImageSize = Size.zero;
  bool _isProcessing = false;
  ui.Image? _uiImage;
  double _tempRotation = 0.0;
  bool _tempFlipHorizontal = false;
  bool _tempFlipVertical = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    _uiImage?.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    if (!mounted) return;
    setState(() => _isProcessing = true);
    try {
      if (widget.image.isEmpty) {
        throw Exception(AppLocalizations.of(context)?.noImages ??
            'Изображение отсутствует');
      }
      final codec = await ui.instantiateImageCodec(widget.image);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final size = Size(image.width.toDouble(), image.height.toDouble());
      if (size.width <= 0 || size.height <= 0) {
        throw Exception('Недопустимый размер изображения');
      }
      if (!mounted) {
        image.dispose();
        codec.dispose();
        return;
      }
      setState(() {
        _uiImage = image;
        _originalImageSize = size;
        _isProcessing = false;
      });
      codec.dispose();
    } catch (e, stackTrace) {
      debugPrint('Ошибка загрузки изображения: $e\n$stackTrace');
      if (mounted) {
        _showError('${AppLocalizations.of(context)?.error ?? 'Ошибка'}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Size _getRotatedSize(double rotation) {
    if (_uiImage == null) return Size.zero;

    final radians = rotation * pi / 180;
    final cosTheta = cos(radians).abs();
    final sinTheta = sin(radians).abs();

    final width = _originalImageSize.width;
    final height = _originalImageSize.height;

    final newWidth = width * cosTheta + height * sinTheta;
    final newHeight = width * sinTheta + height * cosTheta;

    return Size(newWidth, newHeight);
  }

  void _rotateImage(double degrees) {
    if (_isProcessing || _uiImage == null || !mounted) return;
    setState(() {
      _tempRotation = (_tempRotation + degrees) % 360;
      if (_tempRotation < 0) _tempRotation += 360;
    });
  }

  Future<void> _applyRotation() async {
    if (_isProcessing || _uiImage == null || !mounted) {
      debugPrint(
          'Прерывание _applyRotation: обработка или изображение недоступно');
      return;
    }
    setState(() => _isProcessing = true);
    try {
      debugPrint(
          'Применение поворота: rotation=$_tempRotation, flipH=$_tempFlipHorizontal, flipV=$_tempFlipVertical');

      final bytes = await compute(_rotateImageIsolate, {
        'imageBytes': widget.image,
        'rotation': _tempRotation,
        'flipHorizontal': _tempFlipHorizontal,
        'flipVertical': _tempFlipVertical,
      });

      if (bytes.isEmpty) {
        throw Exception('Получен пустой результат поворота');
      }

      String? snapshotPath;
      List<int>? snapshotBytes;
      if (!kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        if (!await tempDir.exists()) {
          debugPrint('Создание временной директории: ${tempDir.path}');
          await tempDir.create(recursive: true);
        }
        snapshotPath =
            '${tempDir.path}/rotate_${widget.imageId}_${DateTime.now().millisecondsSinceEpoch}.png';
        debugPrint('Сохранение файла: $snapshotPath');
        final file = File(snapshotPath);
        await file.writeAsBytes(bytes);
        if (await file.length() == 0) {
          throw Exception('Файл пуст после записи: $snapshotPath');
        }
        debugPrint('Файл успешно сохранен: ${await file.length()} байт');
      } else {
        snapshotBytes = bytes;
        if (snapshotBytes.isEmpty) {
          throw Exception('Пустой snapshotBytes на веб-платформе');
        }
      }

      final history = EditHistory(
        imageId: widget.imageId,
        operationType: 'rotate',
        operationParameters: {
          'rotation': _tempRotation,
          'flipHorizontal': _tempFlipHorizontal,
          'flipVertical': _tempFlipVertical,
        },
        operationDate: DateTime.now(),
        snapshotPath: snapshotPath,
        snapshotBytes: snapshotBytes,
      );
      final db = MagicMomentDatabase.instance;
      final historyId = await db.insertHistory(history);
      debugPrint('ID истории: $historyId');
      if (historyId == null || historyId <= 0) {
        debugPrint('Предупреждение: не удалось сохранить историю изменений');
      }

      if (!mounted) return;

      await widget.onUpdateImage(
        bytes,
        action: AppLocalizations.of(context)?.rotate ?? 'Поворот применен',
        operationType: 'rotate',
        parameters: {
          'rotation': _tempRotation,
          'flipHorizontal': _tempFlipHorizontal,
          'flipVertical': _tempFlipVertical,
          'historyId': historyId ?? -1,
        },
      );

      widget.onApply(bytes);
      if (mounted) {
        widget.onCancel();
      }
    } catch (e, stackTrace) {
      debugPrint('Ошибка поворота: $e\nСтек: $stackTrace');
      if (mounted) {
        _showError('${AppLocalizations.of(context)?.error ?? 'Ошибка'}: $e');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  static Future<Uint8List> _rotateImageIsolate(
      Map<String, dynamic> params) async {
    final imageBytes = params['imageBytes'] as Uint8List;
    final rotation = params['rotation'] as double;
    final flipHorizontal = params['flipHorizontal'] as bool;
    final flipVertical = params['flipVertical'] as bool;

    try {
      // Decode image using the image package
      final image = img.decodeImage(imageBytes)!;

      // Apply transformations
      img.Image transformed = image;

      if (flipHorizontal) {
        transformed = img.flipHorizontal(transformed);
      }

      if (flipVertical) {
        transformed = img.flipVertical(transformed);
      }

      // Apply rotation (convert to radians)
      transformed = img.copyRotate(
        transformed,
        angle: rotation,
      );

      // Encode back to PNG
      return img.encodePng(transformed);
    } catch (e) {
      debugPrint('Error in _rotateImageIsolate: $e');
      return Uint8List(0);
    }
  }

  void _flipImage({required bool horizontal}) {
    if (_isProcessing || _uiImage == null || !mounted) return;
    setState(() {
      if (horizontal) {
        _tempFlipHorizontal = !_tempFlipHorizontal;
      } else {
        _tempFlipVertical = !_tempFlipVertical;
      }
    });
  }

  void _resetChanges() {
    if (!mounted) return;
    setState(() {
      _tempRotation = 0.0;
      _tempFlipHorizontal = false;
      _tempFlipVertical = false;
    });
  }

  void _showError(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)?.errorTitle ?? 'Ошибка'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)?.ok ?? 'ОК'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onCancel();
              },
              child: Text(AppLocalizations.of(context)?.close ?? 'Закрыть'),
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
    final rotatedSize = _getRotatedSize(_tempRotation);

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.95),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(localizations, isDesktop),
                Expanded(
                  child: Center(
                    child: _uiImage == null
                        ? const CircularProgressIndicator(color: Colors.blue)
                        : Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.9,
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.7,
                            ),
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: SizedBox(
                                width: rotatedSize.width,
                                height: rotatedSize.height,
                                child: CustomPaint(
                                  painter: RotatePainter(
                                    _uiImage!,
                                    rotation: _tempRotation,
                                    flipHorizontal: _tempFlipHorizontal,
                                    flipVertical: _tempFlipVertical,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                _buildControls(localizations, isDesktop),
              ],
            ),
            if (_isProcessing)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.blue),
                      const SizedBox(height: 12),
                      Text(
                        localizations?.rotate ?? 'Обработка поворота...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
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

  Widget _buildAppBar(AppLocalizations? localizations, bool isDesktop) {
    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.7),
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.close,
          color: Colors.redAccent,
          size: isDesktop ? 28 : 24,
        ),
        onPressed: widget.onCancel,
        tooltip: localizations?.cancel ?? 'Отмена',
        padding: EdgeInsets.all(isDesktop ? 8 : 6),
      ),
      title: Text(
        localizations?.rotate ?? 'Поворот',
        style: TextStyle(
          color: Colors.white,
          fontSize: isDesktop ? 18 : 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.refresh,
            color: (_tempRotation != 0 ||
                        _tempFlipHorizontal ||
                        _tempFlipVertical) &&
                    !_isProcessing
                ? Colors.white
                : Colors.grey[400],
            size: isDesktop ? 28 : 24,
          ),
          onPressed: (_tempRotation != 0 ||
                      _tempFlipHorizontal ||
                      _tempFlipVertical) &&
                  !_isProcessing
              ? _resetChanges
              : null,
          tooltip: localizations?.reset ?? 'Сброс',
          padding: EdgeInsets.all(isDesktop ? 8 : 6),
        ),
        IconButton(
          icon: Icon(
            Icons.check_circle,
            color: _isProcessing || _uiImage == null
                ? Colors.grey[400]
                : Colors.green,
            size: isDesktop ? 28 : 24,
          ),
          onPressed: _isProcessing || _uiImage == null ? null : _applyRotation,
          tooltip: localizations?.rotate ?? 'Применить поворот',
          padding: EdgeInsets.all(isDesktop ? 8 : 6),
        ),
      ],
    );
  }

  Widget _buildControls(AppLocalizations? localizations, bool isDesktop) {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(
        vertical: isDesktop ? 8 : 6,
        horizontal: isDesktop ? 12 : 8,
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 6 : 4),
              child: GestureDetector(
                onTap: _isProcessing ? null : () => _rotateImage(90),
                child: Container(
                  width: isDesktop ? 60 : 50,
                  height: isDesktop ? 50 : 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.5), width: 1),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.rotate_90_degrees_cw,
                      color: Colors.white,
                      size: isDesktop ? 26 : 22,
                      semanticLabel: localizations?.rotateClockwise ??
                          'Поворот на 90° по часовой стрелке',
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 6 : 4),
              child: GestureDetector(
                onTap: _isProcessing ? null : () => _rotateImage(-90),
                child: Container(
                  width: isDesktop ? 60 : 50,
                  height: isDesktop ? 50 : 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.5), width: 1),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.rotate_90_degrees_ccw,
                      color: Colors.white,
                      size: isDesktop ? 26 : 22,
                      semanticLabel: localizations?.rotateCounterClockwise ??
                          'Поворот на 90° против часовой стрелки',
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 6 : 4),
              child: GestureDetector(
                onTap:
                    _isProcessing ? null : () => _flipImage(horizontal: true),
                child: Container(
                  width: isDesktop ? 60 : 50,
                  height: isDesktop ? 50 : 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.5), width: 1),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.flip,
                      color: Colors.white,
                      size: isDesktop ? 26 : 22,
                      semanticLabel: localizations?.flipHorizontal ??
                          'Отразить по горизонтали',
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 6 : 4),
              child: GestureDetector(
                onTap:
                    _isProcessing ? null : () => _flipImage(horizontal: false),
                child: Container(
                  width: isDesktop ? 60 : 50,
                  height: isDesktop ? 50 : 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.5), width: 1),
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: pi / 2,
                      child: Icon(
                        Icons.flip,
                        color: Colors.white,
                        size: isDesktop ? 26 : 22,
                        semanticLabel: localizations?.flipVertical ??
                            'Отразить по вертикали',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RotatePainter extends CustomPainter {
  final ui.Image image;
  final double rotation;
  final bool flipHorizontal;
  final bool flipVertical;

  const RotatePainter(
    this.image, {
    this.rotation = 0.0,
    this.flipHorizontal = false,
    this.flipVertical = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radians = rotation * pi / 180;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(radians);
    canvas.scale(flipHorizontal ? -1.0 : 1.0, flipVertical ? -1.0 : 1.0);
    canvas.translate(-image.width / 2, -image.height / 2);
    canvas.drawImage(image, Offset.zero, Paint());
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RotatePainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.rotation != rotation ||
      oldDelegate.flipHorizontal != flipHorizontal ||
      oldDelegate.flipVertical != flipVertical;
}
