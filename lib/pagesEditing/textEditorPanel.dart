import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';

class TextEditor extends StatefulWidget {
  final Uint8List image;
  final Function(Uint8List) onUpdate;
  final VoidCallback onClose;
  final ThemeData theme;
  final double scaleFactor;

  const TextEditor({
    required this.image,
    required this.onUpdate,
    required this.onClose,
    required this.theme,
    this.scaleFactor = 1.0,
    Key? key,
  }) : super(key: key);

  @override
  _TextEditorState createState() => _TextEditorState();
}

class _TextEditorState extends State<TextEditor> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Color _textColor = Colors.white;
  Color _backgroundColor = Colors.transparent;
  double _fontSize = 24.0;
  TextAlign _textAlign = TextAlign.center;
  String _backgroundMode = 'none';
  ui.Image? _decodedImage;

  String _selectedFont = 'Roboto';
  FontWeight _selectedWeight = FontWeight.normal;
  bool _isItalic = false;

  final List<String> _availableFonts = [
    'Roboto',
    'Arial',
    'Times New Roman',
    'Courier New',
    'Verdana'
  ];
  final List<FontWeight> _availableWeights = [
    FontWeight.normal,
    FontWeight.bold,
    FontWeight.w100,
    FontWeight.w300,
    FontWeight.w500,
    FontWeight.w700,
    FontWeight.w900,
  ];

  @override
  void initState() {
    super.initState();
    _loadImage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }

  Future<void> _loadImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.image);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _decodedImage = frame.image;
        });
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _decodedImage?.dispose();
    super.dispose();
  }

  TextStyle get _currentTextStyle {
    return TextStyle(
      color: _textColor,
      fontSize: _fontSize * widget.scaleFactor,
      fontFamily: _selectedFont,
      fontWeight: _selectedWeight,
      fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
      backgroundColor: _backgroundMode == 'filled' ? _backgroundColor : null,
    );
  }

  void _toggleTextAlign() {
    setState(() {
      _textAlign = _textAlign == TextAlign.left
          ? TextAlign.center
          : _textAlign == TextAlign.center
          ? TextAlign.right
          : TextAlign.left;
    });
  }

  void _cycleBackgroundMode() {
    setState(() {
      _backgroundMode = _backgroundMode == 'none'
          ? 'color'
          : _backgroundMode == 'color'
          ? 'filled'
          : 'none';

      if (_backgroundMode == 'none') {
        _backgroundColor = Colors.transparent;
      } else if (_backgroundMode == 'color') {
        _backgroundColor = _textColor.withOpacity(0.3);
      } else {
        _backgroundColor = _textColor;
        _textColor = _getContrastColor(_textColor);
      }
    });
  }

  Color _getContrastColor(Color color) {
    return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  Future<void> _applyText() async {
    if (_textController.text.isEmpty) {
      widget.onClose();
      return;
    }

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint();

      if (_decodedImage != null) {
        canvas.drawImageRect(
          _decodedImage!,
          Rect.fromLTWH(0, 0, _decodedImage!.width.toDouble(),
              _decodedImage!.height.toDouble()),
          Rect.fromLTWH(0, 0, _decodedImage!.width.toDouble(),
              _decodedImage!.height.toDouble()),
          paint,
        );
      }

      final textPainter = TextPainter(
        text: TextSpan(
          text: _textController.text,
          style: _currentTextStyle,
        ),
        textAlign: _textAlign,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(maxWidth: _decodedImage?.width.toDouble() ?? 1000);

      final offset = Offset(
        (_decodedImage?.width.toDouble() ?? 1000) / 2 - textPainter.width / 2,
        (_decodedImage?.height.toDouble() ?? 1000) / 2 - textPainter.height / 2,
      );

      if (_backgroundMode == 'color') {
        final backgroundPaint = Paint()
          ..color = _backgroundColor
          ..style = PaintingStyle.fill;

        canvas.drawRect(
          Rect.fromPoints(
            offset,
            offset.translate(textPainter.width, textPainter.height),
          ),
          backgroundPaint,
        );
      }

      textPainter.paint(canvas, offset);

      final picture = recorder.endRecording();
      final image = await picture.toImage(
        _decodedImage?.width ?? 1000,
        _decodedImage?.height ?? 1000,
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      image.dispose();
      widget.onUpdate(bytes);
      widget.onClose();
    } catch (e) {
      debugPrint('Error applying text: $e');
      widget.onClose();
    }
  }

  Future<void> _showFontSizeDialog() async {
    double tempFontSize = _fontSize;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Font Size'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: tempFontSize,
                    min: 12,
                    max: 72,
                    divisions: 12,
                    label: tempFontSize.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        tempFontSize = value;
                      });
                    },
                  ),
                  Text('${tempFontSize.round()} px',
                      style: TextStyle(fontSize: 18)),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _fontSize = tempFontSize;
                });
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    return Theme(
      data: widget.theme,
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          actions: [
            IconButton(
              icon: Icon(Icons.format_align_left),
              onPressed: _toggleTextAlign,
              tooltip: 'Align Text',
            ),
            IconButton(
              icon: Icon(Icons.format_color_fill),
              onPressed: _cycleBackgroundMode,
              tooltip: 'Background',
            ),
            IconButton(
              icon: Icon(Icons.text_fields),
              onPressed: _showFontSizeDialog,
              tooltip: 'Font Size',
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: 200, // Установите минимальную высоту
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: null,
                      expands: true,
                      decoration: InputDecoration(
                        hintText: appLocalizations?.enterText ?? 'Enter your text',
                        border: InputBorder.none,
                        filled: _backgroundMode != 'none',
                        fillColor: _backgroundMode == 'color'
                            ? _backgroundColor
                            : Colors.transparent,
                      ),
                      style: _currentTextStyle,
                      textAlign: _textAlign,
                    ),
                  ),
                ),
              ),

              _buildColorControls(),
              _buildFontControls(),
              _buildActionButtons(appLocalizations),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text('Text Color:', style: TextStyle(color: Colors.white)),
            const SizedBox(width: 8),
            ...['red', 'green', 'blue', 'white', 'yellow', 'black'].map((color) {
              final colorValue = _getColorFromString(color);
              return GestureDetector(
                onTap: () => setState(() => _textColor = colorValue),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colorValue,
                    border: _textColor == colorValue
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.color_lens, color: _textColor),
              onPressed: () => _showColorPicker(false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            DropdownButton<String>(
              value: _selectedFont,
              dropdownColor: Colors.grey[800],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedFont = value);
                }
              },
              items: _availableFonts.map((font) {
                return DropdownMenuItem(
                  value: font,
                  child: Text(font, style: TextStyle(color: Colors.white)),
                );
              }).toList(),
            ),
            const SizedBox(width: 16),
            DropdownButton<FontWeight>(
              value: _selectedWeight,
              dropdownColor: Colors.grey[800],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedWeight = value);
                }
              },
              items: _availableWeights.map((weight) {
                return DropdownMenuItem(
                  value: weight,
                  child: Text(
                    _getWeightName(weight),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: weight,
                    ),
                  ),
                );
              }).toList(),
            ),
            IconButton(
              icon: Icon(Icons.format_italic,
                  color: _isItalic ? Colors.blue : Colors.white),
              onPressed: () => setState(() => _isItalic = !_isItalic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations? appLocalizations) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
        TextButton(
        onPressed: widget.onClose,
        child: Text(appLocalizations?.cancel ?? 'Cancel',
            style: TextStyle(color: Colors.white)
        ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _applyText,
          child: Text(appLocalizations?.apply ?? 'Apply'),
        ),
        ],
      ),
    );
  }

  Future<void> _showColorPicker(bool isBackground) async {
    Color currentColor = isBackground ? _backgroundColor : _textColor;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: (color) => currentColor = color,
              showLabel: true,
              pickerAreaHeightPercent: 0.7,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (isBackground) {
                    _backgroundColor = currentColor;
                  } else {
                    _textColor = currentColor;
                  }
                });
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Color _getColorFromString(String color) {
    switch (color) {
      case 'red': return Colors.red;
      case 'green': return Colors.green;
      case 'blue': return Colors.blue;
      case 'white': return Colors.white;
      case 'yellow': return Colors.yellow;
      case 'black': return Colors.black;
      default: return Colors.white;
    }
  }

  String _getWeightName(FontWeight weight) {
    switch (weight) {
      case FontWeight.normal: return 'Normal';
      case FontWeight.bold: return 'Bold';
      case FontWeight.w100: return 'Thin';
      case FontWeight.w300: return 'Light';
      case FontWeight.w500: return 'Medium';
      case FontWeight.w700: return 'Bold';
      case FontWeight.w900: return 'Black';
      default: return 'Normal';
    }
  }
}