import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

class TextEmojiEditor extends StatefulWidget {
  final Uint8List image;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;
  final onUpdateImage;

  const TextEmojiEditor({
    required this.image,
    required this.onCancel,
    required this.onApply,
    required this.onUpdateImage,
    super.key,
  });

  @override
  _TextEmojiEditorState createState() => _TextEmojiEditorState();
}

class _TextEmojiEditorState extends State<TextEmojiEditor> {
  final GlobalKey _renderKey = GlobalKey();
  final TextEditingController _textController = TextEditingController();
  final List<TextItem> _textItems = [];
  TextItem? _selectedTextItem;
  int _currentTabIndex = 0;

  Color _textColor = Colors.white;
  double _textSize = 24.0;
  String _fontFamily = 'Roboto';
  bool _isBold = false;
  bool _isItalic = false;
  bool _hasShadow = true;
  TextAlign _textAlign = TextAlign.center;

  final List<String> _emojis = [
    '😀', '😂', '😍', '😎', '😜', '🤩', '🥳', '😇',
    '🐶', '🐱', '🦁', '🐯', '🦊', '🐻', '🐼', '🐨',
    '🍎', '🍕', '🍔', '🍟', '🍦', '🍩', '🍪', '🍫',
    '⚽', '🏀', '🏈', '⚾', '🎾', '🏐', '🎱', '🏓',
    '🚗', '✈️', '🚀', '🛳️', '🚲', '🏍️', '🚂', '🚁',
    '❤️', '✨', '🌟', '💎', '🔥', '🌈', '☀️', '⭐',
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTextItem = null),
                child: RepaintBoundary(
                  key: _renderKey,
                  child: Stack(
                    children: [
                      Center(child: Image.memory(widget.image, fit: BoxFit.contain)),
                      ..._textItems.map(_buildTextItemWidget),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: 56,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, spreadRadius: 1),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: widget.onCancel,
            tooltip: 'Cancel',
          ),
          const Spacer(),
          if (_selectedTextItem != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteSelectedItem,
              tooltip: 'Delete selected item',
            ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _saveChanges,
            tooltip: 'Apply changes',
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
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: _selectedTextItem == item
                ? Border.all(color: Colors.blue, width: 2)
                : null,
            color: _selectedTextItem == item
                ? Colors.black.withOpacity(0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            item.text,
            style: TextStyle(
              color: item.color,
              fontSize: item.size,
              fontFamily: item.fontFamily,
              fontWeight: item.isBold ? FontWeight.bold : FontWeight.normal,
              fontStyle: item.isItalic ? FontStyle.italic : FontStyle.normal,
              shadows: item.hasShadow
                  ? [
                Shadow(
                  blurRadius: 5,
                  color: Colors.black.withOpacity(0.8),
                  offset: const Offset(1, 1),
                ),
              ]
                  : null,
            ),
            textAlign: item.textAlign,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, spreadRadius: 1),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabBar(),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _currentTabIndex == 0 ? _buildTextTab() : _buildEmojiTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      child: Row(
        children: [
          _buildTabButton('Text', 0),
          _buildTabButton('Emoji', 1),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentTabIndex = index),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _currentTabIndex == index ? Colors.blue : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: _currentTabIndex == index ? Colors.blue : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: 'Enter text or emoji',
              hintStyle: TextStyle(color: Colors.grey[500]),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add, color: Colors.blue),
                onPressed: _addText,
                tooltip: 'Add text',
              ),
            ),
            style: const TextStyle(color: Colors.white),
            onSubmitted: (_) => _addText(),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
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
                      () => _toggleStyle(() => _isBold = !_isBold),
                  isActive: _isBold,
                ),
                _buildStyleButton(
                  Icons.format_italic,
                  'Italic',
                      () => _toggleStyle(() => _isItalic = !_isItalic),
                  isActive: _isItalic,
                ),
                _buildStyleButton(
                  FluentIcons.image_shadow_20_filled,
                  'Shadow',
                      () => _toggleStyle(() => _hasShadow = !_hasShadow),
                  isActive: _hasShadow,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiTab() {
    return Container(
      height: 200,
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
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _emojis[index],
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStyleButton(IconData icon, String label, VoidCallback onTap, {bool isActive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(icon, color: isActive ? Colors.blue : Colors.white, size: 24),
            onPressed: onTap,
            tooltip: label,
          ),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.blue : Colors.white,
              fontSize: 10,
            ),
          ),
        ],
      ),
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

  void _deleteSelectedItem() {
    if (_selectedTextItem != null) {
      setState(() {
        _textItems.remove(_selectedTextItem);
        _selectedTextItem = null;
        _textController.clear();
      });
    }
  }

  void _toggleStyle(VoidCallback toggle) {
    setState(() {
      toggle();
      if (_selectedTextItem != null) {
        _selectedTextItem!.isBold = _isBold;
        _selectedTextItem!.isItalic = _isItalic;
        _selectedTextItem!.hasShadow = _hasShadow;
      }
    });
  }

  Future<void> _showSizeDialog() async {
    double tempSize = _textSize;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: tempSize,
                    min: 10,
                    max: 72,
                    divisions: 62,
                    activeColor: Colors.blue,
                    inactiveColor: Colors.grey[700],
                    label: tempSize.round().toString(),
                    onChanged: (value) => setState(() => tempSize = value),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _textSize = tempSize;
                            if (_selectedTextItem != null) {
                              _selectedTextItem!.size = tempSize;
                            }
                          });
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
    final colors = [
      Colors.white, Colors.black, Colors.red, Colors.orange, Colors.yellow,
      Colors.green, Colors.blue, Colors.purple, Colors.pink, Colors.teal,
      Colors.cyan, Colors.lime,
    ];

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Text Color',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: colors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _textColor = color;
                        if (_selectedTextItem != null) {
                          _selectedTextItem!.color = color;
                        }
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _textColor == color ? Colors.blue : Colors.white,
                          width: 2,
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Font Family',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...fonts.map((font) {
                return ListTile(
                  title: Text(
                    font,
                    style: TextStyle(color: Colors.white, fontFamily: font, fontSize: 18),
                  ),
                  trailing: _fontFamily == font
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() {
                      _fontFamily = font;
                      if (_selectedTextItem != null) {
                        _selectedTextItem!.fontFamily = font;
                      }
                    });
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Text Alignment',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
        setState(() {
          _textAlign = align;
          if (_selectedTextItem != null) {
            _selectedTextItem!.textAlign = align;
          }
        });
        Navigator.pop(context);
      },
      tooltip: align.toString().split('.').last,
    );
  }

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

  Future<void> _saveChanges() async {
    try {
      final RenderRepaintBoundary boundary = _renderKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) throw Exception('Failed to convert image to bytes');

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      await _updateImage(
        pngBytes,
        action: 'Added text/emoji',
        operationType: 'text_emoji',
        parameters: {
          'text_items_count': _textItems.length,
          'text': _textController.text,
        },
      );

      widget.onApply(pngBytes);
    } catch (e) {
      debugPrint('Error saving image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save changes')),
      );
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
