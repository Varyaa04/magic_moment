import 'dart:async';
import 'dart:io' show Directory;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'package:MagicMoment/database/objectDao.dart' as dao;
import 'package:MagicMoment/database/objectsModels.dart';
import 'package:MagicMoment/database/magicMomentDatabase.dart';
import '../../database/editHistory.dart';
import 'ResponsiveUtils.dart';
import 'package:universal_html/html.dart' as html if (dart.library.io) 'dart:io';

class EmojiPanel extends StatefulWidget {
  final Uint8List image;
  final int imageId;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;
  final Function(Uint8List,
      {String? action,
      String? operationType,
      Map<String, dynamic>? parameters}) onUpdateImage;

  const EmojiPanel({
    required this.image,
    required this.imageId,
    required this.onCancel,
    required this.onApply,
    required this.onUpdateImage,
    super.key,
  });

  @override
  _EmojiPanelState createState() => _EmojiPanelState();
}

class _EmojiPanelState extends State<EmojiPanel> {
  StickerData? _selectedSticker;
  final List<Map<String, dynamic>> _history = [];
  int _historyIndex = -1;
  final Map<String, List<StickerData>> _stickerCategories = {
    'Fun': [
      StickerData(path: 'lib/assets/stickers/fun1.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/fun2.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/fun3.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/fun4.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/fun5.png', isAsset: true),
    ],
    'Animals': [
      StickerData(path: 'lib/assets/stickers/animals1.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/animals2.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/animals3.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/animals4.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/animals5.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/animals6.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/animals7.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/animals8.png', isAsset: true),
    ],
    'Birthday': [
      StickerData(path: 'lib/assets/stickers/birthday1.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/birthday2.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/birthday3.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/birthday4.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/birthday5.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/birthday6.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/birthday7.png', isAsset: true),
    ],
    'Nature': [
      StickerData(path: 'lib/assets/stickers/nature1.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/nature2.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/nature3.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/nature4.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/nature5.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/nature6.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/nature7.png', isAsset: true),
    ],
    'Christmas': [
      StickerData(path: 'lib/assets/stickers/ch1.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/ch2.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/ch3.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/ch4.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/ch5.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/ch6.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/ch7.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/ch8.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/ch9.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/ch10.png', isAsset: true),
      StickerData(path: 'lib/assets/stickers/ch11.png', isAsset: true),
    ],
    'Custom': [],
  };

