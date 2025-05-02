import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';

class EmojiPanel extends StatefulWidget {
  final Uint8List image;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;

  const EmojiPanel({
    required this.image,
    required this.onCancel,
    required this.onApply,
    Key? key,
  }) : super(key: key);

  @override
  _EmojiPanelState createState() => _EmojiPanelState();
}

class _EmojiPanelState extends State<EmojiPanel> {
  final Map<String, List<String>> _emojiCategories = {
    'Smileys': List.generate(100, (index) => String.fromCharCode(0x1F600 + index))
        .where((emoji) => emoji.runes.isNotEmpty).toList(),
    'Animals': List.generate(50, (index) => String.fromCharCode(0x1F400 + index))
        .where((emoji) => emoji.runes.isNotEmpty).toList(),
    'Food': List.generate(50, (index) => String.fromCharCode(0x1F950 + index))
        .where((emoji) => emoji.runes.isNotEmpty).toList(),
    'Activities': List.generate(50, (index) => String.fromCharCode(0x1F930 + index))
        .where((emoji) => emoji.runes.isNotEmpty).toList(),
    'Objects': List.generate(50, (index) => String.fromCharCode(0x1F6A0 + index))
        .where((emoji) => emoji.runes.isNotEmpty).toList(),
    'Symbols': List.generate(50, (index) => String.fromCharCode(0x1F300 + index))
        .where((emoji) => emoji.runes.isNotEmpty).toList(),
  };

  String _selectedCategory = 'Smileys';
  final List<EmojiData> _addedEmojis = [];
  final GlobalKey _imageKey = GlobalKey();
  double _emojiSize = 40.0; // Added size state variable

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onCancel,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _applyChanges,
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: RepaintBoundary(
                  key: _imageKey,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(widget.image, fit: BoxFit.contain),
                      ..._addedEmojis.map((emojiData) => Positioned(
                        left: emojiData.position.dx,
                        top: emojiData.position.dy,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              emojiData.position += details.delta;
                            });
                          },
                          child: Text(
                            emojiData.emoji,
                            style: TextStyle(
                              fontSize: emojiData.size,
                              shadows: [
                                Shadow(
                                  blurRadius: 5,
                                  color: Colors.black.withOpacity(0.5),
                                  offset: const Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ),
            // Emoji categories
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _emojiCategories.keys.map((category) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            // Size slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(appLocalizations?.size ?? 'Size:',
                      style: const TextStyle(color: Colors.white)),
                  Expanded(
                    child: Slider(
                      min: 24,
                      max: 96,
                      value: _emojiSize,
                      divisions: 6,
                      onChanged: (value) {
                        setState(() {
                          _emojiSize = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Emoji grid
            Container(
              height: 150,
              color: Colors.black.withOpacity(0.5),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                ),
                itemCount: _emojiCategories[_selectedCategory]!.length,
                itemBuilder: (context, index) {
                  final emoji = _emojiCategories[_selectedCategory]![index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _addedEmojis.add(EmojiData(
                          emoji: emoji,
                          position: const Offset(100, 100),
                          size: _emojiSize,
                        ));
                      });
                    },
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyChanges() async {
    try {
      final RenderRepaintBoundary? boundary =
      _imageKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception("Could not find render boundary");
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception("Failed to convert image to bytes");
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      widget.onApply(pngBytes);
    } catch (e) {
      debugPrint('Error capturing image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save image: ${e.toString()}')),
      );
    }
  }
}

class EmojiData {
  final String emoji;
  Offset position;
  final double size;

  EmojiData({
    required this.emoji,
    required this.position,
    required this.size,
  });
}