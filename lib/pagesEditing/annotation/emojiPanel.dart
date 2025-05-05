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

  const EmojiPanel({
    required this.image,
    required this.onCancel,
    required this.onApply,
    super.key,
  });

  @override
  _EmojiPanelState createState() => _EmojiPanelState();
}

class _EmojiPanelState extends State<EmojiPanel> {
  final Map<String, List<String>> _stickerCategories = {
    'Fun': [
      'assets/stickers/fun1.png',
      'assets/stickers/fun2.png',
      'assets/stickers/fun3.png',
      'assets/stickers/fun4.png',
      'assets/stickers/fun5.png',
    ],
    'Animals': [
      'assets/stickers/animals1.png',
      'assets/stickers/animals2.png',
      'assets/stickers/animals3.png',
      'assets/stickers/animals4.png',
      'assets/stickers/animals5.png',
      'assets/stickers/animals6.png',
      'assets/stickers/animals7.png',
      'assets/stickers/animals8.png',
    ],
    'Birthday': [
      'assets/stickers/birthday1.png',
      'assets/stickers/birthday2.png',
      'assets/stickers/birthday3.png',
      'assets/stickers/birthday4.png',
      'assets/stickers/birthday5.png',
      'assets/stickers/birthday6.png',
      'assets/stickers/birthday7.png',
    ],
    'Nature': [
      'assets/stickers/nature1.png',
      'assets/stickers/nature2.png',
      'assets/stickers/nature3.png',
      'assets/stickers/nature4.png',
      'assets/stickers/nature5.png',
      'assets/stickers/nature6.png',
      'assets/stickers/nature7.png',
    ],
    'Christmas': [
      'assets/stickers/ch1.png',
      'assets/stickers/ch2.png',
      'assets/stickers/ch3.png',
      'assets/stickers/ch4.png',
      'assets/stickers/ch5.png',
      'assets/stickers/ch6.png',
      'assets/stickers/ch7.png',
      'assets/stickers/ch8.png',
      'assets/stickers/ch9.png',
      'assets/stickers/ch10.png',
      'assets/stickers/ch11.png',
    ],
    'Custom': [],
  };

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
        onTap: () {
          // Optional: Add selection logic if needed
        },
        child: sticker.isAsset
            ? Image.asset(
          sticker.path,
          width: sticker.size,
          height: sticker.size,
          fit: BoxFit.contain,
        )
            : Image.memory(
          sticker.bytes!,
          width: sticker.size,
          height: sticker.size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.error,
            color: Colors.red,
            size: 50,
          ),
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
          final stickerPath = stickers[_selectedCategory == 'Custom' ? index - 1 : index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _addedStickers.add(StickerData(
                  path: stickerPath,
                  position: const Offset(100, 100),
                  size: _stickerSize,
                  isAsset: true,
                ));
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                stickerPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.error,
                  color: Colors.red,
                  size: 30,
                ),
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
        setState(() {
          _stickerCategories['Custom']!.add(pickedFile.path);
          _addedStickers.add(StickerData(
            path: pickedFile.path,
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
          const SnackBar(content: Text('Failed to load image from gallery')),
        );
      }
    }
  }

  Future<void> _applyChanges() async {
    try {
      final RenderRepaintBoundary? boundary =
      _imageKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Could not find render boundary');
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      widget.onApply(pngBytes);
    } catch (e) {
      debugPrint('Error capturing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save image: ${e.toString()}')),
        );
      }
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
    required this.position,
    required this.size,
    required this.isAsset,
  });
}