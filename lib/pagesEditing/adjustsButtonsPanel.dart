import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:MagicMoment/database/editHistory.dart';
import 'package:MagicMoment/database/magicMomentDatabase.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import '../themeWidjets/sliderAdjusts.dart';

class AdjustPanel extends StatefulWidget {
  final Uint8List image;
  final int imageId;
  final Function(Uint8List, Map<String, dynamic>) onImageChanged;
  final VoidCallback onClose;
  final Function(Uint8List,
      {String? action,
      String? operationType,
      Map<String, dynamic>? parameters})? onUpdateImage;

  const AdjustPanel({
    required this.image,
    required this.imageId,
    required this.onImageChanged,
    required this.onClose,
    this.onUpdateImage,
    super.key,
  });

  @override
  State<AdjustPanel> createState() => _AdjustPanelState();
}

class _AdjustPanelState extends State<AdjustPanel> {
  late img.Image _originalImage;
  img.Image? _currentImage;
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  double _exposure = 0.0;
  double _noise = 0.0;
  double _smooth = 0.0;
  bool _isProcessing = false;
  bool _isInitialized = false;
  String? _errorMessage;
  final _adjustmentCache = <String, Uint8List>{};
  static const _previewWidth = 300;
  static const _maxCacheSize = 5;
  Uint8List? _previewImageBytes;
  StreamController<Map<String, dynamic>>? _imageStreamController;

  @override
  void initState() {
    super.initState();
    _imageStreamController = StreamController<Map<String, dynamic>>.broadcast();
    _initializeImage();
    _listenToImageUpdates();
  }

  @override
  void dispose() {
    _adjustmentCache.clear();
    _imageStreamController?.close();
    debugPrint('Disposing AdjustPanel');
    super.dispose();
  }

  Future<void> _initializeImage() async {
    if (widget.image.isEmpty) {
      _handleError('Входное изображение пустое');
      return;
    }

    try {
      final decodedImage = await compute(_decodeAndResizeImage, {
        'bytes': widget.image,
        'width': _previewWidth,
      });

      if (decodedImage == null) {
        throw Exception('Не удалось декодировать изображение');
      }

      if (!mounted) return;

      setState(() {
        _originalImage = decodedImage;
        _currentImage = decodedImage;
        _previewImageBytes = widget.image;
        _isInitialized = true;
      });

      widget.onImageChanged(widget.image, _getParameters());
    } catch (e, stackTrace) {
      debugPrint('Ошибка инициализации изображения: $e\n$stackTrace');
      _handleError('Не удалось загрузить изображение: ${e.toString()}');
    }
  }

  static img.Image? _decodeAndResizeImage(Map<String, dynamic> params) {
    try {
      final bytes = params['bytes'] as Uint8List;
      final width = params['width'] as int;
      final image = img.decodeImage(bytes);
      if (image == null) return null;
      return img.copyResize(image,
          width: width, interpolation: img.Interpolation.linear);
    } catch (e) {
      debugPrint('Ошибка декодирования: $e');
      return null;
    }
  }

