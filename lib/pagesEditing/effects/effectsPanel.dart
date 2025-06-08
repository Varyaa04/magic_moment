import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image;
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
    final width = MediaQuery.of(context).size.width;
    return width > 800;
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
  image.Image? _decodedImage;
  Effect? _selectedEffect;
  final GlobalKey _imageKey = GlobalKey();
  final Map<String, double> _effectParams = {};
  final Completer<void> _initCompleter = Completer<void>();
  final Map<String, Uint8List> _previewCache = {};

  @override
  void initState() {
    super.initState();
    _currentImageBytes = widget.image;
    _initialize();
  }

  @override
  void dispose() {
    _decodedImage = null;
    _selectedEffect = null;
    _previewCache.clear();
    debugPrint('Disposing EffectsPanel');
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      if (widget.image.isEmpty) {
        throw Exception('Входное изображение пустое');
      }
      debugPrint('Initializing EffectsPanel with image size: ${widget.image.length} bytes');
      _decodedImage = await compute(decodeImage, widget.image);
      if (_decodedImage == null) {
        throw Exception('Не удалось декодировать изображение');
      }
      if (!mounted) {
        _initCompleter.completeError(Exception('Widget disposed during initialization'));
        return;
      }
      setState(() {
        _isInitialized = true;
        if (effects.isEmpty) {
          debugPrint('No effects available');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.no ?? 'Нет доступных эффектов',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red[700],
              duration: const Duration(seconds: 3),
            ),
          );
          widget.onCancel();
          return;
        }
        _selectedEffect = effects.first;
        _effectParams.addAll(_selectedEffect!.defaultParams);
      });
      await _applyEffect(_selectedEffect!, Map.from(_selectedEffect!.defaultParams));
      _initCompleter.complete();
      debugPrint('EffectsPanel initialization completed');
    } catch (e, stackTrace) {
      debugPrint('Ошибка инициализации изображения: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.invalidImage ?? 'Неверный формат изображения',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 3),
          ),
        );
        widget.onCancel();
      }
      _initCompleter.completeError(e);
    }
  }

  Future<Uint8List> _generateEffectPreview(Effect effect) async {
    await _initCompleter.future; // Wait for initialization
    if (!_isInitialized || _decodedImage == null) {
      debugPrint('Cannot generate preview for ${effect.name}: image not decoded or not initialized');
      return Uint8List(0);
    }
    final cacheKey = effect.name;
    if (_previewCache.containsKey(cacheKey)) {
      return _previewCache[cacheKey]!;
    }
    try {
      debugPrint('Generating preview for effect: ${effect.name}');
      final previewData = await compute(_processPreview, {
        'image': _decodedImage!,
        'effect': effect,
      });
      if (previewData.isEmpty) {
        throw Exception('Empty preview data for ${effect.name}');
      }
      _previewCache[cacheKey] = previewData;
      return previewData;
    } catch (e, stackTrace) {
      debugPrint('Ошибка генерации превью для ${effect.name}: $e\n$stackTrace');
      return Uint8List(0);
    }
  }

  static Future<Uint8List> _processPreview(Map<String, dynamic> data) async {
    final image.Image decodedImage = data['image'] as image.Image;
    final Effect effect = data['effect'] as Effect;
    final image.Image thumbnail = image.copyResize(
      decodedImage,
      width: 100,
      interpolation: image.Interpolation.linear,
    );
    final image.Image processedImage = await effect.apply(thumbnail, effect.defaultParams);
    final result = await encodeImage(processedImage);
    return result.isEmpty ? Uint8List(0) : result;
  }

  Future<void> _applyEffect(Effect effect, Map<String, double> params) async {
    await _initCompleter.future;
    if (_isProcessing || _decodedImage == null || !mounted) {
      debugPrint('Cannot apply effect ${effect.name}: processing, no image, or disposed');
      return;
    }

    setState(() => _isProcessing = true);
    try {
      debugPrint('Applying effect: ${effect.name} with params: $params');
      final processedBytes = await compute(_processEffect, {
        'image': _decodedImage!,
        'effect': effect,
        'params': params,
      });
      if (processedBytes.isEmpty) {
        throw Exception('Empty processed bytes for effect ${effect.name}');
      }
      if (mounted) {
        setState(() {
          _currentImageBytes = processedBytes;
          _selectedEffect = effect;
          _effectParams.clear();
          _effectParams.addAll(params);
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Ошибка применения эффекта ${effect.name}: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)?.errorApplyEffect ?? 'Не удалось применить эффект'}: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  static Future<Uint8List> _processEffect(Map<String, dynamic> data) async {
    final image.Image decodedImage = data['image'] as image.Image;
    final Effect effect = data['effect'] as Effect;
    final Map<String, double> params = data['params'] as Map<String, double>;
    final image.Image processedImage = await effect.apply(decodedImage, params);
    final result = await encodeImage(processedImage);
    return result.isEmpty ? Uint8List(0) : result;
  }

  Future<void> _saveChanges() async {
    await _initCompleter.future;
    if (_isProcessing || _selectedEffect == null || _decodedImage == null || !mounted) {
      debugPrint('Cannot save changes: processing, no effect, no image, or disposed');
      return;
    }

    setState(() => _isProcessing = true);
    try {
      debugPrint('Saving effect: ${_selectedEffect!.name} with params: $_effectParams');
      final processedBytes = await compute(_processEffect, {
        'image': _decodedImage!,
        'effect': _selectedEffect!,
        'params': _effectParams,
      });
      if (processedBytes.isEmpty) {
        throw Exception('Empty processed bytes for effect ${_selectedEffect!.name}');
      }
      if (mounted) {
        widget.onApply(processedBytes);
      }
    } catch (e, stackTrace) {
      debugPrint('Ошибка сохранения эффекта ${_selectedEffect?.name}: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)?.errorApplyEffect ?? 'Не удалось сохранить эффект'}: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
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
                      vertical: isDesktop ? 16 : 8,
                    ),
                    child: _isInitialized
                        ? RepaintBoundary(
                      key: _imageKey,
                      child: Image.memory(
                        _currentImageBytes,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Error displaying image: $error\n$stackTrace');
                          return Center(
                            child: Text(
                              appLocalizations?.invalidImage ?? 'Не удалось загрузить изображение',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
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
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            appLocalizations?.loading ?? 'Загрузка...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildEffectControls(appLocalizations, theme, isDesktop),
                _buildEffectList(theme, isDesktop),
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
                        appLocalizations?.processingEffect ?? 'Обработка эффекта...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
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

  Widget _buildAppBar(AppLocalizations? appLocalizations, ThemeData theme, bool isDesktop) {
    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.7),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close, color: Colors.redAccent, size: isDesktop ? 28 : 24),
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
            Icons.check,
            color: _isProcessing || _selectedEffect == null ? Colors.grey[700] : Colors.green,
            size: isDesktop ? 28 : 24,
          ),
          onPressed: _isProcessing || _selectedEffect == null ? null : _saveChanges,
          tooltip: appLocalizations?.applyEffect ?? 'Применить эффект',
        ),
      ],
    );
  }

  Widget _buildEffectControls(AppLocalizations? appLocalizations, ThemeData theme, bool isDesktop) {
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
                      divisions: ((param.maxValue - param.minValue) / param.step).round(),
                      activeColor: theme.primaryColor,
                      inactiveColor: theme.disabledColor,
                      label: (_effectParams[param.name] ?? param.defaultValue).toStringAsFixed(1),
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

  Widget _buildEffectList(ThemeData theme, bool isDesktop) {
    final previewSize = isDesktop ? 100.0 : 80.0;
    final fontSize = isDesktop ? 12.0 : 10.0;

    if (!_isInitialized) {
      return Container(
        height: isDesktop ? 140 : 120,
        color: Colors.black.withOpacity(0.7),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    }

    return Container(
      height: isDesktop ? 140 : 120,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16 : 8,
        vertical: isDesktop ? 12 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: effects.length,
        itemBuilder: (context, index) {
          final effect = effects[index];
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
                  _applyEffect(effect, Map.from(effect.defaultParams));
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
                        color: _selectedEffect == effect ? Colors.blue : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: FutureBuilder<Uint8List>(
                        future: _generateEffectPreview(effect),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('Ошибка загрузки превью для ${effect.name}: $error\n$stackTrace');
                                return const Center(
                                  child: Icon(Icons.error, color: Colors.red, size: 24),
                                );
                              },
                            );
                          }
                          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: previewSize,
                    child: Text(
                      effect.name,
                      style: TextStyle(
                        color: _selectedEffect == effect ? Colors.blue : Colors.white,
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