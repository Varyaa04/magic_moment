import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'effectsUtils.dart';

// Утилиты для адаптивного дизайна
class ResponsiveUtils {
  static double getResponsiveWidth(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * percentage;
  }

  static double getResponsiveHeight(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.height * percentage;
  }

  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    return baseSize * (width / 600).clamp(0.8, 1.5);
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return EdgeInsets.symmetric(
      horizontal: width * 0.02,
      vertical: width * 0.01,
    );
  }
}

class EffectsPanel extends StatefulWidget {
  final Uint8List image;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;
  final int imageId;

  const EffectsPanel({
    required this.image,
    required this.onCancel,
    required this.onApply,
    required this.imageId,
    super.key,
  });

  @override
  _EffectsPanelState createState() => _EffectsPanelState();
}

class _EffectsPanelState extends State<EffectsPanel> {
  bool _isInitialized = false;
  bool _isProcessing = false;
  late Uint8List _currentImageBytes;
  img.Image? _decodedImage;
  Effect? _selectedEffect;
  final GlobalKey _imageKey = GlobalKey();
  final Map<String, double> _effectParams = {};
  Timer? _debounceTimer;
  final Map<String, Uint8List> _previewCache = {};
  final List<Map<String, dynamic>> _history = [];
  int _historyIndex = -1;
  final _thumbnailWidth = 32; // Уменьшил для скорости

  @override
  void initState() {
    super.initState();
    _currentImageBytes = widget.image;
    _initialize();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _decodedImage = null;
    _selectedEffect = null;
    _previewCache.clear();
    super.dispose();
  }

// Инициализация с быстрой загрузкой экрана
  Future<void> _initialize() async {
    try {
      if (widget.image.isEmpty) throw Exception('Пустое изображение');
      _decodedImage = await decodeImage(widget.image);
      if (_decodedImage == null) throw Exception('Не удалось декодировать');

// Ресайз для оптимизации
      if (_decodedImage!.width > 800) {
        _decodedImage = img.copyResize(_decodedImage!,
            width: 800, interpolation: img.Interpolation.linear);
      }

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
        if (effects.isEmpty) {
          _showErrorSnackBar('Нет эффектов');
          widget.onCancel();
          return;
        }
        _selectedEffect = effects.first;
        _effectParams.addAll(_selectedEffect!.defaultParams);
      });

// Применяем начальный эффект
      await _applyEffect(_selectedEffect!, _effectParams, force: true);
      _history.add({
        'image': widget.image,
        'action': AppLocalizations.of(context)?.filters ?? 'Исходное',
        'operationType': 'initial',
        'parameters': {},
      });
      _historyIndex = 0;

// Генерация превью в фоне
      unawaited(_generateAllPreviews());
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Ошибка: $e');
        widget.onCancel();
      }
    }
  }

