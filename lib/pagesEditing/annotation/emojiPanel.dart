import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';

class EmojiPanel extends StatefulWidget {
  final Uint8List image;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;
  final onUpdateImage;

  const EmojiPanel({
    required this.image,
    required this.onCancel,
    required this.onApply,
    required this.onUpdateImage,
    super.key,
  });

  @override
  _EmojiPanelState createState() => _EmojiPanelState();
}

class _EmojiPanelState extends State<EmojiPanel> {
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

  Future<void> _updateImage(
      Uint8List newImage, {
        required String action,
        required String operationType,
        required Map<String, dynamic> parameters,
      }) async {
    if (widget.onUpdateImage != null) {
      await widget.onUpdateImage!(newImage, action: action, operationType: operationType, parameters: parameters);
    }
  }

  String _selectedCategory = 'Fun';
  final List<StickerData> _addedStickers = [];
  final GlobalKey _imageKey = GlobalKey();
  double _stickerSize = 100.0;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {}),
                child: RepaintBoundary(
                  key: _imageKey,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(child: Image.memory(widget.image, fit: BoxFit.contain)),
                      ..._addedStickers.map(_buildStickerWidget),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomPanel(appLocalizations),
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
      actions: [
        IconButton(
          icon: const Icon(Icons.check, color: Colors.white),
          onPressed: _applyChanges,
          tooltip: 'Apply changes',
        ),
      ],
    );
  }

  Widget _buildStickerWidget(StickerData sticker) {
    return Positioned(
      left: sticker.position.dx,
      top: sticker.position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            sticker.position += details.delta;
          });
        },
        onTap: () {},
        child: sticker.isAsset
            ? Image.asset(
          sticker.path,
          width: sticker.size,
          height: sticker.size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading asset sticker: ${sticker.path}, $error');
            return const Icon(Icons.error, color: Colors.red, size: 50);
          },
        )
            : Image.memory(
          sticker.bytes!,
          width: sticker.size,
          height: sticker.size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading gallery sticker: ${sticker.path}, $error');
            return const Icon(Icons.error, color: Colors.red, size: 50);
          },
        ),
      ),
    );
  }

  Widget _buildBottomPanel(AppLocalizations? appLocalizations) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, spreadRadius: 1),
        ],
      ),
      child: Column(
        children: [
          _buildCategorySelector(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  appLocalizations?.size ?? 'Size:',
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
                      setState(() => _stickerSize = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          _buildStickerGrid(),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _stickerCategories.keys.map((category) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(category),
              selected: _selectedCategory == category,
              selectedColor: Colors.blue.withOpacity(0.3),
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStickerGrid() {
    final stickers = _stickerCategories[_selectedCategory]!;
    return Container(
      height: 150,
      color: Colors.black.withOpacity(0.5),
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: stickers.length + (_selectedCategory == 'Custom' ? 1 : 0),
        itemBuilder: (context, index) {
          if (_selectedCategory == 'Custom' && index == 0) {
            return GestureDetector(
              onTap: _pickImageFromGallery,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue, width: 1),
                ),
                child: const Icon(Icons.add_photo_alternate, color: Colors.white, size: 40),
              ),
            );
          }
          final adjustedIndex = _selectedCategory == 'Custom' ? index - 1 : index;
          final sticker = stickers[adjustedIndex];
          return GestureDetector(
            onTap: () {
              setState(() {
                _addedStickers.add(StickerData(
                  path: sticker.path,
                  bytes: sticker.bytes,
                  position: const Offset(100, 100),
                  size: _stickerSize,
                  isAsset: sticker.isAsset,
                ));
              });
            },
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

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        if (bytes.isEmpty) {
          throw Exception('Empty image bytes');
        }
        final sticker = StickerData(
          path: 'custom_${DateTime.now().millisecondsSinceEpoch}',
          bytes: bytes,
          isAsset: false,
        );
        setState(() {
          _stickerCategories['Custom']!.add(sticker);
          _addedStickers.add(StickerData(
            path: sticker.path,
            bytes: bytes,
            position: const Offset(100, 100),
            size: _stickerSize,
            isAsset: false,
          ));
          _selectedCategory = 'Custom';
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load image: $e')),
        );
      }
    }
  }

  Future<void> _applyChanges() async {
    try {
      final RenderRepaintBoundary? boundary =
      _imageKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('RenderRepaintBoundary not found. Ensure the widget is rendered.');
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert image to byte data.');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      await _updateImage(
        pngBytes,
        action: 'Added stickers',
        operationType: 'stickers',
        parameters: {
          'stickers_count': _addedStickers.length,
          'category': _selectedCategory,
        },
      );

      widget.onApply(pngBytes);
    } catch (e, stackTrace) {
      debugPrint('Error capturing image: $e\nStackTrace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save image: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {

    }
  }
}

class StickerData {
  final String path;
  final Uint8List? bytes;
  Offset position;
  final double size;
  final bool isAsset;

  StickerData({
    required this.path,
    this.bytes,
    this.position = const Offset(0, 0),
    this.size = 100.0,
    required this.isAsset,
  });
}