  void _listenToImageUpdates() {
    _imageStreamController?.stream.listen((params) async {
      if (!_isInitialized || _currentImage == null) return;

      final cacheKey =
          '${_brightness.toStringAsFixed(2)}|${_contrast.toStringAsFixed(2)}|'
          '${_saturation.toStringAsFixed(2)}|${_exposure.toStringAsFixed(2)}|'
          '${_noise.toStringAsFixed(2)}|${_smooth.toStringAsFixed(2)}';

      if (_adjustmentCache.containsKey(cacheKey)) {
        final cachedBytes = _adjustmentCache[cacheKey]!;
        if (mounted) {
          setState(() {
            _previewImageBytes = cachedBytes;
          });
        }
        widget.onImageChanged(cachedBytes, params);
        return;
      }

      setState(() => _isProcessing = true);

      try {
        final result = await compute(_processImage, {
          'image': _originalImage,
          'brightness': _brightness,
          'contrast': _contrast,
          'saturation': _saturation,
          'exposure': _exposure,
          'noise': _noise,
          'smooth': _smooth,
          'seed': DateTime.now().millisecondsSinceEpoch,
        }).timeout(const Duration(seconds: 3));

        final bytes = img.encodePng(result);
        if (bytes.isEmpty) {
          throw Exception('Ошибка кодирования изображения');
        }

        if (_adjustmentCache.length >= _maxCacheSize) {
          _adjustmentCache.remove(_adjustmentCache.keys.first);
        }
        _adjustmentCache[cacheKey] = bytes;

        if (!mounted) return;

        setState(() {
          _currentImage = result;
          _previewImageBytes = bytes;
        });
        widget.onImageChanged(bytes, params);
      } catch (e, stackTrace) {
        debugPrint('Ошибка применения изменений: $e\n$stackTrace');
        _handleError('Ошибка настройки: ${e.toString()}');
        widget.onImageChanged(widget.image, params);
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    });
  }

  void _applyAdjustments() {
    if (!_isInitialized) return;
    _imageStreamController?.add(_getParameters());
  }

  Map<String, dynamic> _getParameters() {
    return {
      'brightness': _brightness,
      'contrast': _contrast,
      'saturation': _saturation,
      'exposure': _exposure,
      'noise': _noise,
      'smooth': _smooth,
    };
  }

  bool _hasChanges() {
    return _brightness != 0.0 ||
        _contrast != 1.0 ||
        _saturation != 1.0 ||
        _exposure != 0.0 ||
        _noise != 0.0 ||
        _smooth != 0.0;
  }

  Future<void> _applyFinal() async {
    if (!_isInitialized || _isProcessing || !_hasChanges()) {
      widget.onClose();
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final fullImage = img.decodeImage(widget.image);
      if (fullImage == null) {
        throw Exception('Не удалось декодировать изображение');
      }

      final result = await compute(_processImage, {
        'image': fullImage,
        'brightness': _brightness,
        'contrast': _contrast,
        'saturation': _saturation,
        'exposure': _exposure,
        'noise': _noise,
        'smooth': _smooth,
        'seed': DateTime.now().microsecondsSinceEpoch,
      }).timeout(const Duration(seconds: 5));

      final bytes = img.encodePng(result);
      if (bytes.isEmpty) {
        throw Exception('Не удалось закодировать финальное изображение');
      }

      String? snapshotPath;
      List<int>? snapshotBytes;
      if (!kIsWeb) {
        final tempDir = await Directory.systemTemp.createTemp();
        snapshotPath =
        '${tempDir.path}/adjust_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(snapshotPath);
        await file.writeAsBytes(bytes);
      } else {
        snapshotBytes = bytes;
      }

      final history = EditHistory(
        imageId: widget.imageId,
        operationType: 'adjustments',
        operationParameters: _getParameters(),
        operationDate: DateTime.now(),
        snapshotPath: snapshotPath,
        snapshotBytes: snapshotBytes,
      );
      final db = MagicMomentDatabase.instance;
      final historyId = await db.insertHistory(history);

      if (!mounted) return;

      await widget.onUpdateImage?.call(
        bytes,
        action: AppLocalizations.of(context)?.adjust ?? 'Настройки',
        operationType: 'adjustments',
        parameters: {
          ..._getParameters(),
          'historyId': historyId,
        },
      );

      widget.onImageChanged(bytes, _getParameters());
      widget.onClose();
    } catch (e, stackTrace) {
      debugPrint('Ошибка применения финальных изменений: $e\n$stackTrace');
      _handleError('Ошибка финальной обработки: ${e.toString()}');
      widget.onImageChanged(widget.image, _getParameters());
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _reset() {
    if (!_isInitialized || !mounted) {
      debugPrint('Cannot reset: not initialized or widget disposed');
      return;
    }

    setState(() {
      _brightness = 0.0;
      _contrast = 1.0;
      _saturation = 1.0;
      _exposure = 0.0;
      _noise = 0.0;
      _smooth = 0.0;
      _currentImage = _originalImage.clone(); // Обеспечить свежую копию
      _previewImageBytes = widget.image; // Вернуться к исходным байтам изображения
      _adjustmentCache.clear(); // Очистить кэш, чтобы избежать устаревших изображений
    });

    debugPrint('Reset adjustments: brightness=$_brightness, contrast=$_contrast, '
        'saturation=$_saturation, exposure=$_exposure, noise=$_noise, smooth=$_smooth');

    _applyAdjustments(); // Запустить обновление изображения для отражения сброса
    widget.onImageChanged(widget.image, _getParameters());
  }

  void _autoCorrect() {
    final image = _originalImage;
    final histogram = List<int>.filled(256, 0);
    int totalLuma = 0;
    int pixelCount = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luma =
        (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b).round();
        histogram[luma]++;
        totalLuma += luma;
        pixelCount++;
      }
    }

    final avgLuma = totalLuma / pixelCount;
    final minLuma = histogram.indexWhere((v) => v > 0);
    final maxLuma = histogram.lastIndexWhere((v) => v > 0);

    setState(() {
      _brightness = (128.0 - avgLuma) / 100.0;
      _contrast = (maxLuma >= minLuma && maxLuma - minLuma < 100.0)
          ? 1.3
          : (maxLuma - minLuma > 128.0)
          ? 0.7
          : 1.0;
      _saturation = 1.3;
      _exposure = 0.2;
      _noise = 0.0;
      _smooth = 0.0;
    });

    _applyAdjustments();
  }

  void _handleError(String message) {
    debugPrint(message);
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _isInitialized = true;
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

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
                  localizations?.loading ?? 'Загрузка изображения...',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
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
                  onPressed: widget.onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    localizations?.close ?? 'Закрыть',
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
                _buildAppBar(localizations, !isMobile),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_previewImageBytes != null)
                        Center(
                          child: Image.memory(
                            _previewImageBytes!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint(
                                  'Ошибка отображения изображения: $error\n$stackTrace');
                              return Center(
                                child: Text(
                                  localizations?.invalidImage ??
                                      'Не удалось загрузить изображение',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                              );
                            },
                          ),
                        ),
                      if (_isProcessing)
                        Container(
                          color: Colors.black.withOpacity(0.5),
                          child: const Center(
                            child:
                            CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                _buildControls(localizations, isMobile: isMobile),
              ],
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
        icon: Icon(Icons.close,
            color: Colors.redAccent, size: isDesktop ? 28 : 24),
        onPressed: widget.onClose,
        tooltip: localizations?.cancel ?? 'Отмена',
      ),
      title: Text(
        localizations?.adjust ?? 'Настройки',
        style: TextStyle(
          color: Colors.white,
          fontSize: isDesktop ? 20 : 16,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.auto_awesome,
            color: Colors.amber,
            size: isDesktop ? 28 : 24,
          ),
          onPressed: _isProcessing ? null : _autoCorrect,
          tooltip: localizations?.autoCorrect ?? 'Автокоррекция',
        ),
        IconButton(
          icon: Icon(
            Icons.refresh,
            color: Colors.white,
            size: isDesktop ? 28 : 24,
          ),
          onPressed: _isProcessing ? null : _reset,
          tooltip: localizations?.reset ?? 'Сброс',
        ),
        IconButton(
          icon: Icon(
            Icons.check,
            color: Colors.green,
            size: isDesktop ? 28 : 24,
          ),
          onPressed: _isProcessing ? null : _applyFinal,
          tooltip: localizations?.apply ?? 'Применить',
        ),
      ],
    );
  }

  Widget _buildControls(AppLocalizations? localizations,
      {required bool isMobile}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sliderWidth = screenWidth * 0.6;
    final fontSize = isMobile ? 14.0 : 16.0;
    final padding = isMobile ? 12.0 : 16.0;

    return Container(
      height: 120,
      padding: EdgeInsets.symmetric(vertical: padding, horizontal: padding),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Row(
          children: [
            _buildSlider(
              icon: Icons.brightness_6,
              label: localizations?.brightness ?? 'Яркость',
              value: _brightness,
              min: -50,
              max: 50,
              width: sliderWidth,
              fontSize: fontSize,
              onChanged: (v) {
                setState(() {
                  _brightness = v;
                  _applyAdjustments();
                });
              },
            ),
            _buildSlider(
              icon: Icons.contrast,
              label: localizations?.contrast ?? 'Контраст',
              value: (_contrast - 1.0) * 50,
              min: -50,
              max: 50,
              width: sliderWidth,
              fontSize: fontSize,
              onChanged: (v) {
                setState(() {
                  _contrast = 1.0 + (v / 50);
                  _applyAdjustments();
                });
              },
            ),
            _buildSlider(
              icon: Icons.color_lens,
              label: localizations?.saturation ?? 'Насыщенность',
              value: (_saturation - 1.0) * 50,
              min: -50,
              max: 50,
              width: sliderWidth,
              fontSize: fontSize,
              onChanged: (v) {
                setState(() {
                  _saturation = 1.0 + (v / 50);
                  _applyAdjustments();
                });
              },
            ),
            _buildSlider(
              icon: Icons.exposure,
              label: localizations?.exposure ?? 'Экспозиция',
              value: _exposure * 50,
              min: -50,
              max: 50,
              width: sliderWidth,
              fontSize: fontSize,
              onChanged: (v) {
                setState(() {
                  _exposure = v / 50;
                  _applyAdjustments();
                });
              },
            ),
            _buildSlider(
              icon: Icons.grain,
              label: localizations?.noise ?? 'Шум',
              value: _noise,
              min: 0,
              max: 25,
              width: sliderWidth,
              fontSize: fontSize,
              onChanged: (v) {
                setState(() {
                  _noise = v;
                  _applyAdjustments();
                });
              },
            ),
            _buildSlider(
              icon: Icons.blur_on,
              label: localizations?.smooth ?? 'Сглаживание',
              value: _smooth,
              min: 0,
              max: 25,
              width: sliderWidth,
              fontSize: fontSize,
              onChanged: (v) {
                setState(() {
                  _smooth = v;
                  _applyAdjustments();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required double width,
    required double fontSize,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          SliderRow(
            icon: icon,
            value: value,
            min: min,
            max: max,
            divisions: ((max - min).abs() * 5).toInt(),
            label: value.toStringAsFixed(1),
            onChanged: onChanged,
            isProcessing: false,
            activeColor: Colors.blue,
            inactiveColor: Colors.grey[700]!,
          ),
        ],
      ),
    );
  }

  static img.Image _processImage(Map<String, dynamic> params) {
    final image = params['image'] as img.Image;
    final brightness =
        (params['brightness'] as double).clamp(-50.0, 50.0) / 50.0;
    final contrast = (params['contrast'] as double).clamp(0.5, 1.5);
    final saturation = (params['saturation'] as double).clamp(0.5, 1.5);
    final exposure = (params['exposure'] as double).clamp(-0.5, 0.5);
    final noise = (params['noise'] as double).clamp(0.0, 25.0) / 100.0;
    final smooth = (params['smooth'] as double).clamp(0.0, 25.0) / 100.0;
    final seed = params['seed'] as int;

    try {
      var result = image.clone();

      for (var y = 0; y < result.height; y++) {
        for (var x = 0; x < result.width; x++) {
          final pixel = result.getPixel(x, y);

          var r = (pixel.r + (brightness * 255)).clamp(0, 255).toInt();
          var g = (pixel.g + (brightness * 255)).clamp(0, 255).toInt();
          var b = (pixel.b + (brightness * 255)).clamp(0, 255).toInt();

          final factor = (259 * (contrast + 255)) / (255 * (259 - contrast));
          r = (factor * (r - 128) + 128).clamp(0, 255).toInt();
          g = (factor * (g - 128) + 128).clamp(0, 255).toInt();
          b = (factor * (b - 128) + 128).clamp(0, 255).toInt();

          final gray = 0.299 * r + 0.587 * g + 0.114 * b;
          r = (gray + saturation * (r - gray)).clamp(0, 255).toInt();
          g = (gray + saturation * (g - gray)).clamp(0, 255).toInt();
          b = (gray + saturation * (b - gray)).clamp(0, 255).toInt();

          r = (r * pow(2, exposure)).clamp(0, 255).toInt();
          g = (g * pow(2, exposure)).clamp(0, 255).toInt();
          b = (b * pow(2, exposure)).clamp(0, 255).toInt();

          result.setPixelRgba(x, y, r, g, b, pixel.a);
        }
      }

      if (noise > 0.01) {
        final random = Random(seed);
        for (var y = 0; y < result.height; y++) {
          for (var x = 0; x < result.width; x++) {
            final pixel = result.getPixel(x, y);
            final noiseValue = (random.nextDouble() * 2 - 1) * noise * 255;
            final r = (pixel.r + noiseValue).clamp(0, 255).toInt();
            final g = (pixel.g + noiseValue).clamp(0, 255).toInt();
            final b = (pixel.b + noiseValue).clamp(0, 255).toInt();
            result.setPixelRgba(x, y, r, g, b, pixel.a);
          }
        }
      }

      if (smooth > 0.01) {
        result = img.gaussianBlur(result, radius: (smooth * 10).toInt());
      }

      return result;
    } catch (e, stackTrace) {
      debugPrint('Ошибка обработки изображения: $e\n$stackTrace');
      return image;
    }
  }
}