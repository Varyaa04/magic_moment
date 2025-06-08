import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'exampleFilters.dart';

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

class FiltersPanel extends StatefulWidget {
  final Uint8List imageBytes;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;
  final int imageId;
  final Function(Uint8List, {String? action, String? operationType, Map<String, dynamic>? parameters}) onUpdateImage;

  const FiltersPanel({
    required this.imageBytes,
    required this.onCancel,
    required this.onApply,
    required this.imageId,
    required this.onUpdateImage,
    super.key,
  });

  @override
  _FiltersPanelState createState() => _FiltersPanelState();
}

class _FiltersPanelState extends State<FiltersPanel> {
  late Uint8List _currentImageBytes;
  double _scaleFactor = 1.0;
  final ValueNotifier<double> _filterStrength = ValueNotifier(1.0);
  bool _isProcessing = false;
  List<double> _currentFilter = [
    1.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ];
  String? _currentFilterName;
  String _currentFilterGroup = 'Basic'; // Текущая группа фильтров

  final List<double> _identityMatrix = [
    1.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ];

  // Группы фильтров
  final Map<String, Map<String, List<double>>> _filterGroups = {
    'Basic': {
      'Original': [
        1.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
      'Black & White': bw,
      'Sepia': sepium,
      'Contrast': contrast,
      'Vintage': vintage,
    },
    'Color': {
      'Purple': purple,
      'Yellow': yellow,
      'Cyan': cyan,
      'Cool Blue': coolBlue,
      'Warm Sunset': warmSunset,
      'Fresh Mint': freshMint,
    },
    'Mood': {
      'Old Times': oldTimes,
      'Cold Life': coldLife,
      'Warmth': warmth,
      'Ice': ice,
      'Sadness': sadness,
      'Bright Day': brightDay,
    },
    'Artistic': {
      'Retro': retro,
      'Shades': shades,
      'Misty': misty,
      'Heatwave': heatwave,
      'Graphite': graphite,
      'Anxiety': anxiety,
    },
    'Special': {
      'Milk': milk,
      'Shining': shining,
      'Shadow': shadow,
      'Mushroom': mushroom,
      'Cold Light': coldLight,
      'Serenity': serenity,
    }
  };

  @override
  void initState() {
    super.initState();
    _currentImageBytes = widget.imageBytes;
    _verifyImage(widget.imageBytes);
  }

  @override
  void dispose() {
    _filterStrength.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(appLocalizations, isDesktop),
                _buildFilterStrengthSlider(isDesktop),
                Expanded(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    onInteractionUpdate: (details) {
                      setState(() {
                        _scaleFactor = details.scale;
                      });
                    },
                    child: Center(
                      child: Image.memory(
                        _currentImageBytes,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              appLocalizations?.invalidImage ?? 'Failed to load image',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                _buildFilterGroupTabs(isDesktop), // Moved filter group tabs here
                _buildFilterList(isDesktop),
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
                        appLocalizations?.processingFilter ?? 'Processing filter...',
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

  // Метод для отображения вкладок групп фильтров
  Widget _buildFilterGroupTabs(bool isDesktop) {
    return Container(
      height: isDesktop ? 50 : 40,
      color: Colors.black.withOpacity(0.7),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterGroups.length,
        itemBuilder: (context, index) {
          final groupName = _filterGroups.keys.elementAt(index);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(
                groupName,
                style: TextStyle(
                  color: _currentFilterGroup == groupName ? Colors.white : Colors.white70,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
                ),
              ),
              selected: _currentFilterGroup == groupName,
              onSelected: (selected) {
                setState(() {
                  _currentFilterGroup = groupName;
                });
              },
              selectedColor: Colors.blueAccent,
              backgroundColor: Colors.grey[800],
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 16 : 12,
                vertical: isDesktop ? 8 : 4,
              ),
            ),
          );
        },
      ),
    );
  }

  // Метод для отображения списка фильтров
  Widget _buildFilterList(bool isDesktop) {
    final previewSize = isDesktop ? 100.0 : 80.0;
    final currentGroupFilters = _filterGroups[_currentFilterGroup] ?? {};

    return Container(
      height: isDesktop ? 140 : 120,
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 8 : 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: ResponsiveUtils.getResponsivePadding(context),
        itemCount: currentGroupFilters.length,
        itemBuilder: (context, index) {
          final entry = currentGroupFilters.entries.elementAt(index);
          return _buildFilterPreview(entry.key, entry.value, previewSize);
        },
      ),
    );
  }