// Генерация всех превью асинхронно
  Future<void> _generateAllPreviews() async {
    if (_decodedImage == null) return;
    final thumbnail = img.copyResize(_decodedImage!, width: _thumbnailWidth);

    for (var effect in effects) {
      final cacheKey = effect.name +
          effect.defaultParams.entries
              .map((e) => '${e.key}:${e.value}')
              .join('_');
      if (_previewCache.containsKey(cacheKey)) continue;

      try {
        final processedImage = await compute(_processPreview, {
          'srcImage': thumbnail,
          'effect': effect,
          'params': Map<String, double>.from(effect.defaultParams),
        });
        final previewBytes = await encodeImage(processedImage);
        if (previewBytes.isNotEmpty && mounted) {
          setState(() {
            _previewCache[cacheKey] = previewBytes;
          });
        }
      } catch (e) {
        if (mounted) _showErrorSnackBar('Ошибка превью ${effect.name}: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  static Future<img.Image> _processPreview(Map<String, dynamic> data) async {
    final img.Image srcImage = data['srcImage'];
    final Effect effect = data['effect'];
    final Map<String, double> params = data['params'];
    return await effect.apply(srcImage, params);
  }

  Future<void> _applyEffect(Effect effect, Map<String, double> params,
      {bool force = false}) async {
    if (_isProcessing && !force) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () async {
      setState(() => _isProcessing = true);
      try {
        if (_decodedImage == null) throw Exception('Нет изображения');
        final processedImage = await compute(_processEffect, {
          'srcImage': _decodedImage!,
          'effect': effect,
          'params': Map<String, double>.from(params),
        });
        final processedBytes = await encodeImage(processedImage);
        if (processedBytes.isEmpty) throw Exception('Ошибка обработки');
        if (mounted) {
          setState(() {
            _currentImageBytes = processedBytes;
            _selectedEffect = effect;
            _effectParams.clear();
            _effectParams.addAll(params);
          });
        }
      } catch (e) {
        if (mounted) _showErrorSnackBar('Ошибка эффекта ${effect.name}: $e');
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    });
  }

  static Future<img.Image> _processEffect(Map<String, dynamic> data) async {
    final img.Image srcImage = data['srcImage'];
    final Effect effect = data['effect'];
    final Map<String, double> params = data['params'];
    return await effect.apply(srcImage, params);
  }

  Future<void> _undo() async {
    if (_isProcessing || _historyIndex <= 0) return;
    setState(() => _isProcessing = true);
    try {
      setState(() {
        _historyIndex--;
        _currentImageBytes = _history[_historyIndex]['image'];
        _selectedEffect = null;
        _effectParams.clear();
      });
    } catch (e) {
      if (mounted) _showErrorSnackBar('Ошибка отмены: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveChanges() async {
    if (_isProcessing || _selectedEffect == null || _decodedImage == null)
      return;
    setState(() => _isProcessing = true);
    try {
// Проверяем, что все параметры инициализированы
      final params = Map<String, double>.from(_selectedEffect!.defaultParams);
      params.addAll(_effectParams);
      final processedImage = await compute(_processEffect, {
        'srcImage': _decodedImage!,
        'effect': _selectedEffect!,
        'params': params,
      });
      final processedBytes = await encodeImage(processedImage);
      if (processedBytes.isEmpty) throw Exception('Ошибка сохранения');
      if (mounted) {
        setState(() {
          if (_historyIndex < _history.length - 1) {
            _history.removeRange(_historyIndex + 1, _history.length);
          }
          _history.add({
            'image': processedBytes,
            'action': 'Эффект: ${_selectedEffect!.name}',
            'operationType': 'effect',
            'parameters': Map<String, double>.from(params),
          });
          _historyIndex++;
        });
        widget.onApply(processedBytes);
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Ошибка сохранения: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(appLocalizations, theme, isDesktop),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 24 : 8,
                      vertical: 8,
                    ),
                    child: _isInitialized
                        ? RepaintBoundary(
                            key: _imageKey,
                            child: Image.memory(
                              _currentImageBytes,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    appLocalizations?.invalidImage ??
                                        'Ошибка изображения',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          ResponsiveUtils.getResponsiveFontSize(
                                              context, 14),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                    color: Colors.white),
                                const SizedBox(height: 16),
                                Text(
                                  appLocalizations?.loading ?? 'Загрузка...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize:
                                        ResponsiveUtils.getResponsiveFontSize(
                                            context, 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                _buildEffectControls(appLocalizations, theme, isDesktop),
                _buildEffectList(theme, appLocalizations),
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
                        appLocalizations?.processingEffect ?? 'Обработка...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context, 14),
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

  Widget _buildAppBar(
      AppLocalizations? appLocalizations, ThemeData theme, bool isDesktop) {
    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.7),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close,
            color: Colors.redAccent, size: isDesktop ? 28 : 24),
        onPressed: widget.onCancel,
        tooltip: appLocalizations?.cancel ?? 'Отмена',
      ),
      title: Text(
        appLocalizations?.effects ?? 'Эффекты',
        style: TextStyle(
          color: Colors.white,
          fontSize: isDesktop ? 20 : 16,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.undo,
            color: _historyIndex > 0 ? Colors.white : Colors.grey[700],
            size: isDesktop ? 28 : 24,
          ),
          onPressed: _historyIndex > 0 && !_isProcessing ? _undo : null,
          tooltip: appLocalizations?.undo ?? 'Отмена',
        ),
        IconButton(
          icon: Icon(
            Icons.check,
            color: _isProcessing || _selectedEffect == null
                ? Colors.grey[700]
                : Colors.green,
            size: isDesktop ? 28 : 24,
          ),
          onPressed:
              _isProcessing || _selectedEffect == null ? null : _saveChanges,
          tooltip: appLocalizations?.applyEffect ?? 'Применить',
        ),
      ],
    );
  }

  Widget _buildEffectControls(
      AppLocalizations? appLocalizations, ThemeData theme, bool isDesktop) {
    if (_selectedEffect == null || _selectedEffect!.params.isEmpty) {
      return const SizedBox.shrink();
    }

    final fontSize = isDesktop ? 14.0 : 12.0;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 12,
        vertical: isDesktop ? 12 : 8,
      ),
      color: Colors.black.withOpacity(0.7),
      child: SingleChildScrollView(
        child: Column(
          children: _selectedEffect!.params.map((param) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: isDesktop ? 120 : 80,
                    child: Text(
                      param.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: _effectParams[param.name] ?? param.defaultValue,
                      min: param.minValue,
                      max: param.maxValue,
                      divisions:
                          ((param.maxValue - param.minValue) / param.step)
                              .round(),
                      activeColor: theme.primaryColor,
                      inactiveColor: theme.disabledColor,
                      label: (_effectParams[param.name] ?? param.defaultValue)
                          .toStringAsFixed(1),
                      onChanged: _isProcessing
                          ? null
                          : (value) {
                              setState(() {
                                _effectParams[param.name] = value;
                              });
                              _applyEffect(_selectedEffect!, _effectParams);
                            },
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEffectList(ThemeData theme, AppLocalizations? appLocalizations) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final previewSize =
        isDesktop ? 56.0 : 40.0; // Уменьшил для избежания overflow
    final fontSize = isDesktop ? 12.0 : 10.0;

    if (!_isInitialized) {
      return Container(
        height: isDesktop ? 120 : 100, // Увеличил высоту для избежания overflow
        color: Colors.black.withOpacity(0.7),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    }

    return Container(
      height: isDesktop ? 120 : 100, // Увеличил высоту
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: effects.length,
        itemBuilder: (context, index) {
          final effect = effects[index];
          final cacheKey = effect.name +
              effect.defaultParams.entries
                  .map((e) => '${e.key}:${e.value}')
                  .join('_');
          final previewBytes = _previewCache[cacheKey];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: _isProcessing
                  ? null
                  : () {
                      if (mounted) {
                        setState(() {
                          _selectedEffect = effect;
                          _effectParams.clear();
                          _effectParams.addAll(effect.defaultParams);
                        });
                        _applyEffect(effect,
                            Map<String, double>.from(effect.defaultParams));
                      }
                    },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: previewSize,
                    height: previewSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedEffect == effect
                            ? Colors.blue
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: previewBytes != null
                          ? Image.memory(
                              previewBytes,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.memory(
                                  widget.image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.error,
                                          color: Colors.red, size: 24),
                                    );
                                  },
                                );
                              },
                            )
                          : const Center(
                              child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: previewSize,
                    child: Text(
                      effect.name,
                      style: TextStyle(
                        color: _selectedEffect == effect
                            ? Colors.blue
                            : Colors.white,
                        fontSize: fontSize,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
