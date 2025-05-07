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
  Effect? _selectedEffect;
  final GlobalKey _imageKey = GlobalKey();
  final Map<String, double> _effectParams = {};
  DateTime _lastUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _currentImageBytes = widget.image;
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      debugPrint('Initializing EffectsPanel');
      final img.Image decodedImage = await decodeImage(widget.image);
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _selectedEffect = effects.first;
          _effectParams.addAll(_selectedEffect!.defaultParams);
        });
        await _applyEffect(_selectedEffect!, _effectParams, force: true);
      }
    } catch (e, stackTrace) {
      debugPrint('Error initializing image: $e\nStackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid image format: $e')),
        );
        widget.onCancel();
      }
    }
  }

  Future<void> _applyEffect(Effect effect, Map<String, double> params, {bool force = false}) async {
    if (_isProcessing && !force) return;

    final now = DateTime.now();
    if (!force && now.difference(_lastUpdate).inMilliseconds < 100) return;
    _lastUpdate = now;

    setState(() => _isProcessing = true);
    try {
      debugPrint('Applying effect: ${effect.name}');
      final img.Image decodedImage = await decodeImage(widget.image);
      final img.Image processedImage = await effect.apply(decodedImage, params);
      final Uint8List processedBytes = await encodeImage(processedImage);
      if (mounted) {
        setState(() {
          _currentImageBytes = processedBytes;
          _selectedEffect = effect;
          _effectParams.clear();
          _effectParams.addAll(params);
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error applying effect ${effect.name}: $e\nStackTrace: $stackTrace');
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
  }

  Future<void> _updateImage(
      Uint8List newImage, {
        required String action,
        required String operationType,
        required Map<String, dynamic> parameters,
      }) async {
    try {
      debugPrint('Updating image with action: $action');
      if (widget.onUpdateImage != null) {
        await widget.onUpdateImage!(newImage, action: action, operationType: operationType, parameters: parameters);
      }
    } catch (e, stackTrace) {
      debugPrint('Error in onUpdateImage: $e\nStackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _saveChanges() async {
    if (_isProcessing || _selectedEffect == null) {
      debugPrint('Save aborted: Processing=$_isProcessing, SelectedEffect=$_selectedEffect');
      return;
    }

    setState(() => _isProcessing = true);
    try {
      debugPrint('Saving changes with effect: ${_selectedEffect!.name}');
      final img.Image decodedImage = await decodeImage(widget.image);
      final img.Image processedImage = await _selectedEffect!.apply(decodedImage, _effectParams);
      final Uint8List processedBytes = await encodeImage(processedImage);

      debugPrint('Image encoded, bytes length: ${processedBytes.length}');
      await _updateImage(
        processedBytes,
        action: 'Applied effect: ${_selectedEffect!.name}',
        operationType: 'effect',
        parameters: {
          'effect_name': _selectedEffect!.name,
          ..._effectParams,
        },
      );

      debugPrint('Calling onApply');
      widget.onApply(processedBytes);
    } catch (e, stackTrace) {
      debugPrint('Error saving image: $e\nStackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save image: $e')),
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
                    child: Center(
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
                    ),
                  )
                      : const Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
                _buildEffectControls(appLocalizations, theme),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withOpacity(0.7),
      child: Column(
        children: _selectedEffect!.params.map((param) {
          return Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  param.name,
                  style: const TextStyle(color: Colors.white),
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
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.black.withOpacity(0.7),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: effects.length,
        itemBuilder: (context, index) {
          final effect = effects[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: () => _applyEffect(effect, Map.from(effect.defaultParams)),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
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
                          if (snapshot.hasData) {
                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('Error loading preview for ${effect.name}: $error');
                                return const Icon(
                                  Icons.error,
                                  color: Colors.red,
                                  size: 40,
                                );
                              },
                            );
                          }
                          if (snapshot.hasError) {
                            debugPrint('Preview error for ${effect.name}: ${snapshot.error}');
                            return const Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 40,
                            );
                          }
                          return const Center(child: CircularProgressIndicator());
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    effect.name,
                    style: TextStyle(
                      color: _selectedEffect == effect ? Colors.blue : Colors.white,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<Uint8List> _generateEffectPreview(Effect effect) async {
    try {
      debugPrint('Generating preview for effect: ${effect.name}');
      final img.Image decodedImage = await decodeImage(widget.image);
      final img.Image thumbnail = img.copyResize(decodedImage, width: 100);
      final img.Image processedImage = await effect.apply(thumbnail, effect.defaultParams);
      final Uint8List previewBytes = await encodeImage(processedImage);
      debugPrint('Preview generated, bytes length: ${previewBytes.length}');
      return previewBytes;
    } catch (e, stackTrace) {
      debugPrint('Error generating preview for ${effect.name}: $e\nStackTrace: $stackTrace');
      rethrow;
    }
  }
}