  String _selectedCategory = 'Fun';
  final List<StickerData> _addedStickers = [];
  final GlobalKey _imageKey = GlobalKey();
  double _stickerSize = 100.0;
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  bool _isInitialized = false;
  double? _imageAspectRatio;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _loadStickersFromDb();
      _imageAspectRatio = await _getImageAspectRatio();
      _history.add({
        'image': widget.image,
        'action': 'Initial image',
        'operationType': 'init',
        'parameters': {},
      });
      _historyIndex = 0;
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e, stackTrace) {
      _handleError('Initialization failed: $e\n$stackTrace');
    }
  }

  Future<double> _getImageAspectRatio() async {
    final codec = await ui.instantiateImageCodec(widget.image);
    final frame = await codec.getNextFrame();
    final width = frame.image.width.toDouble();
    final height = frame.image.height.toDouble();
    frame.image.dispose();
    return width / height;
  }

  Future<Uint8List> _cropToImageBounds(
      Uint8List inputBytes, int targetWidth, int targetHeight) async {
    final codec = await ui.instantiateImageCodec(inputBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
      Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
      Paint(),
    );

    final croppedImage =
        await recorder.endRecording().toImage(targetWidth, targetHeight);
    final byteData =
        await croppedImage.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    croppedImage.dispose();
    if (byteData == null) {
      throw Exception('Failed to encode cropped image');
    }
    return byteData.buffer.asUint8List();
  }

  Future<void> _addSticker(StickerData sticker) async {
    if (_isProcessing || !_isInitialized) return;
    setState(() => _isProcessing = true);

    try {
      final newSticker = StickerData(
        path: sticker.path,
        bytes: sticker.bytes,
        position: const Offset(100, 100),
        size: _stickerSize,
        isAsset: sticker.isAsset,
      );

      final history = EditHistory(
        imageId: widget.imageId,
        operationType: 'stickers',
        operationParameters: {
          'sticker_path': newSticker.path,
          'category': _selectedCategory,
        },
        operationDate: DateTime.now(),
      );
      final db = MagicMomentDatabase.instance;
      final historyId = await db.insertHistory(history);

      final objectDao = dao.ObjectDao();
      final stickerId = await objectDao.insertSticker(Sticker(
        imageId: widget.imageId,
        path: newSticker.path,
        positionX: newSticker.position.dx,
        positionY: newSticker.position.dy,
        scale: newSticker.size,
        rotation: 0.0,
        historyId: historyId,
        isAsset: newSticker.isAsset,
      ));

      if (!mounted) return;

      setState(() {
        newSticker.id = stickerId;
        _addedStickers.add(newSticker);
        _selectedSticker = newSticker;
        debugPrint('Sticker added: ${newSticker.path}, ID: $stickerId');
      });
    } catch (e, stackTrace) {
      _handleError('Failed to add sticker: $e\n$stackTrace');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (_isProcessing || !_isInitialized) return;
    setState(() => _isProcessing = true);

    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
        debugPrint('No image picked from gallery');
        return;
      }
      final bytes = await pickedFile.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception(AppLocalizations.of(context)?.errorEmptyImage ??
            'Empty image bytes');
      }
      final sticker = StickerData(
        path: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        bytes: bytes,
        position: const Offset(100, 100),
        size: _stickerSize,
        isAsset: false,
      );

      final history = EditHistory(
        historyId: null,
        imageId: widget.imageId,
        operationType: 'stickers',
        operationParameters: {
          'sticker_path': sticker.path,
          'category': 'Custom',
        },
        operationDate: DateTime.now(),
        snapshotPath: kIsWeb
            ? null
            : '${Directory.systemTemp.path}/sticker_${DateTime.now().millisecondsSinceEpoch}.png',
        snapshotBytes: kIsWeb ? bytes : null,
      );
      final db = MagicMomentDatabase.instance;
      final historyId = await db.insertHistory(history);

      final objectDao = dao.ObjectDao();
      final stickerId = await objectDao.insertSticker(Sticker(
        imageId: widget.imageId,
        path: sticker.path,
        positionX: sticker.position.dx,
        positionY: sticker.position.dy,
        scale: sticker.size,
        rotation: 0.0,
        historyId: historyId,
        isAsset: sticker.isAsset,
      ));

      if (!mounted) return;

      setState(() {
        sticker.id = stickerId;
        _stickerCategories['Custom']!.add(sticker);
        _addedStickers.add(sticker);
        _selectedSticker = sticker;
        _selectedCategory = 'Custom';
        debugPrint('Custom sticker added: ${sticker.path}, ID: $stickerId');
      });
    } catch (e, stackTrace) {
      debugPrint('Error picking image: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)?.errorPickImage ??
                  'Failed to pick image: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

Future<void> _applyChanges() async {
if (_isProcessing || !_isInitialized) return;
setState(() {
_isProcessing = true;
_selectedSticker = null;
});

try {
await Future.delayed(const Duration(milliseconds: 16));
final boundary = _imageKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
if (boundary == null) {
throw Exception(AppLocalizations.of(context)?.error ?? 'Rendering error');
}
final image = await boundary.toImage(pixelRatio: 3.0);
final recorder = ui.PictureRecorder();
final canvas = Canvas(recorder);
canvas.drawColor(Colors.transparent, BlendMode.clear); // Очистка с прозрачным фоном
canvas.drawImage(image, Offset.zero, Paint());
final finalImage = await recorder.endRecording().toImage(image.width, image.height);
final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
image.dispose();
finalImage.dispose();
if (byteData == null) {
throw Exception(AppLocalizations.of(context)?.error ?? 'Image conversion error');
}
final pngBytes = byteData.buffer.asUint8List();
if (pngBytes.isEmpty) {
throw Exception('Empty image bytes after cropping');
}

      final history = EditHistory(
        imageId: widget.imageId,
        operationType: 'stickers',
        operationParameters: {
          'stickers_count': _addedStickers.length,
          'category': _selectedCategory,
        },
        operationDate: DateTime.now(),
        snapshotBytes: kIsWeb ? pngBytes : null,
      );
      final db = MagicMomentDatabase.instance;
      final historyId = await db.insertHistory(history);

      if (!mounted) return;

      setState(() {
        if (_historyIndex < _history.length - 1) {
          _history.removeRange(_historyIndex + 1, _history.length);
        }
        _history.add({
          'image': pngBytes,
          'action': AppLocalizations.of(context)?.emoji ?? 'Emoji',
          'operationType': 'stickers',
          'parameters': {
            'stickers_count': _addedStickers.length,
            'category': _selectedCategory,
          },
        });
        _historyIndex++;
        _selectedSticker = null; // Deselect sticker but keep panel open
      });

      await _updateImage(
        newImage: pngBytes,
        action: AppLocalizations.of(context)?.emoji ?? 'Emoji',
        operationType: 'stickers',
        parameters: {
          'stickers_count': _addedStickers.length,
          'category': _selectedCategory,
        },
      );

      widget.onApply(pngBytes);
    } catch (e, stackTrace) {
      _handleError('Error applying stickers: $e\n$stackTrace');
    } finally {
      setState(() => _isProcessing = false);
      // Remove widget.onCancel() to allow re-editing
    }
  }

  Future<void> _loadStickersFromDb() async {
    try {
      final objectDao = dao.ObjectDao();
      final saved = await objectDao.getStickers(widget.imageId);
      debugPrint(
          'Loaded ${saved.length} stickers from DB for imageId: ${widget.imageId}');

      final newStickers = saved
          .map((s) => StickerData(
                id: s.id,
                path: s.path,
                position: Offset(s.positionX, s.positionY),
                size: s.scale,
                isAsset: s.isAsset,
              ))
          .toList();

      if (mounted) {
        setState(() => _addedStickers.addAll(newStickers));
      }
    } catch (e, stackTrace) {
      _handleError('Failed to load stickers: $e\n$stackTrace');
    }
  }

  Future<void> _updateImage({
    required Uint8List newImage,
    required String action,
    required String operationType,
    required Map<String, dynamic> parameters,
  }) async {
    try {
      if (newImage.isEmpty) {
        throw Exception('Empty image bytes');
      }
      await widget.onUpdateImage(
        newImage,
        action: action,
        operationType: operationType,
        parameters: parameters,
      );
      debugPrint('Image updated: $action, size: ${newImage.length} bytes');
    } catch (e, stackTrace) {
      _handleError('Failed to update image: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<void> _undo() async {
    if (_historyIndex <= 0 || _isProcessing || !_isInitialized) return;
    setState(() => _isProcessing = true);

    try {
      final previousImage = _history[_historyIndex]['image'] as Uint8List?;
      if (previousImage == null || previousImage.isEmpty) {
        throw Exception('Invalid history image data');
      }
      setState(() {
        _historyIndex--;
        _addedStickers.clear();
        _selectedSticker = null;
      });

      await _updateImage(
        newImage: previousImage,
        action: 'Undo stickers',
        operationType: 'undo',
        parameters: {
          'previous_action': _history[_historyIndex + 1]['action'],
        },
      );
      debugPrint('Undo performed, history index: $_historyIndex');
    } catch (e, stackTrace) {
      _handleError('Failed to undo: $e\n$stackTrace');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _handleError(String message) {
    debugPrint(message);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
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
                  child: _isInitialized && _imageAspectRatio != null
                      ? GestureDetector(
                          onTap: () => setState(() => _selectedSticker = null),
                          child: AspectRatio(
                            aspectRatio: _imageAspectRatio!,
                            child: RepaintBoundary(
                              key: _imageKey,
                              child: Stack(
                                children: [
                                  Center(
                                      child: Image.memory(widget.image,
                                          fit: BoxFit.contain)),
                                  ..._addedStickers.map(_buildStickerWidget),
                                ],
                              ),
                            ),
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
                                localizations?.loading ?? 'Loading...',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                ),
                _buildBottomPanel(localizations),
              ],
            ),
            if (_isProcessing)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                    child: CircularProgressIndicator(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(AppLocalizations? localizations) {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: widget.onCancel,
        tooltip: localizations?.cancel ?? 'Cancel',
      ),
      title: Text(localizations?.emoji ?? 'Emoji',
          style: const TextStyle(color: Colors.white)),
      actions: [
        IconButton(
          icon: Icon(Icons.undo,
              color: _historyIndex > 0 && _isInitialized
                  ? Colors.white
                  : Colors.grey),
          onPressed: _historyIndex > 0 && _isInitialized ? _undo : null,
          tooltip: localizations?.undo ?? 'Undo',
        ),
        IconButton(
          icon: const Icon(Icons.check, color: Colors.white),
          onPressed: _isInitialized ? _applyChanges : null,
          tooltip: localizations?.apply ?? 'Apply',
        ),
      ],
    );
  }

  Widget _buildStickerWidget(StickerData sticker) {
    final isSelected = sticker == _selectedSticker;
    return Positioned(
      left: sticker.position.dx,
      top: sticker.position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            sticker.position += details.delta;
            debugPrint('Sticker moved to: ${sticker.position}');
          });
        },
        onTap: () {
          setState(() {
            _selectedSticker = sticker;
            _stickerSize = sticker.size;
            debugPrint('Sticker selected: ${sticker.path}');
          });
        },
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            sticker.isAsset
                ? Image.asset(
                    sticker.path,
                    width: sticker.size,
                    height: sticker.size,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint(
                          'Error loading asset sticker: ${sticker.path}, $error');
                      return const Icon(Icons.error,
                          color: Colors.red, size: 30);
                    },
                  )
                : Image.memory(
                    sticker.bytes!,
                    width: sticker.size,
                    height: sticker.size,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint(
                          'Error loading gallery sticker: ${sticker.path}, $error');
                      return const Icon(Icons.error,
                          color: Colors.red, size: 30);
                    },
                  ),
            if (isSelected)
              GestureDetector(
                onTap: () => _confirmDeleteSticker(sticker),
                child: const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteSticker(StickerData sticker) async {
    final localizations = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations?.confirmDelete ?? 'Delete Sticker'),
        content: Text(localizations?.confirmDeleteMessage ??
            'Are you sure you want to delete this sticker?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(localizations?.delete ?? 'Delete',
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() {
          _addedStickers.remove(sticker);
          _selectedSticker = null;
        });
        final objectDao = dao.ObjectDao();
        if (sticker.id != null) {
          await objectDao.softDeleteSticker(sticker.id!);
          debugPrint('Sticker deleted: ${sticker.path}');
        }
      } catch (e, stackTrace) {
        _handleError('Failed to delete sticker: $e\n$stackTrace');
      }
    }
  }

  Widget _buildBottomPanel(AppLocalizations? localizations) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildCategorySelector(localizations),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${localizations?.size ?? 'Size'}:',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    min: 50,
                    max: 200,
                    value: _stickerSize,
                    divisions: 15,
                    activeColor: Colors.blue,
                    inactiveColor: Colors.grey[700],
                    label: _stickerSize.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        _stickerSize = value;
                        if (_selectedSticker != null) {
                          _selectedSticker!.size = value;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          _buildStickerGrid(localizations),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(AppLocalizations? localizations) {
    final categoryNames = {
      'Fun': localizations?.fun ?? 'Fun',
      'Animals': localizations?.animals ?? 'Animals',
      'Birthday': localizations?.birthday ?? 'Birthday',
      'Nature': localizations?.nature ?? 'Nature',
      'Christmas': localizations?.christmas ?? 'Christmas',
      'Custom': localizations?.custom ?? 'Custom',
    };

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _stickerCategories.keys.map((category) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(categoryNames[category] ?? category),
                selected: _selectedCategory == category,
                selectedColor: Colors.blue.withOpacity(0.3),
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = category;
                    debugPrint('Category selected: $category');
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStickerGrid(AppLocalizations? localizations) {
    final stickers = _stickerCategories[_selectedCategory]!;
    return Container(
      height: ResponsiveUtils.getResponsiveHeight(context, 0.18),
      constraints: BoxConstraints(maxHeight: ResponsiveUtils.isDesktop(context) ? 180 : 150),
      color: Colors.black.withOpacity(0.5),
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveUtils.getGridCrossAxisCount(context),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: stickers.length + (_selectedCategory == 'Custom' ? 1 : 0),
        itemBuilder: (context, index) {
          if (_selectedCategory == 'Custom' && index == 0) {
            return Tooltip(
              message: localizations?.addPhoto ?? 'Add photo',
              child: GestureDetector(
                onTap: _pickImageFromGallery,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue, width: 1),
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            );
          }
          final adjustedIndex = _selectedCategory == 'Custom' ? index - 1 : index;
          final sticker = stickers[adjustedIndex];
          return GestureDetector(
            onTap: () => _addSticker(sticker),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: sticker.isAsset
                  ? Image.asset(
                sticker.path,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Error loading asset sticker in grid: ${sticker.path}, $error');
                  return const Icon(Icons.error, color: Colors.red, size: 30);
                },
              )
                  : Image.memory(
                sticker.bytes!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Error loading gallery sticker in grid: ${sticker.path}, $error');
                  return const Icon(Icons.error, color: Colors.red, size: 30);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class StickerData {
  int? id;
  final String path;
  final Uint8List? bytes;
  Offset position;
  double size;
  final bool isAsset;

  StickerData({
    this.id,
    required this.path,
    this.bytes,
    this.position = const Offset(0, 0),
    this.size = 100.0,
    required this.isAsset,
  });
}