  Future<void> _verifyImage(Uint8List bytes) async {
    try {
      final image = await _loadImage(bytes);
      final byteData = await image.toByteData();
      if (byteData == null) {
        throw Exception('Invalid image format');
      }
    } catch (e) {
      debugPrint('Image verification failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.invalidImage ?? 'Invalid image format',
            ),
          ),
        );
        widget.onCancel();
      }
    }
  }

  List<double> _blendFilterMatrix(List<double> filterMatrix, double strength) {
    // Interpolate between identity matrix and filter matrix
    return List.generate(20, (i) {
      return _identityMatrix[i] + (filterMatrix[i] - _identityMatrix[i]) * strength;
    });
  }

  Widget _buildAppBar(AppLocalizations? appLocalizations, bool isDesktop) {
    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.7),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close, color: Colors.redAccent, size: isDesktop ? 28 : 24),
        onPressed: widget.onCancel,
        tooltip: appLocalizations?.cancel ?? 'Cancel',
      ),
      title: Text(
        appLocalizations?.filters ?? 'Filters',
        style: TextStyle(
          color: Colors.white,
          fontSize: isDesktop ? 20 : 16,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.check,
              color: _isProcessing ? Colors.grey[700] : Colors.green,
              size: isDesktop ? 28 : 24),
          onPressed: _isProcessing
              ? null
              : () async {
            setState(() => _isProcessing = true);
            try {
              final blendedMatrix = _blendFilterMatrix(_currentFilter, _filterStrength.value);
              final filteredBytes = await _applyFilterToOriginal(blendedMatrix);
              widget.onApply(filteredBytes);
              widget.onUpdateImage(
                filteredBytes,
                operationType: 'Filter',
                parameters: {
                  'filterName': _currentFilterName ?? 'Unknown',
                  'strength': _filterStrength.value,
                },
              );
            } catch (e) {
              debugPrint('Error applying filter: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${appLocalizations?.errorApplyFilter ?? 'Failed to apply filter'}: $e',
                    ),
                  ),
                );
              }
            } finally {
              if (mounted) setState(() => _isProcessing = false);
            }
          },
          tooltip: appLocalizations?.applyFilter ?? 'Apply Filter',
        ),
      ],
    );
  }

  Widget _buildFilterStrengthSlider(bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 8, vertical: isDesktop ? 8 : 4),
      color: Colors.black.withOpacity(0.6),
      child: Row(
        children: [
          Text(
            '${AppLocalizations.of(context)?.filterStrength ?? 'Filter Strength'}:',
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ValueListenableBuilder<double>(
              valueListenable: _filterStrength,
              builder: (context, strength, _) {
                return Slider(
                  value: strength,
                  min: 0.0,
                  max: 1.0,
                  divisions: 100,
                  activeColor: Colors.blueAccent,
                  inactiveColor: Colors.grey.withOpacity(0.5),
                  label: (strength * 100).round().toString(),
                  onChanged: _isProcessing
                      ? null
                      : (value) async {
                    _filterStrength.value = value;
                    if (_currentFilterName != 'Original') {
                      setState(() => _isProcessing = true);
                      try {
                        final blendedMatrix = _blendFilterMatrix(_currentFilter, value);
                        final filteredBytes = await _applyFilterToOriginal(blendedMatrix);
                        setState(() {
                          _currentImageBytes = filteredBytes;
                        });
                      } catch (e) {
                        debugPrint('Error adjusting filter strength: $e');
                      } finally {
                        setState(() => _isProcessing = false);
                      }
                    }
                  },
                );
              },
            ),
          ),
          Text(
            (_filterStrength.value * 100).round().toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _isProcessing
                ? null
                : () {
              _filterStrength.value = 1.0;
              if (_currentFilterName != 'Original') {
                _applyFilter(_currentFilter, _currentFilterName!);
              }
            },
            child: Text(
              AppLocalizations.of(context)?.reset ?? 'Reset',
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPreview(String name, List<double> matrix, double previewSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: _isProcessing ? null : () => _applyFilter(matrix, name),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: previewSize,
              height: previewSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _currentFilter == matrix ? Colors.blue : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: FutureBuilder<Uint8List>(
                  future: _generateFilterPreview(widget.imageBytes, matrix),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Error loading preview for $name: $error');
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
                name,
                style: TextStyle(
                  color: _currentFilter == matrix ? Colors.blue : Colors.white,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 10),
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
  }

  Future<Uint8List> _generateFilterPreview(Uint8List bytes, List<double> matrix) async {
    try {
      final blendedMatrix = _blendFilterMatrix(matrix, _filterStrength.value);
      final image = await _loadImage(bytes, targetWidth: 100);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()
        ..colorFilter = ColorFilter.matrix(blendedMatrix)
        ..filterQuality = FilterQuality.medium;

      final imageWidth = image.width.toDouble();
      final imageHeight = image.height.toDouble();
      const previewSize = 100.0;
      final aspectRatio = imageHeight / imageWidth;
      final destHeight = previewSize * aspectRatio;

      final destRect = Rect.fromLTWH(0, 0, previewSize, destHeight.clamp(1.0, 1000.0));
      final srcRect = Rect.fromLTWH(0, 0, imageWidth, imageHeight);

      canvas.drawImageRect(image, srcRect, destRect, paint);
      final picture = recorder.endRecording();
      final previewImage = await picture.toImage(
        previewSize.toInt(),
        destHeight.toInt().clamp(1, 1000),
      );
      final byteData = await previewImage.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      previewImage.dispose();
      picture.dispose();

      if (byteData == null || byteData.lengthInBytes == 0) {
        throw Exception('Failed to generate filter preview');
      }
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error generating filter preview: $e');
      return Uint8List(0);
    }
  }

  Future<void> _applyFilter(List<double> matrix, String filterName) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _currentFilter = matrix;
      _currentFilterName = filterName;
      _filterStrength.value = 1.0; // Reset strength when changing filters
    });

    try {
      final blendedMatrix = _blendFilterMatrix(matrix, _filterStrength.value);
      final filteredBytes = await _applyFilterToOriginal(blendedMatrix);
      debugPrint('Filter applied: $filterName with strength ${_filterStrength.value}');
      if (mounted) {
        setState(() {
          _currentImageBytes = filteredBytes;
        });
      }
    } catch (e) {
      debugPrint('Error applying filter: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)?.errorApplyFilter ?? 'Failed to apply filter'}: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<Uint8List> _applyFilterToOriginal(List<double> matrix) async {
    try {
      final image = await _loadImage(widget.imageBytes);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()
        ..colorFilter = ColorFilter.matrix(matrix)
        ..filterQuality = FilterQuality.high;

      canvas.drawImage(image, Offset.zero, paint);
      final picture = recorder.endRecording();
      final filteredImage = await picture.toImage(image.width, image.height);
      final byteData = await filteredImage.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      filteredImage.dispose();
      picture.dispose();

      if (byteData == null || byteData.lengthInBytes == 0) {
        throw Exception('Failed to apply filter to original image');
      }

      var filteredPixels = byteData.buffer.asUint8List();
      if (_scaleFactor != 1.0) {
        filteredPixels = await _applyScale(filteredPixels, image.width, image.height, _scaleFactor);
      }

      return filteredPixels;
    } catch (e) {
      debugPrint('Error applying filter to original: $e');
      throw Exception('Failed to apply filter: $e');
    }
  }

  Future<ui.Image> _loadImage(Uint8List bytes, {int? targetWidth}) async {
    try {
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: targetWidth,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      codec.dispose();
      return image;
    } catch (e) {
      debugPrint('Error loading image: $e');
      throw Exception('Failed to load image: $e');
    }
  }

  Future<Uint8List> _applyScale(Uint8List pixels, int width, int height, double scale) async {
    if (scale == 1.0) return pixels;

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..filterQuality = FilterQuality.high;

      final codec = await ui.instantiateImageCodec(pixels);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final newWidth = (width * scale).round();
      final newHeight = (height * scale).round();

      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()),
        paint,
      );

      final picture = recorder.endRecording();
      final scaledImage = await picture.toImage(newWidth, newHeight);
      final byteData = await scaledImage.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      scaledImage.dispose();
      picture.dispose();

      if (byteData == null) {
        throw Exception('Failed to convert scaled image to bytes');
      }
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error applying scale: $e');
      throw Exception('Failed to apply scale: $e');
    }
  }
}