import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:MagicMoment/database/editHistory.dart';
import 'package:MagicMoment/database/magicMomentDatabase.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'package:image/image.dart' as img;
import 'package:universal_html/html.dart' as html
    if (dart.library.io) 'dart:io';

class CropPanel extends StatefulWidget {
  final Uint8List image;
  final int imageId;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;
  final Function(Uint8List,
      {String? action,
      String? operationType,
      Map<String, dynamic>? parameters}) onUpdateImage;

  const CropPanel({
    required this.image,
    required this.imageId,
    required this.onCancel,
    required this.onApply,
    required this.onUpdateImage,
    super.key,
  });

  @override
  _CropPanelState createState() => _CropPanelState();
}

class _CropPanelState extends State<CropPanel> {
  Rect _tempCropRect = Rect.zero;
  Size _imageSize = Size.zero;
  bool _isProcessing = false;
  String _tempAspectRatio = 'Свободная форма';
  ui.Image? _uiImage;
  final List<Map<String, dynamic>> _history = [];
  int _historyIndex = -1;

  late Rect _initialCropRect;
  late String _initialAspectRatio;

  static const double _minCropSize = 10.0;

  final Map<String, double?> _aspectRatios = {
    'Свободная форма': null,
    '1:1': 1.0,
    '4:3': 4 / 3,
    '3:4': 3 / 4,
    '16:9': 16 / 9,
    '9:16': 9 / 16,
  };

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
        _imageSize = size;
        _initializeCropRect();
        _history.add({
          'image': widget.image,
          'action': AppLocalizations.of(context)?.crop ?? 'Обрезка',
          'operationType': 'init',
          'parameters': {
            'crop_rect': {
              'left': _tempCropRect.left,
              'top': _tempCropRect.top,
              'width': _tempCropRect.width,
              'height': _tempCropRect.height,
            },
            'template': _tempAspectRatio,
          },
        });
        _historyIndex = 0;
        _initialCropRect = _tempCropRect;
        _initialAspectRatio = _tempAspectRatio;
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


