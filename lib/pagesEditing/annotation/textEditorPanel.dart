import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:MagicMoment/database/magicMomentDatabase.dart';
import 'package:MagicMoment/pagesEditing/image_utils.dart';

class TextEditorPanel extends StatefulWidget {
  final Uint8List image;
  final int imageId;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;
  final Function(Uint8List, {String? action, String? operationType, Map<String, dynamic>? parameters}) onUpdateImage;

  const TextEditorPanel({
    required this.image,
    required this.imageId,
    required this.onCancel,
    required this.onApply,
    required this.onUpdateImage,
    super.key,
  });

  @override
  State<TextEditorPanel> createState() => _TextEditorPanelState();
}

class _TextEditorPanelState extends State<TextEditorPanel> {
  final GlobalKey _key = GlobalKey();
  final List<TextItem> _items = [];
  final TextEditingController _controller = TextEditingController();
  TextItem? _editing;

  @override
  void initState() {
    super.initState();
    _loadText();
  }

  Future<void> _loadText() async {
    final db = magicMomentDatabase.instance;
    final list = await db.getTextItemsForImage(widget.imageId);
    setState(() => _items.addAll(list));
  }

  void _addText(String text) {
    final item = TextItem(
      text: text,
      position: const Offset(100, 100),
      size: 24,
      color: Colors.white,
    );
    setState(() {
      _items.add(item);
      _editing = item;
    });
  }

  void _apply() async {
    final db = magicMomentDatabase.instance;
    for (final item in _items) {
      if (item.id == null) {
        final id = await db.insertTextItem(item, widget.imageId);
        item.id = id;
      } else {
        await db.updateTextItem(item);
      }
    }

    await Future.delayed(const Duration(milliseconds: 50));
    final pngBytes = await saveImage(_key);

    await widget.onUpdateImage(
      pngBytes,
      action: 'Text updated',
      operationType: 'text',
      parameters: {'count': _items.length},
    );

    widget.onApply(pngBytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          AppBar(
            backgroundColor: Colors.black,
            title: const Text('Text / Emoji'),
            leading: IconButton(icon: const Icon(Icons.close), onPressed: widget.onCancel),
            actions: [
              IconButton(icon: const Icon(Icons.check), onPressed: _apply),
            ],
          ),
          Expanded(
            child: RepaintBoundary(
              key: _key,
              child: Stack(
                children: [
                  Center(child: Image.memory(widget.image, fit: BoxFit.contain)),
                  ..._items.map((item) => Positioned(
                    left: item.position.dx,
                    top: item.position.dy,
                    child: GestureDetector(
                      onPanUpdate: (d) => setState(() => item.position += d.delta),
                      onTap: () {
                        setState(() {
                          _editing = item;
                          _controller.text = item.text;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: _editing == item ? Border.all(color: Colors.blue) : null,
                        ),
                        child: Text(
                          item.text,
                          style: TextStyle(
                            fontSize: item.size,
                            color: item.color,
                          ),
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'Text or emoji', hintStyle: TextStyle(color: Colors.grey)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.blue),
                  onPressed: () => _addText(_controller.text),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class TextItem {
  int? id;
  String text;
  Offset position;
  double size;
  Color color;

  TextItem({
    this.id,
    required this.text,
    required this.position,
    required this.size,
    required this.color,
  });

  Map<String, dynamic> toMap(int imageId) => {
    'image_id': imageId,
    'text': text,
    'x': position.dx,
    'y': position.dy,
    'size': size,
    'color': color.value,
  };

  factory TextItem.fromMap(Map<String, dynamic> map) => TextItem(
    id: map['id'],
    text: map['text'],
    position: Offset(map['x'], map['y']),
    size: map['size'],
    color: Color(map['color']),
  );
}
