import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'exampleFilters.dart';

class FiltersPanel extends StatefulWidget {
  final Uint8List imageBytes;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;
  final Function(Uint8List, {String? action, String? operationType, Map<String, dynamic>? parameters}) onUpdateImage;

  const FiltersPanel({
    required this.imageBytes,
    required this.onCancel,
    required this.onApply,
    required this.onUpdateImage,
    super.key,
  });

  @override
  _FiltersPanelState createState() => _FiltersPanelState();
}

class _FiltersPanelState extends State<FiltersPanel> {
  late Uint8List _originalImageBytes;
  late Uint8List _previewImageBytes;
  bool _isProcessing = false;
  String? _currentFilterName;
  List<double>? _pendingFilter;
  final Map<String, Uint8List> _previewCache = {};
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _history = [];
  int _historyIndex = -1;

  // Organized filters into categories for better UX
  final Map<String, List<MapEntry<String, List<double>>>> _filterCategories = {
    'Classic': [
      MapEntry('Original', [
        1.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ]),
      MapEntry('Black & White', bw),
      MapEntry('Sepia', sepium),
      MapEntry('Vintage', vintage),
      MapEntry('Retro', retro),
    ],
    'Colorful': [
      MapEntry('Purple', purple),
      MapEntry('Yellow', yellow),
      MapEntry('Cyan', cyan),
      MapEntry('Vibrant Life', vibrantLife),
      MapEntry('Playful Colors', playfulColors),
    ],
    'Mood': [
      MapEntry('Warmth', warmth),
      MapEntry('Cold Life', coldLife),
      MapEntry('Serenity', serenity),
      MapEntry('Sadness', sadness),
      MapEntry('Emotions', emotions),
    ],
    'Nature': [
      MapEntry('Summer Freshness', summerFreshness),
      MapEntry('Misty Morning', mistyMorning),
      MapEntry('Sunlit Grove', sunlitGrove),
      MapEntry('Calm Waves', calmWaves),
      MapEntry('Fresh Mint', freshMint),
    ],
    'Artistic': [
      MapEntry('Contrast', contrast),
      MapEntry('Shining', shining),
      MapEntry('Ethereal Glow', etherealGlow),
      MapEntry('Cyber Style', cyberStyle),
      MapEntry('Artistic Blend', artisticBlend),
    ],
  };

  @override
  void initState() {
    super.initState();
    _originalImageBytes = widget.imageBytes;
    _previewImageBytes = widget.imageBytes;
    _verifyImage(widget.imageBytes);
    // Initialize history with the original image
    _history.add({
      'image': widget.imageBytes,
      'action': 'Initial image',
      'operationType': 'init',
      'parameters': {},
    });
    _historyIndex = 0;
  }

