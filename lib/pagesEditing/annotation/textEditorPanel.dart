import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

class TextEmojiEditor extends StatefulWidget {
  final Uint8List image;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;

  const TextEmojiEditor({
    required this.image,
    required this.onCancel,
    required this.onApply,
    Key? key,
  }) : super(key: key);

  @override
  _TextEmojiEditorState createState() => _TextEmojiEditorState();
}

class _TextEmojiEditorState extends State<TextEmojiEditor> {
  final GlobalKey _renderKey = GlobalKey();
  final TextEditingController _textController = TextEditingController();
  final List<TextItem> _textItems = [];
  TextItem? _selectedTextItem;
  int _currentTabIndex = 0;

  // Стили текста
  Color _textColor = Colors.white;
  double _textSize = 24.0;
  String _fontFamily = 'Roboto';
  bool _isBold = false;
  bool _isItalic = false;
  bool _hasShadow = true;
  TextAlign _textAlign = TextAlign.center;

  // Эмодзи
  final List<String> _emojis = [
    '😀', '😂', '😍', '😎', '😜', '🤩', '🥳', '😇',
    '🐶', '🐱', '🦁', '🐯', '🦊', '🐻', '🐼', '🐨',
    '🍎', '🍕', '🍔', '🍟', '🍦', '🍩', '🍪', '🍫',
    '⚽', '🏀', '🏈', '⚾', '🎾', '🏐', '🎱', '🏓',
    '🚗', '✈️', '🚀', '🛳️', '🚲', '🏍️', '🚂', '🚁',
    '❤️', '✨', '🌟', '💎', '🔥', '🌈', '☀️', '⭐'
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),

            Expanded(
              child: RepaintBoundary(
                key: _renderKey,
                child: Center(
                  child: Stack(
                    children: [
                      Image.memory(widget.image, fit: BoxFit.contain),
                      ..._textItems.map(_buildTextItemWidget),
                    ],
                  ),
                ),
              ),
            ),

