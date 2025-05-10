import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'effects_utils.dart';

class EffectsPanel extends StatefulWidget {
  final Uint8List image;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;
  final Future<void> Function(
      Uint8List, {
      required String action,
      required String operationType,
      required Map<String, dynamic> parameters,
      })? onUpdateImage;

  const EffectsPanel({
    required this.image,
    required this.onCancel,
    required this.onApply,
    this.onUpdateImage,
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
  final _thumbnailWidth = 80;

  @override
  void initState() {
    super.initState();
    _currentImageBytes = widget.image;
    _initialize();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _previewCache.clear();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      _decodedImage = await decodeImage(widget.image);
      if (_decodedImage == null) {
        throw Exception('Failed to decode image');
      }
      setState(() {
        _isInitialized = true;
        _selectedEffect = effects.isNotEmpty ? effects.first : null;
        if (_selectedEffect != null) {
          _effectParams.addAll(_selectedEffect!.defaultParams);
        }
      });
      if (_selectedEffect != null) {
        await _applyEffect(_selectedEffect!, _effectParams, force: true);
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid image format: $e')),
        );
        widget.onCancel();
      }
    }
  }

  Future<void> _generatePreview(Effect effect) async {
    if (_previewCache.containsKey(effect.name) || _decodedImage == null) return;
    try {
      final thumbnail = img.copyResize(_decodedImage!, width: _thumbnailWidth);
      final processedImage = await effect.apply(thumbnail, effect.defaultParams);
      final previewBytes = await encodeImage(processedImage);
      if (mounted) {
        setState(() {
          _previewCache[effect.name] = previewBytes;
        });
      }
    } catch (e) {
      debugPrint('Error generating preview for ${effect.name}: $e');
    }
  }

  Future<void> _applyEffect(Effect effect, Map<String, double> params, {bool force = false}) async {
    if (_isProcessing && !force) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () async {
      setState(() => _isProcessing = true);
      try {
        if (_decodedImage == null) {
          throw Exception('Image not decoded');
        }
        final processedImage = await effect.apply(_decodedImage!, params);
        final processedBytes = await encodeImage(processedImage);
        if (!mounted) return;
        setState(() {
          _currentImageBytes = processedBytes;
          _selectedEffect = effect;
          _effectParams.clear();
          _effectParams.addAll(params);
        });
      } catch (e) {
        debugPrint('Error applying effect ${effect.name}: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to apply effect ${effect.name}: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    });
  }

  Future<void> _updateImage(
      Uint8List newImage, {
        required String action,
        required String operationType,
        required Map<String, dynamic> parameters,
      }) async {
    try {
      if (widget.onUpdateImage != null) {
        await widget.onUpdateImage!(newImage, action: action, operationType: operationType, parameters: parameters);
      }
    } catch (e) {
      debugPrint('Error in onUpdateImage: $e');
      rethrow;
    }
  }

  Future<void> _saveChanges() async {
    if (_isProcessing || _selectedEffect == null || _decodedImage == null) return;

    setState(() => _isProcessing = true);
    try {
      final processedImage = await _selectedEffect!.apply(_decodedImage!, _effectParams);
      final processedBytes = await encodeImage(processedImage);
      if (!mounted) return;

      await _updateImage(
        processedBytes,
        action: 'Applied effect: ${_selectedEffect!.name}',
        operationType: 'effect',
        parameters: {
          'effect_name': _selectedEffect!.name,
          ..._effectParams,
        },
      );

      widget.onApply(processedBytes);
    } catch (e) {
      debugPrint('Error saving effect: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save effect: $e')),
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

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(theme),
                Expanded(
                  child: _isInitialized
                      ? RepaintBoundary(
                    key: _imageKey,
                    child: Image.memory(
                      _currentImageBytes,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Image display error: $error');
                        return const Center(
                          child: Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      },
                    ),
                  )
                      : const Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
                if (_selectedEffect != null) _buildEffectControls(appLocalizations, theme),
                _buildEffectList(theme),
              ],
            ),
            if (_isProcessing)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.7),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: widget.onCancel,
        tooltip: 'Cancel',
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.check, color: Colors.white),
          onPressed: _isProcessing || _selectedEffect == null ? null : _saveChanges,
          tooltip: 'Apply',
        ),
      ],
    );
  }

  Widget _buildEffectControls(AppLocalizations? appLocalizations, ThemeData theme) {
    if (_selectedEffect == null || _selectedEffect!.params.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.black.withOpacity(0.7),
      child: Column(
        children: _selectedEffect!.params.map((param) {
          return Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  param.name,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Slider(
                  value: _effectParams[param.name] ?? param.defaultValue,
                  min: param.minValue,
                  max: param.maxValue,
                  divisions: ((param.maxValue - param.minValue) / param.step).round(),
                  activeColor: theme.primaryColor,
                  inactiveColor: theme.disabledColor,
                  label: (_effectParams[param.name] ?? param.defaultValue).toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      _effectParams[param.name] = value;
                    });
                    _applyEffect(_selectedEffect!, _effectParams);
                  },
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEffectList(ThemeData theme) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.black.withOpacity(0.7),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: effects.length,
        itemBuilder: (context, index) {
          final effect = effects[index];
          return FutureBuilder<void>(
            future: _generatePreview(effect),
            builder: (context, snapshot) {
              final previewBytes = _previewCache[effect.name];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () {
                    if (!_isProcessing) {
                      _applyEffect(effect, Map.from(effect.defaultParams));
                    }
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _selectedEffect == effect ? Colors.blue : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: previewBytes != null
                              ? Image.memory(
                            previewBytes,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Preview load error for ${effect.name}: $error');
                              return const Icon(Icons.error, color: Colors.red, size: 30);
                            },
                          )
                              : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        effect.name,
                        style: TextStyle(
                          color: _selectedEffect == effect ? Colors.blue : Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}