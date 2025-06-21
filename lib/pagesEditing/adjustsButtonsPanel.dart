import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
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

class _AdjustPanelState extends State<AdjustPanel> with SingleTickerProviderStateMixin {
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
  bool _isApplyingFinal = false;
  String? _errorMessage;
  final _adjustmentCache = <String, Uint8List>{};
  static const _previewWidth = 300;
  static const _maxCacheSize = 5;
  Uint8List? _previewImageBytes;
  StreamController<Map<String, dynamic>>? _imageStreamController;
  double _temperature = 0.0;
  double _tint = 0.0;
  double _shadows = 0.0;
  double _highlights = 0.0;
  double _sharpen = 0.0;
  double _vignette = 0.0;
  Timer? _debounceTimer;
  double _hue = 0.0;
  double _lightness = 0.0;
  double _redBalance = 0.0;
  double _greenBalance = 0.0;
  double _blueBalance = 0.0;
  double _tintAmount = 0.0;
  Color _tintColor = Colors.blue;
  double _shadowTintAmount = 0.0;
  Color _shadowTintColor = Colors.blue;
  double _highlightTintAmount = 0.0;
  Color _highlightTintColor = Colors.orange;
  double _removeColorHue = 0.0;
  double _removeColorThreshold = 0.0;
  late TabController _tabController;
  List<Map<String, dynamic>> _historyStack = [];
  int _currentHistoryIndex = -1;
  bool _isSavingToDb = false;
  bool _isFinalApplied = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _previewImageBytes = widget.image;
    _imageStreamController = StreamController<Map<String, dynamic>>.broadcast();
    _initializeImage();
    _listenToImageUpdates();
  }

  @override
  void dispose() {
    _adjustmentCache.clear();
    _imageStreamController?.close();
    _debounceTimer?.cancel();
    _tabController.dispose();
    _historyStack.clear();
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
        _isInitialized = true;
      });

      _saveToHistory(widget.image, _getParameters());
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
      if (!_isInitialized || _currentImage == null || _isApplyingFinal) return;

      final cacheKey = _generateCacheKey();

      if (_adjustmentCache.containsKey(cacheKey)) {
        final cachedBytes = _adjustmentCache[cacheKey]!;
        if (mounted) {
          setState(() {
            _previewImageBytes = cachedBytes;
          });
        }
        widget.onImageChanged(cachedBytes, params);
        _saveToHistory(cachedBytes, params);
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
          'temperature': _temperature,
          'tint': _tint,
          'shadows': _shadows,
          'highlights': _highlights,
          'sharpen': _sharpen,
          'vignette': _vignette,
          'hue': _hue,
          'lightness': _lightness,
          'redBalance': _redBalance,
          'greenBalance': _greenBalance,
          'blueBalance': _blueBalance,
          'tintAmount': _tintAmount,
          'tintColor': _tintColor.value,
          'shadowTintAmount': _shadowTintAmount,
          'shadowTintColor': _shadowTintColor.value,
          'highlightTintAmount': _highlightTintAmount,
          'highlightTintColor': _highlightTintColor.value,
          'removeColorHue': _removeColorHue,
          'removeColorThreshold': _removeColorThreshold,
          'seed': DateTime.now().millisecondsSinceEpoch,
        }).timeout(const Duration(milliseconds: 500));

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
          _isProcessing = false;
        });
        widget.onImageChanged(bytes, params);
        _saveToHistory(bytes, params);
      } catch (e, stackTrace) {
        debugPrint('Ошибка применения изменений: $e\n$stackTrace');
        _handleError('Ошибка настройки: ${e.toString()}');
        widget.onImageChanged(widget.image, params);
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    });
  }

  String _generateCacheKey() {
    return '${_brightness.toStringAsFixed(2)}|${_contrast.toStringAsFixed(2)}|'
        '${_saturation.toStringAsFixed(2)}|${_exposure.toStringAsFixed(2)}|'
        '${_noise.toStringAsFixed(2)}|${_smooth.toStringAsFixed(2)}|'
        '${_temperature.toStringAsFixed(2)}|${_tint.toStringAsFixed(2)}|'
        '${_shadows.toStringAsFixed(2)}|${_highlights.toStringAsFixed(2)}|'
        '${_sharpen.toStringAsFixed(2)}|${_vignette.toStringAsFixed(2)}|'
        '${_hue.toStringAsFixed(2)}|${_lightness.toStringAsFixed(2)}|'
        '${_redBalance.toStringAsFixed(2)}|${_greenBalance.toStringAsFixed(2)}|'
        '${_blueBalance.toStringAsFixed(2)}|${_tintAmount.toStringAsFixed(2)}|'
        '${_tintColor.value}|${_shadowTintAmount.toStringAsFixed(2)}|'
        '${_shadowTintColor.value}|${_highlightTintAmount.toStringAsFixed(2)}|'
        '${_highlightTintColor.value}|${_removeColorHue.toStringAsFixed(2)}|'
        '${_removeColorThreshold.toStringAsFixed(2)}';
  }

  void _applyAdjustments() {
    if (!_isInitialized || _isApplyingFinal) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      _imageStreamController?.add(_getParameters());
    });
  }

  Map<String, dynamic> _getParameters() {
    return {
      'brightness': _brightness,
      'contrast': _contrast,
      'saturation': _saturation,
      'exposure': _exposure,
      'noise': _noise,
      'smooth': _smooth,
      'temperature': _temperature,
      'tint': _tint,
      'shadows': _shadows,
      'highlights': _highlights,
      'sharpen': _sharpen,
      'vignette': _vignette,
      'hue': _hue,
      'lightness': _lightness,
      'redBalance': _redBalance,
      'greenBalance': _greenBalance,
      'blueBalance': _blueBalance,
      'tintAmount': _tintAmount,
      'tintColor': _tintColor.value,
      'shadowTintAmount': _shadowTintAmount,
      'shadowTintColor': _shadowTintColor.value,
      'highlightTintAmount': _highlightTintAmount,
      'highlightTintColor': _highlightTintColor.value,
      'removeColorHue': _removeColorHue,
      'removeColorThreshold': _removeColorThreshold,
    };
  }

  bool _hasChanges() {
    return _brightness != 0.0 ||
        _contrast != 1.0 ||
        _saturation != 1.0 ||
        _exposure != 0.0 ||
        _noise != 0.0 ||
        _smooth != 0.0 ||
        _temperature != 0.0 ||
        _tint != 0.0 ||
        _shadows != 0.0 ||
        _highlights != 0.0 ||
        _sharpen != 0.0 ||
        _vignette != 0.0 ||
        _hue != 0.0 ||
        _lightness != 0.0 ||
        _redBalance != 0.0 ||
        _greenBalance != 0.0 ||
        _blueBalance != 0.0 ||
        _tintAmount != 0.0 ||
        _shadowTintAmount != 0.0 ||
        _highlightTintAmount != 0.0 ||
        _removeColorHue != 0.0 ||
        _removeColorThreshold != 0.0;
  }

  void _undo() {
    if (_currentHistoryIndex <= 0 || _isProcessing || _isApplyingFinal) return;

    setState(() {
      _currentHistoryIndex--;
      final historyState = _historyStack[_currentHistoryIndex];
      _previewImageBytes = historyState['bytes'];
      final params = historyState['params'] as Map<String, dynamic>;
      _brightness = params['brightness'] ?? 0.0;
      _contrast = params['contrast'] ?? 1.0;
      _saturation = params['saturation'] ?? 1.0;
      _exposure = params['exposure'] ?? 0.0;
      _noise = params['noise'] ?? 0.0;
      _smooth = params['smooth'] ?? 0.0;
      _temperature = params['temperature'] ?? 0.0;
      _tint = params['tint'] ?? 0.0;
      _shadows = params['shadows'] ?? 0.0;
      _highlights = params['highlights'] ?? 0.0;
      _sharpen = params['sharpen'] ?? 0.0;
      _vignette = params['vignette'] ?? 0.0;
      _hue = params['hue'] ?? 0.0;
      _lightness = params['lightness'] ?? 0.0;
      _redBalance = params['redBalance'] ?? 0.0;
      _greenBalance = params['greenBalance'] ?? 0.0;
      _blueBalance = params['blueBalance'] ?? 0.0;
      _tintAmount = params['tintAmount'] ?? 0.0;
      _tintColor = Color(params['tintColor'] ?? Colors.blue.value);
      _shadowTintAmount = params['shadowTintAmount'] ?? 0.0;
      _shadowTintColor = Color(params['shadowTintColor'] ?? Colors.blue.value);
      _highlightTintAmount = params['highlightTintAmount'] ?? 0.0;
      _highlightTintColor = Color(params['highlightTintColor'] ?? Colors.orange.value);
      _removeColorHue = params['removeColorHue'] ?? 0.0;
      _removeColorThreshold = params['removeColorThreshold'] ?? 0.0;
    });

    widget.onImageChanged(_previewImageBytes!, _getParameters());
  }

  void _saveToHistory(Uint8List bytes, Map<String, dynamic> params) {
    // Проверяем, есть ли уже такое состояние в истории
    if (_historyStack.isNotEmpty &&
        _currentHistoryIndex >= 0 &&
        _currentHistoryIndex < _historyStack.length) {
      final lastParams = _historyStack[_currentHistoryIndex]['params'];
      if (_areParamsEqual(lastParams, params)) {
        return;
      }
    }

    if (_currentHistoryIndex < _historyStack.length - 1) {
      _historyStack = _historyStack.sublist(0, _currentHistoryIndex + 1);
    }
    _historyStack.add({'bytes': bytes, 'params': params});
    _currentHistoryIndex++;
    if (_historyStack.length > 20) {
      _historyStack.removeAt(0);
      _currentHistoryIndex--;
    }
  }

  bool _areParamsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    for (final key in a.keys) {
      if (a[key] != b[key]) {
        return false;
      }
    }
    return true;
  }

  Future<void> _applyFinal() async {
    if (!_isInitialized || _isProcessing || _isApplyingFinal || !_hasChanges() || _isFinalApplied) {
      debugPrint('ApplyFinal skipped - already applied or no changes');
      widget.onClose();
      return;
    }

    setState(() {
      _isProcessing = true;
      _isApplyingFinal = true;
      _isFinalApplied = true; // Устанавливаем флаг, что финальное применение выполнено
    });

    try {
      final fullImage = img.decodeImage(widget.image);
      if (fullImage == null) {
        throw Exception('Не удалось декодировать изображение');
      }

      final result = await compute(_processImage, {
        'image': fullImage,
        ..._getParameters(),
        'seed': DateTime.now().microsecondsSinceEpoch,
      }).timeout(const Duration(seconds: 5));

      final bytes = img.encodePng(result);
      if (bytes.isEmpty) {
        throw Exception('Не удалось закодировать финальное изображение');
      }

      // Проверяем, не было ли уже сохранено такое же изображение
      final currentParams = _getParameters();
      bool shouldSaveToDb = true;
      if (_historyStack.isNotEmpty) {
        final lastEntry = _historyStack.last;
        if (_areParamsEqual(lastEntry['params'], currentParams)) {
          shouldSaveToDb = false;
          debugPrint('Skipping DB save - identical to last history entry');
        }
      }

      if (shouldSaveToDb) {
        String? snapshotPath;
        List<int>? snapshotBytes;
        final operationTimestamp = DateTime.now().toIso8601String();

        if (!kIsWeb) {
          final tempDir = await Directory.systemTemp.createTemp();
          snapshotPath = '${tempDir.path}/adjust_${DateTime.now().millisecondsSinceEpoch}.png';
          final file = File(snapshotPath);
          await file.writeAsBytes(bytes);
        } else {
          snapshotBytes = bytes;
        }

        final history = EditHistory(
          imageId: widget.imageId,
          operationType: 'adjustments',
          operationParameters: {
            ...currentParams,
            'timestamp': operationTimestamp,
          },
          operationDate: DateTime.now(),
          snapshotPath: snapshotPath,
          snapshotBytes: snapshotBytes,
        );

        final db = MagicMomentDatabase.instance;
        final historyId = await db.insertHistory(history);
        debugPrint('Saved to database with historyId: $historyId');

        if (!mounted) return;

        await widget.onUpdateImage?.call(
          bytes,
          action: AppLocalizations.of(context)?.adjust ?? 'Настройки',
          operationType: 'adjustments',
          parameters: {
            ...currentParams,
            'historyId': historyId,
            'timestamp': operationTimestamp,
          },
        );
      }

      widget.onImageChanged(bytes, currentParams);
      widget.onClose();
    } catch (e, stackTrace) {
      debugPrint('Ошибка применения финальных изменений: $e\n$stackTrace');
      _handleError('Ошибка финальной обработки: ${e.toString()}');
      widget.onImageChanged(widget.image, _getParameters());
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isApplyingFinal = false;
        });
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
      _temperature = 0.0;
      _tint = 0.0;
      _shadows = 0.0;
      _highlights = 0.0;
      _sharpen = 0.0;
      _vignette = 0.0;
      _hue = 0.0;
      _lightness = 0.0;
      _redBalance = 0.0;
      _greenBalance = 0.0;
      _blueBalance = 0.0;
      _tintAmount = 0.0;
      _tintColor = Colors.blue;
      _shadowTintAmount = 0.0;
      _shadowTintColor = Colors.blue;
      _highlightTintAmount = 0.0;
      _highlightTintColor = Colors.orange;
      _removeColorHue = 0.0;
      _removeColorThreshold = 0.0;
      _currentImage = _originalImage.clone();
      _previewImageBytes = widget.image;
      _adjustmentCache.clear();
      _historyStack.clear();
      _currentHistoryIndex = -1;
    });

    _saveToHistory(widget.image, _getParameters());
    _applyAdjustments();
    widget.onImageChanged(widget.image, _getParameters());
  }

  void _autoCorrect() {
    if (!_isInitialized || _isApplyingFinal) return;

    final image = _originalImage;
    final histogram = List<int>.filled(256, 0);
    int totalLuma = 0;
    int pixelCount = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luma = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b).round();
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
      _temperature = 0.0;
      _tint = 0.0;
      _shadows = 10.0;
      _highlights = -10.0;
      _sharpen = 5.0;
      _vignette = -10.0;
      _hue = 0.0;
      _lightness = 0.0;
      _redBalance = 0.0;
      _greenBalance = 0.0;
      _blueBalance = 0.0;
      _tintAmount = 0.0;
      _shadowTintAmount = 0.0;
      _highlightTintAmount = 0.0;
      _removeColorHue = 0.0;
      _removeColorThreshold = 0.0;
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
        _isApplyingFinal = false;
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
            Icons.undo,
            color: _currentHistoryIndex > 0 ? Colors.white : Colors.grey,
            size: isDesktop ? 28 : 24,
          ),
          onPressed: _currentHistoryIndex > 0 && !_isProcessing && !_isApplyingFinal ? _undo : null,
          tooltip: localizations?.undo ?? 'Отменить',
        ),
        IconButton(
          icon: Icon(
            Icons.auto_awesome,
            color: Colors.amber,
            size: isDesktop ? 28 : 24,
          ),
          onPressed: _isProcessing || _isApplyingFinal ? null : _autoCorrect,
          tooltip: localizations?.autoCorrect ?? 'Автокоррекция',
        ),
        IconButton(
          icon: Icon(
            Icons.refresh,
            color: Colors.white,
            size: isDesktop ? 28 : 24,
          ),
          onPressed: _isProcessing || _isApplyingFinal ? null : _reset,
          tooltip: localizations?.reset ?? 'Сброс',
        ),
        IconButton(
          icon: Icon(
            Icons.check,
            color: Colors.green,
            size: isDesktop ? 28 : 24,
          ),
          onPressed: () {
            if (!_isProcessing && !_isApplyingFinal) {
              _applyFinal();
            }
          },
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
      height: 200,
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
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: localizations?.basic ?? 'Основные'),
              Tab(text: localizations?.color ?? 'Цвет'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
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
                      _buildSlider(
                        icon: Icons.brightness_low,
                        label: localizations?.shadows ?? 'Тени',
                        value: _shadows,
                        min: -50,
                        max: 50,
                        width: sliderWidth,
                        fontSize: fontSize,
                        onChanged: (v) {
                          setState(() {
                            _shadows = v;
                            _applyAdjustments();
                          });
                        },
                      ),
                      _buildSlider(
                        icon: Icons.brightness_high,
                        label: localizations?.highlights ?? 'Света',
                        value: _highlights,
                        min: -50,
                        max: 50,
                        width: sliderWidth,
                        fontSize: fontSize,
                        onChanged: (v) {
                          setState(() {
                            _highlights = v;
                            _applyAdjustments();
                          });
                        },
                      ),
                      _buildSlider(
                        icon: FluentIcons.triangle_12_filled,
                        label: localizations?.sharpen ?? 'Резкость',
                        value: _sharpen,
                        min: 0,
                        max: 25,
                        width: sliderWidth,
                        fontSize: fontSize,
                        onChanged: (v) {
                          setState(() {
                            _sharpen = v;
                            _applyAdjustments();
                          });
                        },
                      ),
                      _buildSlider(
                        icon: Icons.vignette,
                        label: localizations?.vignette ?? 'Виньетирование',
                        value: _vignette,
                        min: -50,
                        max: 50,
                        width: sliderWidth,
                        fontSize: fontSize,
                        onChanged: (v) {
                          setState(() {
                            _vignette = v;
                            _applyAdjustments();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildSlider(
                        icon: Icons.thermostat,
                        label: localizations?.temperature ?? 'Температура',
                        value: _temperature,
                        min: -50,
                        max: 50,
                        width: sliderWidth,
                        fontSize: fontSize,
                        onChanged: (v) {
                          setState(() {
                            _temperature = v;
                            _applyAdjustments();
                          });
                        },
                      ),
                      _buildSlider(
                        icon: Icons.colorize,
                        label: localizations?.tint ?? 'Оттенок',
                        value: _tint,
                        min: -50,
                        max: 50,
                        width: sliderWidth,
                        fontSize: fontSize,
                        onChanged: (v) {
                          setState(() {
                            _tint = v;
                            _applyAdjustments();
                          });
                        },
                      ),
                      _buildColorSlider(
                        label: 'Тонирование',
                        value: _tintAmount,
                        color: _tintColor,
                        min: 0,
                        max: 100,
                        width: sliderWidth,
                        fontSize: fontSize,
                        onValueChanged: (v) {
                          setState(() {
                            _tintAmount = v;
                            _applyAdjustments();
                          });
                        },
                        onColorChanged: (c) {
                          setState(() {
                            _tintColor = c;
                            _applyAdjustments();
                          });
                        },
                      ),
                      _buildColorSlider(
                        label: 'Тени цвет',
                        value: _shadowTintAmount,
                        color: _shadowTintColor,
                        min: 0,
                        max: 100,
                        width: sliderWidth,
                        fontSize: fontSize,
                        onValueChanged: (v) {
                          setState(() {
                            _shadowTintAmount = v;
                            _applyAdjustments();
                          });
                        },
                        onColorChanged: (c) {
                          setState(() {
                            _shadowTintColor = c;
                            _applyAdjustments();
                          });
                        },
                      ),
                      _buildColorSlider(
                        label: 'Света цвет',
                        value: _highlightTintAmount,
                        color: _highlightTintColor,
                        min: 0,
                        max: 100,
                        width: sliderWidth,
                        fontSize: fontSize,
                        onValueChanged: (v) {
                          setState(() {
                            _highlightTintAmount = v;
                            _applyAdjustments();
                          });
                        },
                        onColorChanged: (c) {
                          setState(() {
                            _highlightTintColor = c;
                            _applyAdjustments();
                          });
                        },
                      ),
                      _buildColorPickerSlider(
                        label: 'Удалить цвет',
                        hue: _removeColorHue,
                        threshold: _removeColorThreshold,
                        width: sliderWidth,
                        fontSize: fontSize,
                        onHueChanged: (v) {
                          setState(() {
                            _removeColorHue = v;
                            _applyAdjustments();
                          });
                        },
                        onThresholdChanged: (v) {
                          setState(() {
                            _removeColorThreshold = v;
                            _applyAdjustments();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
            isProcessing: _isProcessing,
            activeColor: Colors.blue,
            inactiveColor: Colors.grey[700]!,
          ),
        ],
      ),
    );
  }

  static img.Image _processImage(Map<String, dynamic> params) {
    final image = params['image'] as img.Image;
    final brightness = (params['brightness'] as double? ?? 0.0).clamp(-1.0, 1.0);
    final contrast = (params['contrast'] as double? ?? 1.0).clamp(0.5, 1.5);
    final saturation = (params['saturation'] as double? ?? 1.0).clamp(0.5, 1.5);
    final exposure = (params['exposure'] as double? ?? 0.0).clamp(-1.0, 1.0);
    final noise = (params['noise'] as double? ?? 0.0).clamp(0.0, 0.25);
    final smooth = (params['smooth'] as double? ?? 0.0).clamp(0.0, 0.25);
    final temperature = (params['temperature'] as double? ?? 0.0).clamp(-1.0, 1.0);
    final tint = (params['tint'] as double? ?? 0.0).clamp(-1.0, 1.0);
    final shadows = (params['shadows'] as double? ?? 0.0).clamp(-1.0, 1.0);
    final highlights = (params['highlights'] as double? ?? 0.0).clamp(-1.0, 1.0);
    final sharpen = (params['sharpen'] as double? ?? 0.0).clamp(0.0, 0.25);
    final vignette = (params['vignette'] as double? ?? 0.0).clamp(-1.0, 1.0);
    final hue = (params['hue'] as double? ?? 0.0).clamp(-180.0, 180.0);
    final lightness = (params['lightness'] as double? ?? 0.0).clamp(-100.0, 100.0);
    final redBalance = (params['redBalance'] as double? ?? 0.0).clamp(-100.0, 100.0);
    final greenBalance = (params['greenBalance'] as double? ?? 0.0).clamp(-100.0, 100.0);
    final blueBalance = (params['blueBalance'] as double? ?? 0.0).clamp(-100.0, 100.0);
    final tintAmount = (params['tintAmount'] as double? ?? 0.0).clamp(0.0, 100.0);
    final tintColor = Color(params['tintColor'] as int? ?? Colors.blue.value);
    final shadowTintAmount = (params['shadowTintAmount'] as double? ?? 0.0).clamp(0.0, 100.0);
    final shadowTintColor = Color(params['shadowTintColor'] as int? ?? Colors.blue.value);
    final highlightTintAmount = (params['highlightTintAmount'] as double? ?? 0.0).clamp(0.0, 100.0);
    final highlightTintColor = Color(params['highlightTintColor'] as int? ?? Colors.orange.value);
    final removeColorHue = (params['removeColorHue'] as double? ?? 0.0).clamp(0.0, 360.0);
    final removeColorThreshold = (params['removeColorThreshold'] as double? ?? 0.0).clamp(0.0, 100.0);
    final seed = params['seed'] as int? ?? DateTime.now().millisecondsSinceEpoch;

    try {
      var result = image.clone();
      final random = Random(seed);

      for (var y = 0; y < result.height; y++) {
        for (var x = 0; x < result.width; x++) {
          var pixel = result.getPixel(x, y);

          var r = pixel.r.toDouble();
          var g = pixel.g.toDouble();
          var b = pixel.b.toDouble();

          if (temperature > 0) {
            r += temperature * 50;
            b -= temperature * 50;
          } else if (temperature < 0) {
            r += temperature * 50;
            b -= temperature * 50;
          }

          if (tint > 0) {
            g += tint * 30;
          } else if (tint < 0) {
            r -= tint * 15;
            b -= tint * 15;
          }

          r += redBalance * 2.55;
          g += greenBalance * 2.55;
          b += blueBalance * 2.55;

          if (tintAmount > 0) {
            final tintR = tintColor.red * tintAmount / 100;
            final tintG = tintColor.green * tintAmount / 100;
            final tintB = tintColor.blue * tintAmount / 100;

            r = (r * (1 - tintAmount / 100) + tintR).clamp(0, 255);
            g = (g * (1 - tintAmount / 100) + tintG).clamp(0, 255);
            b = (b * (1 - tintAmount / 100) + tintB).clamp(0, 255);
          }

          final luma = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
          if (luma < 0.5 && shadowTintAmount > 0) {
            final tintR = shadowTintColor.red * shadowTintAmount / 100;
            final tintG = shadowTintColor.green * shadowTintAmount / 100;
            final tintB = shadowTintColor.blue * shadowTintAmount / 100;

            r = (r * (1 - shadowTintAmount / 100) + tintR).clamp(0, 255);
            g = (g * (1 - shadowTintAmount / 100) + tintG).clamp(0, 255);
            b = (b * (1 - shadowTintAmount / 100) + tintB).clamp(0, 255);
          } else if (luma >= 0.5 && highlightTintAmount > 0) {
            final tintR = highlightTintColor.red * highlightTintAmount / 100;
            final tintG = highlightTintColor.green * highlightTintAmount / 100;
            final tintB = highlightTintColor.blue * highlightTintAmount / 100;

            r = (r * (1 - highlightTintAmount / 100) + tintR).clamp(0, 255);
            g = (g * (1 - highlightTintAmount / 100) + tintG).clamp(0, 255);
            b = (b * (1 - highlightTintAmount / 100) + tintB).clamp(0, 255);
          }

          r = (r + (brightness * 255)).clamp(0, 255);
          g = (g + (brightness * 255)).clamp(0, 255);
          b = (b + (brightness * 255)).clamp(0, 255);

          final contrastFactor = (259 * (contrast + 255)) / (255 * (259 - contrast));
          r = (contrastFactor * (r - 128) + 128).clamp(0, 255);
          g = (contrastFactor * (g - 128) + 128).clamp(0, 255);
          b = (contrastFactor * (b - 128) + 128).clamp(0, 255);

          final gray = 0.299 * r + 0.587 * g + 0.114 * b;
          r = (gray + saturation * (r - gray)).clamp(0, 255);
          g = (gray + saturation * (g - gray)).clamp(0, 255);
          b = (gray + saturation * (b - gray)).clamp(0, 255);

          r = (r * pow(2, exposure)).clamp(0, 255);
          g = (g * pow(2, exposure)).clamp(0, 255);
          b = (b * pow(2, exposure)).clamp(0, 255);

          if (luma < 0.5) {
            r = (r + shadows * 50).clamp(0, 255);
            g = (g + shadows * 50).clamp(0, 255);
            b = (b + shadows * 50).clamp(0, 255);
          } else {
            r = (r + highlights * 50).clamp(0, 255);
            g = (g + highlights * 50).clamp(0, 255);
            b = (b + highlights * 50).clamp(0, 255);
          }

          if (noise > 0.01) {
            final noiseValue = (random.nextDouble() * 2 - 1) * noise * 255;
            r = (r + noiseValue).clamp(0, 255);
            g = (g + noiseValue).clamp(0, 255);
            b = (b + noiseValue).clamp(0, 255);
          }

          if (vignette.abs() > 0.01) {
            final centerX = result.width / 2;
            final centerY = result.height / 2;
            final distX = (x - centerX) / centerX;
            final distY = (y - centerY) / centerY;
            final distance = sqrt(distX * distX + distY * distY);
            final vignetteEffect = 1.0 - (distance * vignette.abs());

            if (vignette > 0) {
              r *= vignetteEffect.clamp(0, 1);
              g *= vignetteEffect.clamp(0, 1);
              b *= vignetteEffect.clamp(0, 1);
            } else {
              r += (1.0 - vignetteEffect.clamp(0, 1)) * 255;
              g += (1.0 - vignetteEffect.clamp(0, 1)) * 255;
              b += (1.0 - vignetteEffect.clamp(0, 1)) * 255;
            }
          }

          result.setPixelRgba(x, y, r.round(), g.round(), b.round(), pixel.a);
        }
      }

      if (smooth > 0.01) {
        result = img.gaussianBlur(result, radius: (smooth * 10).toInt());
      }

      if (sharpen > 0.01) {
        final sharpened = result.clone();
        final amount = sharpen * 2.0;

        for (var y = 1; y < result.height - 1; y++) {
          for (var x = 1; x < result.width - 1; x++) {
            final pixel = result.getPixel(x, y);

            final left = result.getPixel(x - 1, y);
            final right = result.getPixel(x + 1, y);
            final top = result.getPixel(x, y - 1);
            final bottom = result.getPixel(x, y + 1);

            final diffR = (4 * pixel.r - left.r - right.r - top.r - bottom.r) * amount;
            final diffG = (4 * pixel.g - left.g - right.g - top.g - bottom.g) * amount;
            final diffB = (4 * pixel.b - left.b - right.b - top.b - bottom.b) * amount;

            final r = (pixel.r + diffR).clamp(0, 255).toInt();
            final g = (pixel.g + diffG).clamp(0, 255).toInt();
            final b = (pixel.b + diffB).clamp(0, 255).toInt();

            sharpened.setPixelRgba(x, y, r, g, b, pixel.a);
          }
        }
        result = sharpened;
      }

      return result;
    } catch (e, stackTrace) {
      debugPrint('Ошибка обработки изображения: $e\n$stackTrace');
      return image;
    }
  }

  Widget _buildColorSlider({
    required String label,
    required double value,
    required Color color,
    required double min,
    required double max,
    required double width,
    required double fontSize,
    required ValueChanged<double> onValueChanged,
    required ValueChanged<Color> onColorChanged,
  }) {
    final localizations = AppLocalizations.of(context);
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
          const SizedBox(height: 4),
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  Color? newColor;
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(localizations?.selectColor ?? 'Выберите цвет'),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: color,
                          onColorChanged: (c) => newColor = c,
                          showLabel: false,
                          pickerAreaHeightPercent: 0.8,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(localizations?.cancel ?? 'Отмена'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, newColor),
                          child: Text(localizations?.ok ?? 'OK'),
                        ),
                      ],
                    ),
                  );
                  if (newColor != null) {
                    onColorChanged(newColor!);
                  }
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderRow(
                  icon: Icons.opacity,
                  value: value,
                  min: min,
                  max: max,
                  divisions: ((max - min).abs()).toInt(),
                  label: value.toStringAsFixed(0),
                  onChanged: onValueChanged,
                  isProcessing: _isProcessing,
                  activeColor: color,
                  inactiveColor: Colors.grey[700]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorPickerSlider({
    required String label,
    required double hue,
    required double threshold,
    required double width,
    required double fontSize,
    required ValueChanged<double> onHueChanged,
    required ValueChanged<double> onThresholdChanged,
  }) {
    final localizations = AppLocalizations.of(context);
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
          const SizedBox(height: 4),
          SliderRow(
            icon: Icons.colorize,
            value: hue,
            min: 0,
            max: 360,
            divisions: 36,
            label: localizations?.color ?? 'Цвет',
            onChanged: onHueChanged,
            isProcessing: _isProcessing,
            activeColor: HSLColor.fromAHSL(1.0, hue, 1.0, 0.5).toColor(),
            inactiveColor: Colors.grey[700]!,
          ),
          SliderRow(
            icon: Icons.blur_on,
            value: threshold,
            min: 0,
            max: 100,
            divisions: 20,
            label: localizations?.threshold ?? 'Порог',
            onChanged: onThresholdChanged,
            isProcessing: _isProcessing,
            activeColor: Colors.blue,
            inactiveColor: Colors.grey[700]!,
          ),
        ],
      ),
    );
  }
}

double _hueToRGB(double p, double q, double t) {
  if (t < 0) t += 360;
  if (t > 360) t -= 360;

  if (t < 60) return p + (q - p) * t / 60;
  if (t < 180) return q;
  if (t < 240) return p + (q - p) * (240 - t) / 60;
  return p;
}