  Future<void> _verifyImage(Uint8List bytes) async {
    try {
      final image = await _loadImage(bytes);
      final byteData = await image.toByteData();
      if (byteData == null) {
        throw Exception('Failed to get byte data for image verification');
      }
    } catch (e) {
      debugPrint('Image verification failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid image format: $e')),
        );
        widget.onCancel();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _undo() async {
    if (_isProcessing || _historyIndex <= 0) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      setState(() {
        _historyIndex--;
        _previewImageBytes = _history[_historyIndex]['image'];
        _pendingFilter = null;
        _currentFilterName = null;
      });

      await widget.onUpdateImage(
        _previewImageBytes,
        action: 'Undo filter',
        operationType: 'undo',
        parameters: {
          'previous_action': _history[_historyIndex + 1]['action'],
        },
      );
    } catch (e) {
      debugPrint('Error undoing filter: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to undo: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Image.memory(
                      _previewImageBytes,
                      key: ValueKey(_previewImageBytes),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Error displaying image: $error');
                        return const Center(
                          child: Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                _buildFilterList(),
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

  Widget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.7),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: widget.onCancel,
        tooltip: 'Cancel',
      ),
      title: Text(
        _currentFilterName ?? 'Filters',
        style: const TextStyle(color: Colors.white),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.undo, color: Colors.white),
          onPressed: _historyIndex > 0 && !_isProcessing ? _undo : null,
          tooltip: 'Undo',
        ),
        if (_pendingFilter != null)
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _resetPreview,
            tooltip: 'Cancel filter preview',
          ),
        IconButton(
          icon: const Icon(Icons.check, color: Colors.white),
          onPressed: _pendingFilter != null && !_isProcessing ? _applyCurrentFilter : null,
          tooltip: 'Apply',
        ),
      ],
    );
  }

  Widget _buildFilterList() {
    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DefaultTabController(
        length: _filterCategories.length,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: _filterCategories.keys.map((category) => Tab(text: category)).toList(),
            ),
            Expanded(
              child: TabBarView(
                children: _filterCategories.entries.map((category) {
                  return ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: category.value.length,
                    itemBuilder: (context, index) {
                      final entry = category.value[index];
                      return _buildFilterPreview(entry.key, entry.value);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPreview(String name, List<double> matrix) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _previewFilter(name, matrix),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _currentFilterName == name ? Colors.blue : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: FutureBuilder<Uint8List>(
                  future: _getCachedPreview(name, matrix),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
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
                    if (snapshot.hasError) {
                      debugPrint('Snapshot error for $name: ${snapshot.error}');
                      return const Center(
                        child: Icon(Icons.error, color: Colors.red, size: 24),
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _getCachedPreview(String name, List<double> matrix) async {
    if (_previewCache.containsKey(name)) {
      return _previewCache[name]!;
    }
    final preview = await _generateFilterPreview(_originalImageBytes, matrix);
    _previewCache[name] = preview;
    return preview;
  }

  Future<Uint8List> _generateFilterPreview(Uint8List bytes, List<double> matrix) async {
    try {
      if (!_isValidMatrix(matrix)) {
        throw Exception('Invalid filter matrix for preview');
      }
      final image = await _loadImage(bytes);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()
        ..colorFilter = ColorFilter.matrix(matrix)
        ..filterQuality = FilterQuality.high;

      final scale = 80 / image.width;
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(0, 0, image.width * scale, image.height * scale),
        paint,
      );
      final picture = recorder.endRecording();
      final previewImage = await picture.toImage(80, (image.height * scale).round());
      final byteData = await previewImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert preview image to bytes');
      }
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error generating filter preview: $e');
      rethrow;
    }
  }

  Future<void> _previewFilter(String name, List<double> matrix) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _currentFilterName = name;
      _pendingFilter = matrix;
    });

    try {
      final previewBytes = await _applyFilterToImage(_originalImageBytes, matrix);
      setState(() {
        _previewImageBytes = previewBytes;
      });
    } catch (e) {
      debugPrint('Error previewing filter $name: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to preview filter $name: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _applyCurrentFilter() async {
    if (_pendingFilter == null || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final filteredBytes = await _applyFilterToImage(_originalImageBytes, _pendingFilter!);
      // Add to history
      setState(() {
        // Remove future history entries if any
        if (_historyIndex < _history.length - 1) {
          _history.removeRange(_historyIndex + 1, _history.length);
        }
        _history.add({
          'image': filteredBytes,
          'action': 'Applied $_currentFilterName filter',
          'operationType': 'filter',
          'parameters': {'filter_name': _currentFilterName},
        });
        _historyIndex++;
      });

      await widget.onUpdateImage(
        filteredBytes,
        action: 'Applied $_currentFilterName filter',
        operationType: 'filter',
        parameters: {'filter_name': _currentFilterName},
      );

      widget.onApply(filteredBytes);
    } catch (e) {
      debugPrint('Error applying filter: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply filter: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _resetPreview() {
    setState(() {
      _previewImageBytes = _history[_historyIndex]['image'];
      _pendingFilter = null;
      _currentFilterName = null;
    });
  }

  Future<Uint8List> _applyFilterToImage(Uint8List bytes, List<double> matrix) async {
    try {
      if (!_isValidMatrix(matrix)) {
        throw Exception('Invalid filter matrix');
      }
      final image = await _loadImage(bytes);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()
        ..colorFilter = ColorFilter.matrix(matrix)
        ..filterQuality = FilterQuality.high;

      canvas.drawImage(image, Offset.zero, paint);
      final picture = recorder.endRecording();
      final filteredImage = await picture.toImage(image.width, image.height);
      final byteData = await filteredImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert filtered image to bytes');
      }
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error applying filter to image: $e');
      rethrow;
    }
  }

  Future<ui.Image> _loadImage(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 1024,
      );
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      debugPrint('Error loading image: $e');
      throw Exception('Failed to load image: $e');
    }
  }

  bool _isValidMatrix(List<double> matrix) {
    if (matrix.length != 20) {
      debugPrint('Invalid matrix length: ${matrix.length}');
      return false;
    }
    for (var value in matrix) {
      if (value.isNaN || value.isInfinite) {
        debugPrint('Invalid matrix value: $value');
        return false;
      }
    }
    return true;
  }
}