  void _updateCropRect(Offset delta, DragHandle handle) {
    if (!mounted) return;
    setState(() {
      final ratio = _aspectRatios[_tempAspectRatio];
      Rect newRect = _tempCropRect;

      switch (handle) {
        case DragHandle.topLeft:
          if (ratio != null) {
// Для фиксированного соотношения сторон корректируем изменение
            final newWidth = _tempCropRect.width - delta.dx;
            final newHeight = newWidth / ratio;
            newRect = Rect.fromLTWH(
              (_tempCropRect.left + delta.dx)
                  .clamp(0, _tempCropRect.right - _minCropSize),
              (_tempCropRect.top + (_tempCropRect.height - newHeight))
                  .clamp(0, _tempCropRect.bottom - _minCropSize),
              newWidth.clamp(_minCropSize, _imageSize.width),
              newHeight.clamp(_minCropSize, _imageSize.height),
            );
          } else {
// Свободная форма - обычное изменение
            newRect = Rect.fromLTRB(
              (_tempCropRect.left + delta.dx)
                  .clamp(0, _tempCropRect.right - _minCropSize),
              (_tempCropRect.top + delta.dy)
                  .clamp(0, _tempCropRect.bottom - _minCropSize),
              _tempCropRect.right,
              _tempCropRect.bottom,
            );
          }
          break;

        case DragHandle.topRight:
          if (ratio != null) {
// Для фиксированного соотношения сторон
            final newWidth = _tempCropRect.width + delta.dx;
            final newHeight = newWidth / ratio;
            newRect = Rect.fromLTRB(
              _tempCropRect.left,
              (_tempCropRect.top + (_tempCropRect.height - newHeight))
                  .clamp(0, _tempCropRect.bottom - _minCropSize),
              (_tempCropRect.right + delta.dx)
                  .clamp(_tempCropRect.left + _minCropSize, _imageSize.width),
              newHeight.clamp(_minCropSize, _imageSize.height),
            );
          } else {
// Свободная форма
            newRect = Rect.fromLTRB(
              _tempCropRect.left,
              (_tempCropRect.top + delta.dy)
                  .clamp(0, _tempCropRect.bottom - _minCropSize),
              (_tempCropRect.right + delta.dx)
                  .clamp(_tempCropRect.left + _minCropSize, _imageSize.width),
              _tempCropRect.bottom,
            );
          }
          break;

        case DragHandle.bottomLeft:
          if (ratio != null) {
// Для фиксированного соотношения сторон
            final newWidth = _tempCropRect.width - delta.dx;
            final newHeight = newWidth / ratio;
            newRect = Rect.fromLTRB(
              (_tempCropRect.left + delta.dx)
                  .clamp(0, _tempCropRect.right - _minCropSize),
              _tempCropRect.top,
              newWidth.clamp(_minCropSize, _imageSize.width),
              newHeight.clamp(_minCropSize, _imageSize.height),
            );
          } else {
// Свободная форма
            newRect = Rect.fromLTRB(
              (_tempCropRect.left + delta.dx)
                  .clamp(0, _tempCropRect.right - _minCropSize),
              _tempCropRect.top,
              _tempCropRect.right,
              (_tempCropRect.bottom + delta.dy)
                  .clamp(_tempCropRect.top + _minCropSize, _imageSize.height),
            );
          }
          break;

        case DragHandle.bottomRight:
          if (ratio != null) {
// Для фиксированного соотношения сторон
            final newWidth = _tempCropRect.width + delta.dx;
            final newHeight = newWidth / ratio;
            newRect = Rect.fromLTRB(
              _tempCropRect.left,
              _tempCropRect.top,
              (_tempCropRect.right + delta.dx)
                  .clamp(_tempCropRect.left + _minCropSize, _imageSize.width),
              newHeight.clamp(_minCropSize, _imageSize.height),
            );
          } else {
// Свободная форма
            newRect = Rect.fromLTRB(
              _tempCropRect.left,
              _tempCropRect.top,
              (_tempCropRect.right + delta.dx)
                  .clamp(_tempCropRect.left + _minCropSize, _imageSize.width),
              (_tempCropRect.bottom + delta.dy)
                  .clamp(_tempCropRect.top + _minCropSize, _imageSize.height),
            );
          }
          break;

        case DragHandle.center:
// Перемещение - всегда одинаково для всех режимов
          final newLeft = (_tempCropRect.left + delta.dx)
              .clamp(0, _imageSize.width - _tempCropRect.width);
          final newTop = (_tempCropRect.top + delta.dy)
              .clamp(0, _imageSize.height - _tempCropRect.height);
          newRect = _tempCropRect.shift(
              Offset(newLeft - _tempCropRect.left, newTop - _tempCropRect.top));
          break;
      }

      _tempCropRect = newRect;
    });
  }

// Удаляем старый метод _constrainDeltaForAspectRatio, так как он больше не нужен

  void _initializeCropRect() {
    final width = _imageSize.width * 0.8;
    final height = _imageSize.height * 0.8;
    final left = (_imageSize.width - width) / 2;
    final top = (_imageSize.height - height) / 2;

    _tempCropRect = Rect.fromLTWH(left, top, width, height);
    _applyAspectRatio(_tempAspectRatio);
  }

  void _applyAspectRatio(String aspectRatio) {
    if (!mounted || _imageSize.isEmpty) return;
    setState(() {
      _tempAspectRatio = aspectRatio;
      final ratio = _aspectRatios[aspectRatio];
      if (ratio == null) {
        debugPrint('Выбрано соотношение сторон: Свободная форма');
        return;
      }

      double newWidth = _imageSize.width * 0.8;
      double newHeight = newWidth / ratio;

      if (newHeight > _imageSize.height * 0.8) {
        newHeight = _imageSize.height * 0.8;
        newWidth = newHeight * ratio;
      }

      newWidth = newWidth.clamp(_minCropSize, _imageSize.width);
      newHeight = newHeight.clamp(_minCropSize, _imageSize.height);

      final left = (_imageSize.width - newWidth) / 2;
      final top = (_imageSize.height - newHeight) / 2;

      _tempCropRect = Rect.fromLTWH(left, top, newWidth, newHeight);

      debugPrint(
          'Применено соотношение сторон: $aspectRatio, новая область обрезки: $_tempCropRect');
    });
  }