            // Нижняя панель инструментов
            _buildBottomPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: widget.onCancel,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _saveChanges,
          ),
        ],
      ),
    );
  }

  Widget _buildTextItemWidget(TextItem item) {
    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      child: GestureDetector(
        onTap: () => _selectTextItem(item),
        onPanUpdate: (details) {
          setState(() {
            item.position += details.delta;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: _selectedTextItem == item
                ? Border.all(color: Colors.blue, width: 2)
                : null,
          ),
          child: Text(
            item.text,
            style: TextStyle(
              color: item.color,
              fontSize: item.size,
              fontFamily: item.fontFamily,
              fontWeight: item.isBold ? FontWeight.bold : FontWeight.normal,
              fontStyle: item.isItalic ? FontStyle.italic : FontStyle.normal,
              shadows: item.hasShadow ? [
                Shadow(
                  blurRadius: 5,
                  color: Colors.black.withOpacity(0.8),
                  offset: const Offset(1, 1),
                ),
              ] : null,
            ),
            textAlign: item.textAlign,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Табы
        Container(
          height: 48,
          color: Colors.grey[900],
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _currentTabIndex = 0),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _currentTabIndex == 0
                              ? Colors.blue
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'Text',
                      style: TextStyle(
                        color: _currentTabIndex == 0
                            ? Colors.blue
                            : Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _currentTabIndex = 1),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _currentTabIndex == 1
                              ? Colors.blue
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'Emoji',
                      style: TextStyle(
                        color: _currentTabIndex == 1
                            ? Colors.blue
                            : Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Контент табов
        _currentTabIndex == 0 ? _buildTextTab() : _buildEmojiTab(),
      ],
    );
  }

  Widget _buildTextTab() {
    return Column(
      children: [
        // Поле ввода текста
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: 'Enter text here',
              hintStyle: TextStyle(color: Colors.grey[500]),
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add, color: Colors.blue),
                onPressed: _addText,
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ),

        // Панель стилей текста
        Container(
          height: 80,
          color: Colors.grey[900],
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStyleButton(
                Icons.format_size,
                'Size',
                    () => _showSizeDialog(),
              ),
              _buildStyleButton(
                Icons.color_lens,
                'Color',
                    () => _showColorDialog(),
              ),
              _buildStyleButton(
                Icons.font_download,
                'Font',
                    () => _showFontDialog(),
              ),
              _buildStyleButton(
                Icons.format_align_center,
                'Align',
                    () => _showAlignDialog(),
              ),
              _buildStyleButton(
                Icons.format_bold,
                'Bold',
                    () => setState(() => _isBold = !_isBold),
                isActive: _isBold,
              ),
              _buildStyleButton(
                Icons.format_italic,
                'Italic',
                    () => setState(() => _isItalic = !_isItalic),
                isActive: _isItalic,
              ),
              _buildStyleButton(
                Icons.format_underlined,
                'Shadow',
                    () => setState(() => _hasShadow = !_hasShadow),
                isActive: _hasShadow,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmojiTab() {
    return Container(
      height: 200,
      color: Colors.grey[900],
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: _emojis.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _addEmoji(_emojis[index]),
            child: Container(
              alignment: Alignment.center,
              child: Text(
                _emojis[index],
                style: const TextStyle(fontSize: 24),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStyleButton(IconData icon, String label, VoidCallback onTap,
      {bool isActive = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(icon, color: isActive ? Colors.blue : Colors.white),
          onPressed: onTap,
        ),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.blue : Colors.white,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  void _addText() {
    if (_textController.text.isEmpty) return;

    final newItem = TextItem(
      text: _textController.text,
      position: const Offset(100, 100),
      color: _textColor,
      size: _textSize,
      fontFamily: _fontFamily,
      isBold: _isBold,
      isItalic: _isItalic,
      hasShadow: _hasShadow,
      textAlign: _textAlign,
    );

    setState(() {
      _textItems.add(newItem);
      _selectedTextItem = newItem;
      _textController.clear();
    });
  }

  void _addEmoji(String emoji) {
    final newItem = TextItem(
      text: emoji,
      position: const Offset(100, 100),
      color: _textColor,
      size: _textSize,
      fontFamily: _fontFamily,
      isBold: _isBold,
      isItalic: _isItalic,
      hasShadow: _hasShadow,
      textAlign: _textAlign,
    );

    setState(() {
      _textItems.add(newItem);
      _selectedTextItem = newItem;
    });
  }

  void _selectTextItem(TextItem item) {
    setState(() {
      _selectedTextItem = item;
      _textColor = item.color;
      _textSize = item.size;
      _fontFamily = item.fontFamily;
      _isBold = item.isBold;
      _isItalic = item.isItalic;
      _hasShadow = item.hasShadow;
      _textAlign = item.textAlign;
      _textController.text = item.text;
    });
  }

  Future<void> _showSizeDialog() async {
    double newSize = _textSize;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                const Text(
                'Text Size',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Slider(
                value: newSize,
                min: 10,
                max: 72,
                divisions: 10,
                activeColor: Colors.blue,
                inactiveColor: Colors.grey[700],
                onChanged: (value) {
                  setState(() => newSize = value);
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white)),),
                    TextButton(
                      onPressed: () {
                        setState(() => _textSize = newSize);
                        if (_selectedTextItem != null) {
                          _selectedTextItem!.size = newSize;
                          _textController.text = _selectedTextItem!.text;
                        }
                        Navigator.pop(context);
                      },
                      child: const Text('Apply', style: TextStyle(color: Colors.blue)),
                    ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showColorDialog() async {
    final List<Color> colors = [
      Colors.white, Colors.black, Colors.red, Colors.orange,
      Colors.yellow, Colors.green, Colors.blue, Colors.purple,
      Colors.pink, Colors.teal, Colors.cyan, Colors.lime,
    ];

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Text Color',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: colors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() => _textColor = color);
                      _textColor = color;
                      if (_selectedTextItem != null) {
                        _selectedTextItem!.color = color;
                        _textController.text = _selectedTextItem!.text;
                      }
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: _textColor == color ? 2 : 0,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showFontDialog() async {
    final fonts = ['Roboto', 'Arial', 'Courier', 'Times New Roman', 'Verdana'];

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Font Family',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...fonts.map((font) {
                return ListTile(
                  title: Text(
                    font,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: font,
                      fontSize: 18,
                    ),
                  ),
                  trailing: _fontFamily == font
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() => _fontFamily = font);
                    if (_selectedTextItem != null) {
                      _selectedTextItem!.fontFamily = font;
                      _textController.text = _selectedTextItem!.text;

                    }
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAlignDialog() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Text Alignment',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAlignOption(Icons.format_align_left, TextAlign.left),
                  _buildAlignOption(Icons.format_align_center, TextAlign.center),
                  _buildAlignOption(Icons.format_align_right, TextAlign.right),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlignOption(IconData icon, TextAlign align) {
    return IconButton(
      icon: Icon(icon, size: 32, color: _textAlign == align ? Colors.blue : Colors.white),
      onPressed: () {
        setState(() => _textAlign = align);

        if (_selectedTextItem != null) {
          _selectedTextItem!.textAlign = align;
          _textController.text = _selectedTextItem!.text;
        }
        Navigator.pop(context);
      },
    );
  }

  Future<void> _saveChanges() async {
    try {
      final RenderRepaintBoundary boundary =
      _renderKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      widget.onApply(pngBytes);
    } catch (e) {
      debugPrint('Error saving image: $e');
    }
  }
}

class TextItem {
  String text;
  Offset position;
  Color color;
  double size;
  String fontFamily;
  bool isBold;
  bool isItalic;
  bool hasShadow;
  TextAlign textAlign;

  TextItem({
    required this.text,
    required this.position,
    required this.color,
    required this.size,
    required this.fontFamily,
    required this.isBold,
    required this.isItalic,
    required this.hasShadow,
    required this.textAlign,
  });
}