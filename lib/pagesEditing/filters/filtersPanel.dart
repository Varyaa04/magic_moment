import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:MagicMoment/database/editHistory.dart';
import 'package:MagicMoment/database/magicMomentDatabase.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'exampleFilters.dart';

class FiltersPanel extends StatefulWidget {
  final Uint8List imageBytes;
  final int imageId; // Добавлено для привязки к базе данных
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;
  final Function(Uint8List, {String? action, String? operationType, Map<String, dynamic>? parameters}) onUpdateImage;

  const FiltersPanel({
    required this.imageBytes,
    required this.imageId,
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
  final int _maxCacheSize = 10;
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _history = [];
  int _historyIndex = -1;

  final Map<String, List<MapEntry<String, List<double>>>> _filterCategories = {
    // ... без изменений ...
  };

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _previewCache.clear();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      _originalImageBytes = widget.imageBytes;
      _previewImageBytes = widget.imageBytes;
      await _verifyImage(widget.imageBytes);
      if (mounted) {
        setState(() {
          _history.add({
            'image': widget.imageBytes,
            'action': AppLocalizations.of(context)?.filters ?? 'Filters',
            'operationType': 'init',
            'parameters': {},
          });
          _historyIndex = 0;
        });
      }
    } catch (e) {
      _handleError(AppLocalizations.of(context)?.error ?? 'Error', 'Initialization error: $e');
      if (mounted) widget.onCancel();
    }
  }

  Future<void> _verifyImage(Uint8List bytes) async {
    try {
      if (bytes.isEmpty) {
        throw Exception(AppLocalizations.of(context)?.noImages ?? 'No image provided');
      }
      final image = await _loadImage(bytes);
      final byteData = await image.toByteData();
      image.dispose(); // Освобождаем ресурс
      if (byteData == null) {
        throw Exception(AppLocalizations.of(context)?.invalidImage ?? 'Invalid image format');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _resetFilters() async {
    final localizations = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations?.warning ?? 'Warning'),
        content: Text(localizations?.unsavedChangesWarning ?? 'Reset all filters?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(localizations?.yes ?? 'Yes', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() {
        _previewImageBytes = widget.imageBytes;
        _pendingFilter = null;
        _currentFilterName = null;
        _previewCache.clear();
      });
      await widget.onUpdateImage(
        widget.imageBytes,
        action: localizations?.reset ?? 'Reset filters',
        operationType: 'reset',
        parameters: {},
      );
      debugPrint('Filters reset');
    }
  }

