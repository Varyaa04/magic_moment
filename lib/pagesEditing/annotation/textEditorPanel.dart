import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import '../../database/editHistory.dart';
import '../../database/objectDao.dart' as dao;
import '../../database/objectsModels.dart';
import '../../database/magicMomentDatabase.dart';
import '../../themeWidjets/colorPicker.dart';

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
  _TextEditorPanelState createState() => _TextEditorPanelState();
}

class _TextEditorPanelState extends State<TextEditorPanel> with SingleTickerProviderStateMixin {
  final List<TextItem> _textItems = [];
  TextItem? _selectedText;
  final List<Map<String, dynamic>> _history = [];
  int _historyIndex = -1;
  final GlobalKey _imageKey = GlobalKey();
  bool _isProcessing = false;
  bool _isInitialized = false;
  String _currentText = '';
  Color _currentColor = Colors.black;
  double _currentFontSize = 20.0;
  String _currentFontFamily = 'Roboto';
  FontWeight _currentFontWeight = FontWeight.normal;
  FontStyle _currentFontStyle = FontStyle.normal;
  TextAlign _currentAlignment = TextAlign.left;
  double _currentScale = 1.0;
  double _currentRotation = 0.0;
  final GlobalKey _renderKey = GlobalKey();
  final TextEditingController _textController = TextEditingController();
  TextItem? _selectedTextItem;
  Color _textBackgroundColor = Colors.transparent;
  Color _textColor = Colors.white;
  double _textSize = 24.0;
  String _fontFamily = 'Roboto';
  bool _isBold = false;
  bool _isItalic = false;
  bool _hasShadow = true;
  TextAlign _textAlign = TextAlign.center;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initialize();
  }
  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }


  Future<void> _initialize() async {
    try {
      await _loadTextFromDb();
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
    } catch (e) {
      _handleError('Initialization failed: $e');
    }
  }

  Future<void> _addText() async {
    if (_currentText.isEmpty || _isProcessing || !_isInitialized) return;
    setState(() => _isProcessing = true);

    try {
      final newTextItem = TextItem(
        text: _currentText,
        position: const Offset(100, 100),
        color: _currentColor,
        fontSize: _currentFontSize,
        fontFamily: _currentFontFamily,
        fontWeight: _currentFontWeight,
        fontStyle: _currentFontStyle,
        alignment: _currentAlignment,
        scale: _currentScale,
        rotation: _currentRotation,
        backgroundColor: _textBackgroundColor,
        hasShadow: _hasShadow,
      );

      final history = EditHistory(
        imageId: widget.imageId,
        operationType: 'text',
        operationParameters: {
          'text': newTextItem.text,
          'fontSize': newTextItem.fontSize,
        },
        operationDate: DateTime.now(),
      );
      final db = MagicMomentDatabase.instance;
      final historyId = await db.insertHistory(history);

      final objectDao = dao.ObjectDao();
      final textId = await objectDao.insertText(TextObject(
        imageId: widget.imageId,
        text: newTextItem.text,
        positionX: newTextItem.position.dx,
        positionY: newTextItem.position.dy,
        fontSize: newTextItem.fontSize,
        fontWeight: newTextItem.fontWeight == FontWeight.bold ? 'bold' : 'normal',
        fontStyle: newTextItem.fontStyle == FontStyle.italic ? 'italic' : 'normal',
        alignment: newTextItem.alignment == TextAlign.center
            ? 'center'
            : newTextItem.alignment == TextAlign.right
            ? 'right'
            : 'left',
        color: '#${newTextItem.color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        fontFamily: newTextItem.fontFamily,
        scale: newTextItem.scale,
        rotation: newTextItem.rotation,
        historyId: historyId,
      ));

      setState(() {
        newTextItem.id = textId;
        _textItems.add(newTextItem);
        _selectedText = newTextItem;
        _textController.clear();
        _currentText = '';
        debugPrint('Text added: ${newTextItem.text}, ID: $textId');
      });
    } catch (e) {
      _handleError('Failed to add text: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _applyChanges() async {
    if (_isProcessing || !_isInitialized) return;
    setState(() {
      _isProcessing = true;
      _selectedText = null;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 16));
      final boundary = _imageKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception(AppLocalizations.of(context)?.error ?? 'Rendering error');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose(); // Освобождаем изображение
      if (byteData == null) {
        throw Exception(AppLocalizations.of(context)?.errorEncode ?? 'Image conversion error');
      }

      final pngBytes = byteData.buffer.asUint8List();
      debugPrint('Changes applied with ${_textItems.length} texts');

      final history = EditHistory(
        historyId: null,
        imageId: widget.imageId,
        operationType: 'text',
        operationParameters: {
          'texts_count': _textItems.length,
        },
        operationDate: DateTime.now(),
        snapshotPath: kIsWeb ? null : '${Directory.systemTemp.path}/text_${DateTime.now().millisecondsSinceEpoch}.png',
        snapshotBytes: kIsWeb ? pngBytes : null,
      );
      final db = MagicMomentDatabase.instance;
      final historyId = await db.insertHistory(history);

      final objectDao = dao.ObjectDao();
      for (final text in _textItems) {
        await objectDao.insertText(TextObject(
          imageId: widget.imageId,
          text: text.text,
          positionX: text.position.dx,
          positionY: text.position.dy,
          fontSize: text.fontSize,
          fontWeight: text.fontWeight.toString(),
          fontStyle: text.fontStyle.toString(),
          alignment: text.alignment.toString(),
          color: '#${text.color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
          fontFamily: text.fontFamily,
          scale: text.scale,
          rotation: text.rotation,
          historyId: historyId,
        ));
      }

      if (!mounted) return;

      setState(() {
        if (_historyIndex < _history.length - 1) {
          _history.removeRange(_historyIndex + 1, _history.length);
        }
        _history.add({
          'image': pngBytes,
          'action': AppLocalizations.of(context)?.text ?? 'Text',
          'operationType': 'text',
          'parameters': {
            'texts_count': _textItems.length,
          },
        });
        _historyIndex++;
      });

      await _updateImage(
        newImage: pngBytes,
        action: AppLocalizations.of(context)?.text ?? 'Text',
        operationType: 'text',
        parameters: {
          'texts_count': _textItems.length,
        },
      );

      widget.onApply(pngBytes);
    } catch (e) {
      debugPrint('Error applying text: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)?.error ?? 'Error'}: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
      widget.onCancel();
    }
  }

  Future<void> _loadTextFromDb() async {
    try {
      final objectDao = dao.ObjectDao();
      final saved = await objectDao.getTexts(widget.imageId);
      debugPrint('Loaded ${saved.length} texts from DB for imageId: ${widget.imageId}');

      final newTexts = saved.map((t) => TextItem(
        id: t.id,
        text: t.text,
        position: Offset(t.positionX, t.positionY),
        color: Color(int.parse(t.color.replaceFirst('#', '0xff'))),
        fontSize: t.fontSize,
        fontFamily: t.fontFamily,
        fontWeight: t.fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
        fontStyle: t.fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
        alignment: t.alignment == 'center'
            ? TextAlign.center
            : t.alignment == 'right'
            ? TextAlign.right
            : TextAlign.left,
        scale: t.scale,
        rotation: t.rotation,
        backgroundColor: Colors.transparent,
        hasShadow: true,
      )).toList();

      if (mounted) {
        setState(() => _textItems.addAll(newTexts));
      }
    } catch (e) {
      _handleError('Failed to load texts: $e');
    }
  }

  Future<void> _updateImage({
    required Uint8List newImage,
    required String action,
    required String operationType,
    required Map<String, dynamic> parameters,
  }) async {
    try {
      await widget.onUpdateImage(
        newImage,
        action: action,
        operationType: operationType,
        parameters: parameters,
      );
      debugPrint('Image updated: $action');
    } catch (e) {
      _handleError('Failed to update image: $e');
      rethrow;
    }
  }

  Future<void> _undo() async {
    if (_historyIndex <= 0 || _isProcessing || !_isInitialized) return;
    setState(() => _isProcessing = true);

    try {
      setState(() {
        _historyIndex--;
        _textItems.clear();
        _selectedText = null;
      });

      await _updateImage(
        newImage: _history[_historyIndex]['image'],
        action: 'Undo text',
        operationType: 'undo',
        parameters: {
          'previous_action': _history[_historyIndex + 1]['action'],
        },
      );
      debugPrint('Undo performed, history index: $_historyIndex');
    } catch (e) {
      _handleError('Failed to undo: $e');
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

  void _updateTextProperties({
    Color? color,
    double? fontSize,
    String? fontFamily,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextAlign? alignment,
    double? scale,
    double? rotation,
    Color? backgroundColor,
    bool? hasShadow,
  }) {
    setState(() {
      if (color != null) _currentColor = color;
      if (fontSize != null) _currentFontSize = fontSize;
      if (fontFamily != null) _currentFontFamily = fontFamily;
      if (fontWeight != null) _currentFontWeight = fontWeight;
      if (fontStyle != null) _currentFontStyle = fontStyle;
      if (alignment != null) _currentAlignment = alignment;
      if (scale != null) _currentScale = scale;
      if (rotation != null) _currentRotation = rotation;
      if (backgroundColor != null) _textBackgroundColor = backgroundColor;
      if (hasShadow != null) _hasShadow = hasShadow;

      if (_selectedText != null) {
        _selectedText!.color = _currentColor;
        _selectedText!.fontSize = _currentFontSize;
        _selectedText!.fontFamily = _currentFontFamily;
        _selectedText!.fontWeight = _currentFontWeight;
        _selectedText!.fontStyle = _currentFontStyle;
        _selectedText!.alignment = _currentAlignment;
        _selectedText!.scale = _currentScale;
        _selectedText!.rotation = _currentRotation;
        _selectedText!.backgroundColor = _textBackgroundColor;
        _selectedText!.hasShadow = _hasShadow;
      }
    });
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
                  child: _isInitialized
                      ? GestureDetector(
                    onTap: () => setState(() => _selectedText = null),
                    child: RepaintBoundary(
                      key: _imageKey,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Center(child: Image.memory(widget.image, fit: BoxFit.contain)),
                          ..._textItems.map(_buildTextWidget),
                        ],
                      ),
                    ),
                  )
                      : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
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
                child: const Center(child: CircularProgressIndicator(color: Colors.white)),
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
      title: Text(localizations?.text ?? 'Text', style: const TextStyle(color: Colors.white)),
      actions: [
        IconButton(
          icon: Icon(Icons.undo, color: _historyIndex > 0 && _isInitialized ? Colors.white : Colors.grey),
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

  Widget _buildTextWidget(TextItem textItem) {
    final isSelected = textItem == _selectedText;
    return Positioned(
      left: textItem.position.dx,
      top: textItem.position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            textItem.position += details.delta;
            debugPrint('Text moved to: ${textItem.position}');
          });
        },
        onTap: () {
          setState(() {
            _selectedText = textItem;
            _currentText = textItem.text;
            _currentColor = textItem.color;
            _currentFontSize = textItem.fontSize;
            _currentFontFamily = textItem.fontFamily;
            _currentFontWeight = textItem.fontWeight;
            _currentFontStyle = textItem.fontStyle;
            _currentAlignment = textItem.alignment;
            _currentScale = textItem.scale;
            _currentRotation = textItem.rotation;
            _textBackgroundColor = textItem.backgroundColor;
            _hasShadow = textItem.hasShadow;
            _textController.text = textItem.text;
            debugPrint('Text selected: ${textItem.text}');
          });
        },
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Transform.rotate(
              angle: textItem.rotation,
              child: Transform.scale(
                scale: textItem.scale,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: textItem.backgroundColor,
                    border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
                    boxShadow: textItem.hasShadow
                        ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(2, 2),
                      ),
                    ]
                        : [],
                  ),
                  child: SizedBox(
                    width: 200,
                    child: Text(
                      textItem.text,
                      style: TextStyle(
                        color: textItem.color,
                        fontSize: textItem.fontSize,
                        fontFamily: textItem.fontFamily,
                        fontWeight: textItem.fontWeight,
                        fontStyle: textItem.fontStyle,
                      ),
                      textAlign: textItem.alignment,
                    ),
                  ),
                ),
              ),
            ),
            if (isSelected)
              GestureDetector(
                onTap: () => _confirmDeleteText(textItem),
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

  Future<void> _confirmDeleteText(TextItem textItem) async {
    final localizations = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations?.confirmDelete ?? 'Delete Text'),
        content: Text(localizations?.confirmDeleteMessage ?? 'Are you sure you want to delete this text?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(localizations?.delete ?? 'Delete', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() {
          _textItems.remove(textItem);
          _selectedText = null;
        });
        final objectDao = dao.ObjectDao();
        if (textItem.id != null) {
          await objectDao.softDeleteText(textItem.id!);
          debugPrint('Text deleted: ${textItem.text}');
        }
      } catch (e) {
        _handleError('Failed to delete text: $e');
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
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: localizations?.input ?? 'Input'),
              Tab(text: localizations?.style ?? 'Style'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
          ),
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTextInput(localizations),
                _buildStylePanel(localizations),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations? localizations) {
    return TabBar(
      tabs: [
        Tab(text: localizations?.input ?? 'Input'),
        Tab(text: localizations?.style ?? 'Style'),
      ],
      labelColor: Colors.white,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Colors.blue,
    );
  }

  Widget _buildTextInput(AppLocalizations? localizations) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: localizations?.enterText ?? 'Enter text',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() => _currentText = value);
                if (_selectedText != null) {
                  _selectedText!.text = value;
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _addText,
            tooltip: localizations?.addText ?? 'Add Text',
          ),
        ],
      ),
    );
  }

  Widget _buildStylePanel(AppLocalizations? localizations) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '${localizations?.color ?? 'Color'}:',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  final color = await showDialog<Color>(
                    context: context,
                    builder: (context) => ColorPickerDialog(initialColor: _currentColor),
                  );
                  if (color != null) {
                    _updateTextProperties(color: color);
                  }
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _currentColor,
                    border: Border.all(color: Colors.white, width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${localizations?.size ?? 'Size'}:',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _currentFontSize,
                  min: 10,
                  max: 50,
                  divisions: 40,
                  activeColor: Colors.blue,
                  inactiveColor: Colors.grey[700],
                  label: _currentFontSize.round().toString(),
                  onChanged: (value) => _updateTextProperties(fontSize: value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${localizations?.font ?? 'Font'}:',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _currentFontFamily,
                dropdownColor: Colors.grey[900],
                style: const TextStyle(color: Colors.white),
                items: ['Roboto', 'Arial', 'Times New Roman', 'Courier New'].map((font) {
                  return DropdownMenuItem(
                    value: font,
                    child: Text(font),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _updateTextProperties(fontFamily: value);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.format_bold,
                  color: _currentFontWeight == FontWeight.bold ? Colors.blue : Colors.white,
                ),
                onPressed: () => _updateTextProperties(
                  fontWeight: _currentFontWeight == FontWeight.bold ? FontWeight.normal : FontWeight.bold,
                ),
                tooltip: localizations?.bold ?? 'Bold',
              ),
              IconButton(
                icon: Icon(
                  Icons.format_italic,
                  color: _currentFontStyle == FontStyle.italic ? Colors.blue : Colors.white,
                ),
                onPressed: () => _updateTextProperties(
                  fontStyle: _currentFontStyle == FontStyle.italic ? FontStyle.normal : FontStyle.italic,
                ),
                tooltip: localizations?.italic ?? 'Italic',
              ),
              IconButton(
                icon: Icon(
                  Icons.format_align_left,
                  color: _currentAlignment == TextAlign.left ? Colors.blue : Colors.white,
                ),
                onPressed: () => _updateTextProperties(alignment: TextAlign.left),
                tooltip: localizations?.alignLeft ?? 'Align Left',
              ),
              IconButton(
                icon: Icon(
                  Icons.format_align_center,
                  color: _currentAlignment == TextAlign.center ? Colors.blue : Colors.white,
                ),
                onPressed: () => _updateTextProperties(alignment: TextAlign.center),
                tooltip: localizations?.alignCenter ?? 'Align Center',
              ),
              IconButton(
                icon: Icon(
                  Icons.format_align_right,
                  color: _currentAlignment == TextAlign.right ? Colors.blue : Colors.white,
                ),
                onPressed: () => _updateTextProperties(alignment: TextAlign.right),
                tooltip: localizations?.alignRight ?? 'Align Right',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${localizations?.background ?? 'Background'}:',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  final color = await showDialog<Color>(
                    context: context,
                    builder: (context) => ColorPickerDialog(initialColor: _textBackgroundColor),
                  );
                  if (color != null) {
                    _updateTextProperties(backgroundColor: color);
                  }
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _textBackgroundColor,
                    border: Border.all(color: Colors.white, width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Checkbox(
                value: _hasShadow,
                activeColor: Colors.blue,
                onChanged: (value) => _updateTextProperties(hasShadow: value ?? false),
              ),
              Text(
                localizations?.shadow ?? 'Shadow',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TextItem {
  int? id;
  String text;
  Offset position;
  Color color;
  double fontSize;
  String fontFamily;
  FontWeight fontWeight;
  FontStyle fontStyle;
  TextAlign alignment;
  double scale;
  double rotation;
  Color backgroundColor;
  bool hasShadow;

  TextItem({
    this.id,
    required this.text,
    required this.position,
    required this.color,
    required this.fontSize,
    required this.fontFamily,
    required this.fontWeight,
    required this.fontStyle,
    required this.alignment,
    required this.scale,
    required this.rotation,
    required this.backgroundColor,
    required this.hasShadow,
  });
}

class ColorPickerDialog extends StatelessWidget {
  final Color initialColor;

  const ColorPickerDialog({required this.initialColor, super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick a color'),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: initialColor,
          onColorChanged: (color) => Navigator.pop(context, color)
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}