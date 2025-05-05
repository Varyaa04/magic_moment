import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as image;
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'effects_utils.dart';

class EffectsPanel extends StatefulWidget {
  final Uint8List image;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;

  const EffectsPanel({
    required this.image,
    required this.onCancel,
    required this.onApply,
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

  @override
  void initState() {
    super.initState();
    _currentImageBytes = widget.image;
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final image.Image decodedImage = await decodeImage(widget.image);
      setState(() {
        _isInitialized = true;
        _selectedEffect = effects.first;
        _effectParams.addAll(_selectedEffect!.defaultParams);
      });
    } catch (e) {
      debugPrint('Error initializing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid image format')),
        );
        widget.onCancel();
      }
    }
  }

  Future<void> _applyEffect(Effect effect, Map<String, double> params) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      final image.Image decodedImage = await decodeImage(widget.image);
      final image.Image processedImage = await effect.apply(decodedImage, params);
      final Uint8List processedBytes = await encodeImage(processedImage);
      setState(() {
        _currentImageBytes = processedBytes;
        _selectedEffect = effect;
        _effectParams.clear();
        _effectParams.addAll(params);
      });
    } catch (e) {
      debugPrint('Error applying effect: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to apply effect')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveChanges() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      final image.Image decodedImage = await decodeImage(widget.image);
      final image.Image processedImage = await _selectedEffect!.apply(decodedImage, _effectParams);
      final Uint8List processedBytes = await encodeImage(processedImage);
      widget.onApply(processedBytes);
    } catch (e) {
      debugPrint('Error saving image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save image')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
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
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
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
      title: Text(
        AppLocalizations.of(context)?.effects ?? 'Effects',
        style: const TextStyle(color: Colors.white),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.check, color: Colors.white),
          onPressed: _isProcessing ? null : _saveChanges,
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
              Text(
                param.name,
                style: const TextStyle(color: Colors.white),
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
                  label: _effectParams[param.name]?.toStringAsFixed(1),
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
              onTap: () => _applyEffect(effect, effect.defaultParams),
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
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.error,
                                color: Colors.red,
                                size: 40,
                              ),
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
      final image.Image decodedImage = await decodeImage(widget.image);
      final image.Image thumbnail = image.copyResize(decodedImage, width: 100);
      final image.Image processedImage = await effect.apply(thumbnail, effect.defaultParams);
      return await encodeImage(processedImage);
    } catch (e) {
      debugPrint('Error generating preview: $e');
      rethrow;
    }
  }
}