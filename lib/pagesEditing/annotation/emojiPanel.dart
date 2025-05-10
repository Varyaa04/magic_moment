import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:MagicMoment/database/magicMomentDatabase.dart';
import 'package:MagicMoment/pagesEditing/image_utils.dart';

class EmojiPanel extends StatefulWidget {
  final Uint8List image;
  final int imageId;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;
  final Function(Uint8List, {String? action, String? operationType, Map<String, dynamic>? parameters}) onUpdateImage;

  const EmojiPanel({
    required this.image,
    required this.imageId,
    required this.onCancel,
    required this.onApply,
    required this.onUpdateImage,
    super.key,
  });

  @override
  State<EmojiPanel> createState() => _EmojiPanelState();
}

class _EmojiPanelState extends State<EmojiPanel> {
  final GlobalKey _key = GlobalKey();
  final List<StickerData> _stickers = [];
  late final Map<String, List<StickerData>> _categories;
  String _currentCategory = 'Fun';

  @override
  void initState() {
    super.initState();
    _initCategories();
    _loadFromDb();
  }

  void _initCategories() {
    _categories = {
      'Fun': [
        'fun1', 'fun2', 'fun3', 'fun4', 'fun5'
      ].map((n) => StickerData(path: 'lib/assets/stickers/$n.png')).toList(),
      'Animals': [
        for (int i = 1; i <= 8; i++) StickerData(path: 'lib/assets/stickers/animals$i.png'),
      ],
      'Birthday': [
        for (int i = 1; i <= 7; i++) StickerData(path: 'lib/assets/stickers/birthday$i.png'),
      ],
      'Nature': [
        for (int i = 1; i <= 7; i++) StickerData(path: 'lib/assets/stickers/nature$i.png'),
      ],
      'Christmas': [
        for (int i = 1; i <= 11; i++) StickerData(path: 'lib/assets/stickers/ch$i.png'),
      ],
    };
  }

  Future<void> _loadFromDb() async {
    final db = magicMomentDatabase.instance;
    final saved = await db.getStickersForImage(widget.imageId);
    setState(() => _stickers.addAll(saved));
  }

  void _addSticker(StickerData s) {
    setState(() {
      _stickers.add(s.copyWith(position: const Offset(100, 100), size: 100));
    });
  }

  void _removeSticker(StickerData s) => setState(() => _stickers.remove(s));

  Future<void> _apply() async {
    final db = magicMomentDatabase.instance;
    for (final s in _stickers) {
      if (s.id == null) {
        final id = await db.insertSticker(s, widget.imageId);
        s.id = id;
      } else {
        await db.updateSticker(s);
      }
    }

    await Future.delayed(const Duration(milliseconds: 50));
    final pngBytes = await saveImage(_key);

    await widget.onUpdateImage(
      pngBytes,
      action: 'Sticker updated',
      operationType: 'sticker',
      parameters: {'count': _stickers.length},
    );
    widget.onApply(pngBytes);
  }

  @override
  Widget build(BuildContext context) {
    final available = _categories[_currentCategory]!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          AppBar(
            backgroundColor: Colors.black,
            title: const Text('Stickers'),
            leading: IconButton(icon: const Icon(Icons.close), onPressed: widget.onCancel),
            actions: [
              IconButton(icon: const Icon(Icons.check), onPressed: _apply),
            ],
          ),
          _buildCategorySelector(),
          Expanded(
            child: RepaintBoundary(
              key: _key,
              child: Stack(
                children: [
                  Center(child: Image.memory(widget.image, fit: BoxFit.contain)),
                  ..._stickers.map((s) => Positioned(
                    left: s.position.dx,
                    top: s.position.dy,
                    child: GestureDetector(
                      onPanUpdate: (d) => setState(() => s.position += d.delta),
                      onLongPress: () => _removeSticker(s),
                      child: Image.asset(s.path, width: s.size),
                    ),
                  )),
                ],
              ),
            ),
          ),
          Container(
            color: Colors.grey[900],
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: available.map((s) {
                return GestureDetector(
                  onTap: () => _addSticker(s),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                    ),
                    child: Image.asset(s.path),
                  ),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 50,
      color: Colors.black,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _categories.keys.map((c) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ChoiceChip(
              label: Text(c, style: const TextStyle(color: Colors.white)),
              selected: _currentCategory == c,
              onSelected: (_) => setState(() => _currentCategory = c),
              selectedColor: Colors.blue.withOpacity(0.4),
              backgroundColor: Colors.grey[800],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class StickerData {
  int? id;
  final String path;
  Offset position;
  double size;

  StickerData({this.id, required this.path, this.position = Offset.zero, this.size = 100});

  StickerData copyWith({Offset? position, double? size}) => StickerData(
    id: id,
    path: path,
    position: position ?? this.position,
    size: size ?? this.size,
  );

  Map<String, dynamic> toMap(int imageId) => {
    'image_id': imageId,
    'path': path,
    'x': position.dx,
    'y': position.dy,
    'size': size,
  };

  factory StickerData.fromMap(Map<String, dynamic> map) => StickerData(
    id: map['id'],
    path: map['path'],
    position: Offset(map['x'], map['y']),
    size: map['size'],
  );
}