  Future<void> _undo() async {
    if (_isProcessing || _historyIndex <= 0) return;

    setState(() => _isProcessing = true);
    final localizations = AppLocalizations.of(context);
    try {
      if (mounted) {
        setState(() {
          _historyIndex--;
          _previewImageBytes = _history[_historyIndex]['image'];
          _pendingFilter = null;
          _currentFilterName = null;
        });
      }

      await widget.onUpdateImage(
        _previewImageBytes,
        action: localizations?.undo ?? 'Undo filter',
        operationType: 'undo',
        parameters: {
          'previous_action': _history[_historyIndex + 1]['action'],
        },
      );
      debugPrint('Undo filter, history index: $_historyIndex');
    } catch (e) {
      _handleError(localizations?.error ?? 'Error', 'Undo error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _applyCurrentFilter() async {
    if (_pendingFilter == null || _isProcessing) return;

    setState(() => _isProcessing = true);
    final localizations = AppLocalizations.of(context);
    try {
      final filteredBytes = _currentFilterName == 'Original'
          ? _originalImageBytes
          : await _applyFilterToImage(_originalImageBytes, _pendingFilter!);

      String? snapshotPath;
      List<int>? snapshotBytes;
      if (!kIsWeb) {
        final tempDir = await Directory.systemTemp.createTemp();
        snapshotPath = '${tempDir.path}/filter_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(snapshotPath);
        await file.writeAsBytes(filteredBytes);
      } else {
        snapshotBytes = filteredBytes;
      }

      final history = EditHistory(
        imageId: widget.imageId,
        operationType: 'filter',
        operationParameters: {'filter_name': _currentFilterName},
        operationDate: DateTime.now(),
        snapshotPath: snapshotPath,
        snapshotBytes: snapshotBytes,
      );
      final db = MagicMomentDatabase.instance;
      final historyId = await db.insertHistory(history);

      if (mounted) {
        setState(() {
          if (_historyIndex < _history.length - 1) {
            _history.removeRange(_historyIndex + 1, _history.length);
          }
          _history.add({
            'image': filteredBytes,
            'action': _currentFilterName == 'Original'
                ? (localizations?.reset ?? 'Reset to Original')
                : '${localizations?.filters ?? 'Filters'}: $_currentFilterName',
            'operationType': 'filter',
            'parameters': {'filter_name': _currentFilterName, 'historyId': historyId},
          });
          _historyIndex++;
          _pendingFilter = null;
          _currentFilterName = null;
        });

        await widget.onUpdateImage(
          filteredBytes,
          action: _currentFilterName == 'Original'
              ? (localizations?.reset ?? 'Reset to Original')
              : '${localizations?.filters ?? 'Filters'}: $_currentFilterName',
          operationType: 'filter',
          parameters: {'filter_name': _currentFilterName, 'historyId': historyId},
        );

        widget.onApply(filteredBytes);
      }
    } catch (e) {
      _handleError(localizations?.errorApplyFilter ?? 'Error applying filter', 'Error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _resetPreview() {
    if (mounted) {
      setState(() {
        _previewImageBytes = _history[_historyIndex]['image'];
        _pendingFilter = null;
        _currentFilterName = null;
      });
      debugPrint('Preview reset');
    }
  }

  Future<Uint8List> _generateFilterPreview(Uint8List bytes, List<double> matrix) async {
    ui.Image? image;
    ui.PictureRecorder? recorder;
    try {
      if (!_isValidMatrix(matrix)) {
        throw Exception(AppLocalizations.of(context)?.invalidFilter ?? 'Invalid filter matrix');
      }
      image = await _loadImage(bytes);
      recorder = ui.PictureRecorder();
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
      previewImage.dispose();
      if (byteData == null) {
        throw Exception(AppLocalizations.of(context)?.invalidImage ?? 'Failed to convert preview');
      }
      return byteData.buffer.asUint8List();
    } catch (e) {
      _handleError(AppLocalizations.of(context)?.error ?? 'Error', 'Error generating filter preview: $e');
      rethrow;
    } finally {
      image?.dispose();
      recorder?.endRecording();
    }
  }

  Future<void> _previewFilter(String name, List<double> matrix) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      final previewBytes = name == 'Original'
          ? _originalImageBytes
          : await _applyFilterToImage(_originalImageBytes, matrix);
      if (mounted) {
        setState(() {
          _previewImageBytes = previewBytes;
          _currentFilterName = name;
          _pendingFilter = name == 'Original' ? null : matrix;
        });
        debugPrint('Filter preview applied: $name');
      }
    } catch (e) {
      _handleError(AppLocalizations.of(context)?.error ?? 'Error', 'Error previewing filter $name: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<Uint8List> _applyFilterToImage(Uint8List bytes, List<double> matrix) async {
    ui.Image? image;
    ui.PictureRecorder? recorder;
    try {
      if (!_isValidMatrix(matrix)) {
        throw Exception(AppLocalizations.of(context)?.invalidFilter ?? 'Invalid filter matrix');
      }
      image = await _loadImage(bytes);
      recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()
        ..colorFilter = ColorFilter.matrix(matrix)
        ..filterQuality = FilterQuality.high;

      canvas.drawImage(image, Offset.zero, paint);
      final picture = recorder.endRecording();
      final filteredImage = await picture.toImage(image.width, image.height);
      final byteData = await filteredImage.toByteData(format: ui.ImageByteFormat.png);
      filteredImage.dispose();
      if (byteData == null) {
        throw Exception(AppLocalizations.of(context)?.invalidImage ?? 'Failed to convert image');
      }
      return byteData.buffer.asUint8List();
    } catch (e) {
      _handleError(AppLocalizations.of(context)?.errorApplyFilter ?? 'Error applying filter', 'Error: $e');
      rethrow;
    } finally {
      image?.dispose();
      recorder?.endRecording();
    }
  }

  Future<ui.Image> _loadImage(Uint8List bytes) async {
    try {
      if (bytes.isEmpty) {
        throw Exception(AppLocalizations.of(context)?.noImages ?? 'No image provided');
      }
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 1024,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      codec.dispose();
      return image;
    } catch (e) {
      _handleError(AppLocalizations.of(context)?.error ?? 'Error', 'Error loading image: $e');
      throw Exception(AppLocalizations.of(context)?.invalidImage ?? 'Failed to load image');
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

  void _handleError(String title, String message) {
    debugPrint(message);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title: $message'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(localizations),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: RepaintBoundary(
                      key: ValueKey(_previewImageBytes),
                      child: Image.memory(
                        _previewImageBytes,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Error displaying image: $error');
                          return Center(
                            child: Text(
                              localizations?.invalidImage ?? 'Failed to load image',
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                _buildFilterList(localizations),
              ],
            ),
            if (_isProcessing)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.blueAccent),
                      const SizedBox(height: 16),
                      Text(
                        localizations?.processingFilter ?? 'Processing filter...',
                        style: const TextStyle(color: Colors.white),
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

  Widget _buildAppBar(AppLocalizations? localizations) {
    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.7),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.redAccent),
        onPressed: widget.onCancel,
        tooltip: localizations?.cancel ?? 'Cancel',
      ),
      title: Text(
        _currentFilterName ?? (localizations?.filters ?? 'Filters'),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.undo, color: _historyIndex > 0 ? Colors.white : Colors.grey[700]),
          onPressed: _historyIndex > 0 && !_isProcessing ? _undo : null,
          tooltip: localizations?.undo ?? 'Undo',
        ),
        IconButton(
          icon: const Icon(Icons.restart_alt, color: Colors.white),
          onPressed: _isProcessing ? null : _resetFilters,
          tooltip: localizations?.reset ?? 'Reset',
        ),
        if (_pendingFilter != null)
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _resetPreview,
            tooltip: localizations?.cancelPreview ?? 'Cancel preview',
          ),
        IconButton(
          icon: const Icon(Icons.check, color: Colors.green),
          onPressed: _pendingFilter != null && !_isProcessing ? _applyCurrentFilter : null,
          tooltip: localizations?.applyFilter ?? 'Apply Filter',
        ),
      ],
    );
  }

  Widget _buildFilterList(AppLocalizations? localizations) {
    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: DefaultTabController(
        length: _filterCategories.length,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[700],
              indicatorColor: Colors.blueAccent,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: _filterCategories.keys.map((category) => Tab(text: category)).toList(),
            ),
            Expanded(
              child: TabBarView(
                children: _filterCategories.entries.map((category) {
                  return ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: category.value.length,
                    itemBuilder: (context, index) {
                      final entry = category.value[index];
                      return _buildFilterPreview(entry.key, entry.value, localizations);
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

  Widget _buildFilterPreview(String name, List<double> matrix, AppLocalizations? localizations) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _previewFilter(name, matrix),
            onDoubleTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(localizations?.filters ?? 'Filters'),
                  content: Text(
                    '${localizations?.filter ?? 'Filter'}: $name\n'
                        '${localizations?.description ?? 'Description'}: $name',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(localizations?.ok ?? 'OK'),
                    ),
                  ],
                ),
              );
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _currentFilterName == name ? Colors.blueAccent : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: name == 'Original'
                    ? Image.memory(
                  _originalImageBytes,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Error loading original preview: $error');
                    return const Center(
                      child: Icon(Icons.error, color: Colors.red, size: 24),
                    );
                  },
                )
                    : FutureBuilder<Uint8List>(
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
                    return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: TextStyle(
              color: _currentFilterName == name ? Colors.blueAccent : Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
    if (_previewCache.length >= _maxCacheSize) {
      _previewCache.remove(_previewCache.keys.first);
    }
    _previewCache[name] = preview;
    return preview;
  }
}