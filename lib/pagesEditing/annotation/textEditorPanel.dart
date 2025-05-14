import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:MagicMoment/themeWidjets/colorPicker.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import '../../database/objectDao.dart' as dao;
import '../../database/objectsModels.dart';
import '../../database/magicMomentDatabase.dart';

class TextEmojiEditor extends StatefulWidget {
  final Uint8List image;
  final int imageId;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;
  final Function(Uint8List, {String? action, String? operationType, Map<String, dynamic>? parameters}) onUpdateImage;

  const TextEmojiEditor({
    required this.image,
    required this.imageId,
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
  final List<Map<String, dynamic>> _history = [];
  int _historyIndex = -1;
  TextItem? _selectedTextItem;
  int _currentTabIndex = 0;
  Color _textBackgroundColor = Colors.transparent;
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
  void initState() {
    super.initState();
    _textController.addListener(() {
      if (_selectedTextItem != null) {
        setState(() {
          _selectedTextItem!.text = _textController.text;
        });
      }
    });
    _loadTextsFromDb();
    _history.add({
      'image': widget.image,
      'action': 'Initial image',
      'operationType': 'init',
      'parameters': {},
    });
    _historyIndex = 0;
  }

  Future<void> _loadTextsFromDb() async {
    try {
      final objectDao = dao.ObjectDao();
      final saved = await objectDao.getTexts(widget.imageId);
      debugPrint('Loaded ${saved.length} texts from DB for imageId: ${widget.imageId}');

      setState(() {
        _textItems.addAll(saved.map((t) => TextItem(
          id: t.id,
          text: t.text,
          position: Offset(t.positionX, t.positionY),
          color: Color(int.parse(t.color.replaceFirst('#', '0xff'))),
          size: t.fontSize,
          fontFamily: t.fontFamily,
          isBold: t.fontWeight == 'bold',
          isItalic: t.fontStyle == 'italic',
          hasShadow: true,
          textAlign: TextAlign.values.byName(t.alignment),
          backgroundColor: Colors.transparent,
        )));
      });
    } catch (e) {
      debugPrint('Error loading texts from DB: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load texts: $e')),
        );
      }
    }
  }

  Future<void> _undo() async {
    if (_historyIndex <= 0) return;

    try {
      setState(() {
        _historyIndex--;
        _textItems.clear();
        _selectedTextItem = null;
        _textController.clear();
      });

      await widget.onUpdateImage(
        _history[_historyIndex]['image'],
        action: 'Undo text/emoji',
        operationType: 'undo',
        parameters: {
          'previous_action': _history[_historyIndex + 1]['action'],
        },
      );
      debugPrint('Undo performed, history index: $_historyIndex');
    } catch (e) {
      debugPrint('Error undoing text/emoji: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to undo: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(localizations),
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
            _buildBottomPanel(localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations? localizations) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: 56,
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, spreadRadius: 1),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: widget.onCancel,
            tooltip: localizations?.cancel ?? 'Cancel',
          ),
          const Spacer(),
          if (_selectedTextItem != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteSelectedItem,
              tooltip: localizations?.remove ?? 'Remove',
            ),
          IconButton(
            icon: Icon(Icons.undo, color: _historyIndex > 0 ? Colors.white : Colors.grey),
            onPressed: _historyIndex > 0 ? _undo : null,
            tooltip: localizations?.undo ?? 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _saveChanges,
            tooltip: localizations?.apply ?? 'Apply',
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
            debugPrint('Text moved to: ${item.position}');
          });
        },
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: _selectedTextItem == item ? Border.all(color: Colors.blue, width: 2) : null,
            color: item.backgroundColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Container(
            decoration: _selectedTextItem == item
                ? BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            )
                : null,
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
      ),
    );
  }

  Widget _buildBottomPanel(AppLocalizations? localizations) {
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
          _buildTabBar(localizations),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _currentTabIndex == 0 ? _buildTextTab(localizations) : _buildEmojiTab(localizations),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations? localizations) {
    return Container(
      height: 48,
      child: Row(
        children: [
          _buildTabButton(localizations?.text ?? 'Text', 0),
          _buildTabButton(localizations?.emoji ?? 'Emoji', 1),
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

  Widget _buildTextTab(AppLocalizations? localizations) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: localizations?.enterText ?? 'Enter text or emoji',
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
                tooltip: localizations?.add ?? 'Add',
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
                  localizations?.size ?? 'Size',
                      () => _showSizeDialog(localizations),
                ),
                _buildStyleButton(
                  Icons.color_lens,
                  localizations?.textColor ?? 'Color',
                      () => _showColorDialog(localizations),
                ),
                _buildStyleButton(
                  Icons.format_color_fill,
                  localizations?.background ?? 'Background',
                      () => _showBackgroundColorDialog(localizations),
                ),
                _buildStyleButton(
                  Icons.font_download,
                  localizations?.font ?? 'Font',
                      () => _showFontDialog(localizations),
                ),
                _buildStyleButton(
                  Icons.format_align_center,
                  localizations?.align ?? 'Align',
                      () => _showAlignDialog(localizations),
                ),
                _buildStyleButton(
                  Icons.format_bold,
                  localizations?.bold ?? 'Bold',
                      () => _toggleStyle(() => _isBold = !_isBold),
                  isActive: _isBold,
                ),
                _buildStyleButton(
                  Icons.format_italic,
                  localizations?.italic ?? 'Italic',
                      () => _toggleStyle(() => _isItalic = !_isItalic),
                  isActive: _isItalic,
                ),
                _buildStyleButton(
                  FluentIcons.image_shadow_20_filled,
                  localizations?.shadow ?? 'Shadow',
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

  Widget _buildEmojiTab(AppLocalizations? localizations) {
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
          return Tooltip(
            message: localizations?.tapToPlaceEmoji ?? 'Tap to place emoji',
            child: GestureDetector(
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

  Future<void> _showBackgroundColorDialog(AppLocalizations? localizations) async {
    Color tempColor = _textBackgroundColor;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localizations?.textBackground ?? 'Text Background',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ColorPicker(
                    pickerColor: tempColor,
                    onColorChanged: (color) => tempColor = color,
                    pickerAreaHeightPercent: 0.7,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(localizations?.cancel ?? 'Cancel', style: const TextStyle(color: Colors.white)),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _textBackgroundColor = tempColor;
                          if (_selectedTextItem != null) {
                            _selectedTextItem!.backgroundColor = tempColor;
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: Text(localizations?.apply ?? 'Apply', style: const TextStyle(color: Colors.blue)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addText() async {
    if (_textController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.enterText ?? 'Please enter text')),
        );
      }
      return;
    }

    try {
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
        backgroundColor: _textBackgroundColor,
      );

      final history = EditHistory(
        imageId: widget.imageId,
        operationType: 'text_emoji',
        operationParameters: {
          'text': newItem.text,
          'font_size': newItem.size,
        },
        operationDate: DateTime.now(),
      );
      final db = MagicMomentDatabase.instance;
      final historyId = await db.insertHistory(history);
      debugPrint('History inserted with ID: $historyId');

      final objectDao = dao.ObjectDao();
      final textId = await objectDao.insertText(TextObject(
        imageId: widget.imageId,
        text: newItem.text,
        positionX: newItem.position.dx,
        positionY: newItem.position.dy,
        fontSize: newItem.size,
        fontWeight: newItem.isBold ? 'bold' : 'normal',
        fontStyle: newItem.isItalic ? 'italic' : 'normal',
        alignment: newItem.textAlign.name,
        color: '#${newItem.color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        fontFamily: newItem.fontFamily,
        scale: 1.0,
        rotation: 0.0,
        historyId: historyId,
      ));

      setState(() {
        newItem.id = textId;
        _textItems.add(newItem);
        _selectedTextItem = newItem;
        _textController.clear();
        debugPrint('Text added: ${newItem.text}, ID: $textId');
      });
    } catch (e) {
      debugPrint('Error adding text: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add text: $e')),
        );
      }
    }
  }

  Future<void> _addEmoji(String emoji) async {
    try {
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
        backgroundColor: _textBackgroundColor,
      );

      final history = EditHistory(
        imageId: widget.imageId,
        operationType: 'text_emoji',
        operationParameters: {
          'emoji': newItem.text,
          'font_size': newItem.size,
        },
        operationDate: DateTime.now(),
      );
      final db = MagicMomentDatabase.instance;
      final historyId = await db.insertHistory(history);
      debugPrint('History inserted with ID: $historyId');

      final objectDao = dao.ObjectDao();
      final textId = await objectDao.insertText(TextObject(
        imageId: widget.imageId,
        text: newItem.text,
        positionX: newItem.position.dx,
        positionY: newItem.position.dy,
        fontSize: newItem.size,
        fontWeight: newItem.isBold ? 'bold' : 'normal',
        fontStyle: newItem.isItalic ? 'italic' : 'normal',
        alignment: newItem.textAlign.name,
        color: '#${newItem.color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        fontFamily: newItem.fontFamily,
        scale: 1.0,
        rotation: 0.0,
        historyId: historyId,
      ));

      setState(() {
        newItem.id = textId;
        _textItems.add(newItem);
        _selectedTextItem = newItem;
        debugPrint('Emoji added: ${newItem.text}, ID: $textId');
      });
    } catch (e) {
      debugPrint('Error adding emoji: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add emoji: $e')),
        );
      }
    }
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
      _textBackgroundColor = item.backgroundColor;
      _textController.text = item.text;
      _textController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: item.text.length,
      );
      debugPrint('Text selected: ${item.text}');
    });
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

  Future<void> _showSizeDialog(AppLocalizations? localizations) async {
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
                  Text(
                    localizations?.textSize ?? 'Text Size',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
                        child: Text(localizations?.cancel ?? 'Cancel', style: const TextStyle(color: Colors.white)),
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
                        child: Text(localizations?.apply ?? 'Apply', style: const TextStyle(color: Colors.blue)),
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

  Future<void> _showColorDialog(AppLocalizations? localizations) async {
    Color tempColor = _textColor;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localizations?.textColor ?? 'Text Color',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ColorPicker(
                    pickerColor: tempColor,
                    onColorChanged: (color) => tempColor = color,
                    pickerAreaHeightPercent: 0.7,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(localizations?.cancel ?? 'Cancel', style: const TextStyle(color: Colors.white)),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _textColor = tempColor;
                          if (_selectedTextItem != null) {
                            _selectedTextItem!.color = tempColor;
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: Text(localizations?.apply ?? 'Apply', style: const TextStyle(color: Colors.blue)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showFontDialog(AppLocalizations? localizations) async {
    final fonts = [
      'Roboto',
      'Arial',
      'Oi-Regular',
      'LilitaOne-Regular',
      'Comfortaa',
      'PTSansNarrow-Regular',
      'Courier',
      'Times New Roman',
      'Verdana',
      'Impact',
      'Comic Sans MS',
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
              Text(
                localizations?.fontFamily ?? 'Font Family',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: fonts.map((font) {
                    return ListTile(
                      title: Text(
                        font,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: font,
                          fontSize: 18,
                        ),
                      ),
                      trailing: _fontFamily == font ? const Icon(Icons.check, color: Colors.blue) : null,
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
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations?.close ?? 'Close', style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAlignDialog(AppLocalizations? localizations) async {
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
              Text(
                localizations?.textAlignment ?? 'Text Alignment',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAlignOption(Icons.format_align_left, TextAlign.left, localizations?.left ?? 'Left'),
                  _buildAlignOption(Icons.format_align_center, TextAlign.center, localizations?.center ?? 'Center'),
                  _buildAlignOption(Icons.format_align_right, TextAlign.right, localizations?.right ?? 'Right'),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations?.close ?? 'Close', style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlignOption(IconData icon, TextAlign align, String tooltip) {
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
      tooltip: tooltip,
    );
  }

  Future<void> _deleteSelectedItem() async {
    if (_selectedTextItem != null) {
      try {
        if (_selectedTextItem!.id != null) {
          final objectDao = dao.ObjectDao();
          await objectDao.softDeleteText(_selectedTextItem!.id!);
          debugPrint('Text deleted: ${_selectedTextItem!.text}');
        }
        setState(() {
          _textItems.remove(_selectedTextItem);
          _selectedTextItem = null;
          _textController.clear();
        });
      } catch (e) {
        debugPrint('Error deleting text: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete text: $e')),
          );
        }
      }
    }
  }

  Future<void> _saveChanges() async {
    try {
      setState(() {
        _selectedTextItem = null;
      });

      await Future.delayed(const Duration(milliseconds: 16));
      final boundary = _renderKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception(AppLocalizations.of(context)?.error ?? 'Rendering error');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception(AppLocalizations.of(context)?.error ?? 'Image conversion error');
      }

      final pngBytes = byteData.buffer.asUint8List();
      debugPrint('Changes applied with ${_textItems.length} text items');

      final history = EditHistory(
        imageId: widget.imageId,
        operationType: 'text_emoji',
        operationParameters: {
          'text_items_count': _textItems.length,
        },
        operationDate: DateTime.now(),
      );
      final db = MagicMomentDatabase.instance;
      final historyId = await db.insertHistory(history);
      debugPrint('History inserted with ID: $historyId');

      setState(() {
        if (_historyIndex < _history.length - 1) {
          _history.removeRange(_historyIndex + 1, _history.length);
        }
        _history.add({
          'image': pngBytes,
          'action': AppLocalizations.of(context)?.text ?? 'Text',
          'operationType': 'text_emoji',
          'parameters': {
            'text_items_count': _textItems.length,
          },
        });
        _historyIndex++;
      });

      await widget.onUpdateImage(
        pngBytes,
        action: AppLocalizations.of(context)?.text ?? 'Text',
        operationType: 'text_emoji',
        parameters: {
          'text_items_count': _textItems.length,
        },
      );

      widget.onApply(pngBytes);
    } catch (e) {
      debugPrint('Error saving text/emoji: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving text/emoji: $e')),
        );
      }
    } finally {
      widget.onCancel();
    }
  }
}

class TextItem {
  int? id;
  String text;
  Offset position;
  Color color;
  double size;
  String fontFamily;
  bool isBold;
  bool isItalic;
  bool hasShadow;
  TextAlign textAlign;
  Color backgroundColor;

  TextItem({
    this.id,
    required this.text,
    required this.position,
    required this.color,
    required this.size,
    required this.fontFamily,
    required this.isBold,
    required this.isItalic,
    required this.hasShadow,
    required this.textAlign,
    required this.backgroundColor,
  });
}