  Future<void> _undo() async {
    if (_isProcessing || _historyIndex <= 0 || !mounted) return;
    setState(() => _isProcessing = true);
    try {
      final prevImage = _history[_historyIndex - 1]['image'] as Uint8List;
      final codec = await ui.instantiateImageCodec(prevImage);
      final frame = await codec.getNextFrame();
      final updatedImage = frame.image;
      codec.dispose();

      if (!mounted) return;

      setState(() {
        _historyIndex--;
        _tempCropRect = Rect.fromLTWH(
          _history[_historyIndex]['parameters']['crop_rect']['left'] ??
              _tempCropRect.left,
          _history[_historyIndex]['parameters']['crop_rect']['top'] ??
              _tempCropRect.top,
          _history[_historyIndex]['parameters']['crop_rect']['width'] ??
              _tempCropRect.width,
          _history[_historyIndex]['parameters']['crop_rect']['height'] ??
              _tempCropRect.height,
        );
        _tempAspectRatio = _history[_historyIndex]['parameters']['template'] ??
            _tempAspectRatio;
        _uiImage?.dispose();
        _uiImage = updatedImage;
        _imageSize =
            Size(updatedImage.width.toDouble(), updatedImage.height.toDouble());
      });

      debugPrint('Отмена выполнена, индекс истории: $_historyIndex');
    } catch (e, stackTrace) {
      debugPrint('Ошибка отмены: $e\n$stackTrace');
      if (mounted) {
        _showError(
            '${AppLocalizations.of(context)?.error ?? 'Ошибка'}: Не удалось отменить');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _applyCrop() async {
    if (_isProcessing || _uiImage == null || !mounted) return;

// Сначала быстрый предпросмотр с низким качеством
    final previewResult = await compute(_cropImageIsolate, {
      'imageBytes': widget.image,
      'cropRect': {
        'left': _tempCropRect.left,
        'top': _tempCropRect.top,
        'width': _tempCropRect.width,
        'height': _tempCropRect.height,
      },
      'quality': 0.5, // Низкое качество для предпросмотра
    });


    final fullResult = await compute(_cropImageIsolate, {
      'imageBytes': widget.image,
      'cropRect': {
        'left': _tempCropRect.left,
        'top': _tempCropRect.top,
        'width': _tempCropRect.width,
        'height': _tempCropRect.height,
      },
      'quality': 1.0, // Полное качество
    });
    setState(() => _isProcessing = true);
    try {
      final result = await compute(_cropImageIsolate, {
        'imageBytes': widget.image,
        'cropRect': {
          'left': _tempCropRect.left,
          'top': _tempCropRect.top,
          'width': _tempCropRect.width,
          'height': _tempCropRect.height,
        },
      });

      final bytes = result['bytes'] as Uint8List;
      if (bytes.isEmpty) {
        throw Exception('Обрезанное изображение пустое');
      }

      String? snapshotPath;
      List<int>? snapshotBytes;
      if (!kIsWeb) {
        final tempDir = await Directory.systemTemp.createTemp();
        snapshotPath =
            '${tempDir.path}/crop_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(snapshotPath);
        await file.writeAsBytes(bytes);
        if (!await file.exists()) {
          throw Exception('Не удалось сохранить снимок в файл: $snapshotPath');
        }
      } else {
        snapshotBytes = bytes;
      }

      final history = EditHistory(
        imageId: widget.imageId,
        operationType: 'crop',
        operationParameters: {
          'template': _tempAspectRatio,
          'aspect_ratio':
              _aspectRatios[_tempAspectRatio]?.toString() ?? 'Свободная форма',
          'crop_rect': {
            'left': _tempCropRect.left,
            'top': _tempCropRect.top,
            'width': _tempCropRect.width,
            'height': _tempCropRect.height,
          },
        },
        operationDate: DateTime.now(),
        snapshotPath: snapshotPath,
        snapshotBytes: snapshotBytes,
      );
      final db = MagicMomentDatabase.instance;
      final historyId = await db.insertHistory(history);
      if (historyId == null || historyId <= 0) {
        throw Exception('Не удалось сохранить историю изменений');
      }

      if (!mounted) return;

      setState(() {
        if (_historyIndex < _history.length - 1) {
          _history.removeRange(_historyIndex + 1, _history.length);
        }
        _history.add({
          'image': bytes,
          'action':
              AppLocalizations.of(context)?.cropApplied ?? 'Обрезка применена',
          'operationType': 'crop',
          'parameters': {
            'template': _tempAspectRatio,
            'aspect_ratio': _aspectRatios[_tempAspectRatio]?.toString() ??
                'Свободная форма',
            'crop_rect': {
              'left': _tempCropRect.left,
              'top': _tempCropRect.top,
              'width': _tempCropRect.width,
              'height': _tempCropRect.height,
            },
            'historyId': historyId,
          },
        });
        _historyIndex++;
      });

      await widget.onUpdateImage(
        bytes,
        action:
            AppLocalizations.of(context)?.cropApplied ?? 'Обрезка применена',
        operationType: 'crop',
        parameters: {
          'template': _tempAspectRatio,
          'aspect_ratio':
              _aspectRatios[_tempAspectRatio]?.toString() ?? 'Свободная форма',
          'crop_rect': {
            'left': _tempCropRect.left,
            'top': _tempCropRect.top,
            'width': _tempCropRect.width,
            'height': _tempCropRect.height,
          },
          'historyId': historyId,
        },
      );

      widget.onApply(bytes);
      widget.onCancel();
    } catch (e, stackTrace) {
      debugPrint('Ошибка обрезки: $e\n$stackTrace');
      if (mounted) {
        _showError(
            '${AppLocalizations.of(context)?.error ?? 'Ошибка'}: Не удалось применить обрезку');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  static Future<Map<String, dynamic>> _cropImageIsolate(
      Map<String, dynamic> params) async {
    final imageBytes = params['imageBytes'] as Uint8List;
    final cropRect = params['cropRect'] as Map<String, dynamic>;

    try {
      final image = img.decodeImage(imageBytes)!;

      final cropped = img.copyCrop(
        image,
        x: cropRect['left'].toInt(),
        y: cropRect['top'].toInt(),
        width: cropRect['width'].toInt(),
        height: cropRect['height'].toInt(),
      );

      final result = img.encodePng(cropped);
      return {'bytes': result};
    } catch (e) {
      debugPrint('Error in _cropImageIsolate: $e');
      return {'bytes': Uint8List(0)};
    }
  }

  void _resetChanges() {
    if (!mounted) return;
    setState(() {
      _tempCropRect = _initialCropRect;
      _tempAspectRatio = _initialAspectRatio;
    });
    widget.onCancel();
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
              onPressed: () => widget.onCancel(),
              child: Text(AppLocalizations.of(context)?.ok ?? 'ОК'),
            ),
            TextButton(
              onPressed: () {
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(theme, localizations, isDesktop),
                Expanded(
                  child: Center(
                    child: _uiImage == null
                        ? const Center(
                            child:
                                CircularProgressIndicator(color: Colors.blue),
                          )
                        : FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: _imageSize.width,
                              height: _imageSize.height,
                              child: GestureDetector(
                                onPanUpdate: (details) => _updateCropRect(
                                    details.delta, DragHandle.center),
                                child: Stack(
                                  children: [
                                    CustomPaint(
                                      painter: ImagePainter(_uiImage!),
                                    ),
                                    CustomPaint(
                                      painter: CropPainter(
                                          _tempCropRect, _imageSize),
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            left: _tempCropRect.left - 20,
                                            top: _tempCropRect.top - 20,
                                            child: GestureDetector(
                                              onPanUpdate: (details) =>
                                                  _updateCropRect(details.delta,
                                                      DragHandle.topLeft),
                                              child: _buildHandle(isDesktop),
                                            ),
                                          ),
                                          Positioned(
                                            left: _tempCropRect.right - 20,
                                            top: _tempCropRect.top - 20,
                                            child: GestureDetector(
                                              onPanUpdate: (details) =>
                                                  _updateCropRect(details.delta,
                                                      DragHandle.topRight),
                                              child: _buildHandle(isDesktop),
                                            ),
                                          ),
                                          Positioned(
                                            left: _tempCropRect.left - 20,
                                            top: _tempCropRect.bottom - 20,
                                            child: GestureDetector(
                                              onPanUpdate: (details) =>
                                                  _updateCropRect(details.delta,
                                                      DragHandle.bottomLeft),
                                              child: _buildHandle(isDesktop),
                                            ),
                                          ),
                                          Positioned(
                                            left: _tempCropRect.right - 20,
                                            top: _tempCropRect.bottom - 20,
                                            child: GestureDetector(
                                              onPanUpdate: (details) =>
                                                  _updateCropRect(details.delta,
                                                      DragHandle.bottomRight),
                                              child: _buildHandle(isDesktop),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                _buildControls(theme, localizations, isDesktop),
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
                        localizations?.processingCrop ?? 'Обработка обрезки...',
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

  Widget _buildHandle(bool isDesktop) {
    return Container(
      width: isDesktop ? 48 : 36,
      height: isDesktop ? 48 : 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: isDesktop ? 16 : 12,
          height: isDesktop ? 16 : 12,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildControls(
      ThemeData theme, AppLocalizations? localizations, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isDesktop ? 12 : 8,
        horizontal: isDesktop ? 16 : 12,
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
          children: _aspectRatios.keys.map((ratio) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 8 : 6),
              child: GestureDetector(
                onTap: _isProcessing ? null : () => _applyAspectRatio(ratio),
                child: Container(
                  width: isDesktop ? 90 : 70,
                  height: isDesktop ? 60 : 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _tempAspectRatio == ratio
                          ? Colors.blue
                          : Colors.white.withOpacity(0.5),
                      width: _tempAspectRatio == ratio ? 2.5 : 1.5,
                    ),
                    color: _tempAspectRatio == ratio
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.transparent,
                  ),
                  child: Center(
                    child: Text(
                      ratio,
                      style: TextStyle(
                        color: _tempAspectRatio == ratio
                            ? Colors.blue
                            : Colors.white,
                        fontSize: isDesktop ? 16 : 14,
                        fontWeight: _tempAspectRatio == ratio
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
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
        tooltip: localizations?.cancel ?? 'Отмена',
        padding: EdgeInsets.all(isDesktop ? 8 : 6),
      ),
      title: Text(
        localizations?.crop ?? 'Обрезка',
        style: TextStyle(
          color: Colors.white,
          fontSize: isDesktop ? 18 : 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.undo,
            color: _historyIndex > 0 && !_isProcessing
                ? Colors.white
                : Colors.grey[400],
            size: isDesktop ? 28 : 24,
          ),
          onPressed: _historyIndex > 0 && !_isProcessing ? _undo : null,
          tooltip: localizations?.undo ?? 'Отменить',
          padding: EdgeInsets.all(isDesktop ? 8 : 6),
        ),
        IconButton(
          icon: Icon(
            Icons.check,
            color: _isProcessing || _uiImage == null
                ? Colors.grey[400]
                : Colors.green,
            size: isDesktop ? 28 : 24,
          ),
          onPressed: _isProcessing || _uiImage == null ? null : _applyCrop,
          tooltip: localizations?.applyCrop ?? 'Применить обрезку',
          padding: EdgeInsets.all(isDesktop ? 8 : 6),
        ),
      ],
    );
  }
}

enum DragHandle { topLeft, topRight, bottomLeft, bottomRight, center }

class ImagePainter extends CustomPainter {
  final ui.Image image;

  const ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(image, Offset.zero, Paint());
  }

  @override
  bool shouldRepaint(covariant ImagePainter oldDelegate) =>
      oldDelegate.image != image;
}

class CropPainter extends CustomPainter {
  final Rect cropRect;
  final Size imageSize;

  CropPainter(this.cropRect, this.imageSize);

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, imageSize.width, cropRect.top),
      overlayPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, cropRect.bottom, imageSize.width,
          imageSize.height - cropRect.bottom),
      overlayPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, cropRect.top, cropRect.left, cropRect.height),
      overlayPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(cropRect.right, cropRect.top,
          imageSize.width - cropRect.right, cropRect.height),
      overlayPaint,
    );

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(cropRect, borderPaint);

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final thirdWidth = cropRect.width / 3;
    final thirdHeight = cropRect.height / 3;

    for (var i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(cropRect.left + thirdWidth * i, cropRect.top),
        Offset(cropRect.left + thirdWidth * i, cropRect.bottom),
        gridPaint,
      );
      canvas.drawLine(
        Offset(cropRect.left, cropRect.top + thirdHeight * i),
        Offset(cropRect.right, cropRect.top + thirdHeight * i),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CropPainter oldDelegate) =>
      oldDelegate.cropRect != cropRect || oldDelegate.imageSize != imageSize;
}
