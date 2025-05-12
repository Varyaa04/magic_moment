import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/rendering.dart';
import 'package:MagicMoment/pagesEditing/editPage.dart';
import 'package:MagicMoment/pagesEditing/image_utils.dart';
import 'package:MagicMoment/pagesCollage/templates/2photos_collage.dart';
import 'package:MagicMoment/pagesCollage/templates/3photos_collage.dart';
import 'package:MagicMoment/pagesCollage/templates/4photos_collage.dart';
import 'package:MagicMoment/pagesCollage/templates/5photos_collage.dart';
import 'package:MagicMoment/pagesCollage/templates/6photos_collage.dart';
import '../themeWidjets/colorPicker.dart';

class CollageEditorPage extends StatefulWidget {
  final List<Uint8List> images;
  const CollageEditorPage({super.key, required this.images});

  @override
  State<CollageEditorPage> createState() => _CollageEditorPageState();
}

class _CollageEditorPageState extends State<CollageEditorPage> {
  Color _backgroundColor = Colors.grey[900]!;
  Uint8List? _backgroundImage;
  double _borderRadius = 12;
  double _borderWidth = 2;
  Color _borderColor = Colors.blueAccent;
  final GlobalKey _collageKey = GlobalKey();
  int _selectedTemplateIndex = 0;
  late List<Widget> _templates;
  bool _showColorPicker = false;
  List<Offset> _imagePositions = [];
  List<double> _imageScales = [];
  int? _selectedImageIndex;
  bool _showImageControls = false;

  @override
  void initState() {
    super.initState();
    _templates = _generateTemplates();
    // Initialize positions and scales
    _imagePositions = List.generate(widget.images.length, (index) => Offset.zero);
    _imageScales = List.generate(widget.images.length, (index) => 1.0);
  }

  List<Widget> _generateTemplates() {
    final providers = widget.images.map((e) => MemoryImage(e)).toList();
    switch (providers.length) {
      case 2:
        return getTwoPhotosCollages(providers);
      case 3:
        return getThreePhotosCollages(providers);
      case 4:
        return getFourPhotosCollages(providers);
      case 5:
        return getFivePhotosCollages(providers);
      case 6:
        return getSixPhotosCollages(providers);
      default:
        return [const Center(child: Text('Выберите от 2 до 6 фото'))];
    }
  }

  Widget _buildEditableTemplate(Widget template) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedImageIndex = null;
          _showImageControls = false;
        });
      },
      child: Stack(
        children: [
          template,
          ..._buildDraggableImages(),
        ],
      ),
    );
  }

  List<Widget> _buildDraggableImages() {
    return List.generate(widget.images.length, (index) {
      return Positioned.fill(
        child: Align(
          alignment: Alignment(
            _imagePositions[index].dx,
            _imagePositions[index].dy,
          ),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedImageIndex = index;
                _showImageControls = true;
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _imagePositions[index] += Offset(
                  details.delta.dx / 100,
                  details.delta.dy / 100,
                );
                // Constrain position
                _imagePositions[index] = Offset(
                  _imagePositions[index].dx.clamp(-1.0, 1.0),
                  _imagePositions[index].dy.clamp(-1.0, 1.0),
                );
              });
            },
            child: Transform.scale(
              scale: _imageScales[index],
              child: Container(
                decoration: BoxDecoration(
                  border: _selectedImageIndex == index
                      ? Border.all(color: Colors.white, width: 2)
                      : null,
                ),
                child: Image.memory(
                  widget.images[index],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Future<void> _pickBackgroundImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() => _backgroundImage = bytes);
    }
  }

  void _changeBackgroundColor(Color color) {
    setState(() {
      _backgroundColor = color;
      _backgroundImage = null;
    });
  }

  void _changeBorderColor(Color color) {
    setState(() {
      _borderColor = color;
    });
  }

  void _resetImagePositions() {
    setState(() {
      _imagePositions = List.generate(widget.images.length, (index) => Offset.zero);
      _imageScales = List.generate(widget.images.length, (index) => 1.0);
    });
  }

  Future<void> _exportAndEdit() async {
    try {
      final imageBytes = await saveImage(_collageKey);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditPage(
            imageBytes: imageBytes,
            imageId: DateTime.now().microsecondsSinceEpoch,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Ошибка экспорта коллажа: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка экспорта: $e'),
          backgroundColor: Colors.red[800],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.grey[800],
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );


      return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: AppBar(
        title: const Text(
          'Редактор коллажа',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.grey[900],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: _exportAndEdit,
            tooltip: 'Редактировать коллаж',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Основное превью коллажа
            Expanded(
              child: Center(
                child: RepaintBoundary(
                  key: _collageKey,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? double.infinity : 600,
                      maxHeight: isMobile ? 400 : 500,
                    ),
                    decoration: BoxDecoration(
                      color: _backgroundImage == null ? _backgroundColor : null,
                      image: _backgroundImage != null
                          ? DecorationImage(
                        image: MemoryImage(_backgroundImage!),
                        fit: BoxFit.cover,
                      )
                          : null,
                      borderRadius: BorderRadius.circular(_borderRadius),
                      border: Border.all(
                        color: _borderColor,
                        width: _borderWidth,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(_borderRadius),
                      child: _buildEditableTemplate(_templates[_selectedTemplateIndex]),
                    ),
                  ),
                ),
              ),
            ),

            // Image controls (when an image is selected)
            if (_showImageControls && _selectedImageIndex != null)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.grey[900],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.zoom_in, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _imageScales[_selectedImageIndex!] += 0.1;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.zoom_out, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          if (_imageScales[_selectedImageIndex!] > 0.2) {
                            _imageScales[_selectedImageIndex!] -= 0.1;
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.rotate_left, color: Colors.white),
                      onPressed: () {
                        // TODO: Implement rotation
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.rotate_right, color: Colors.white),
                      onPressed: () {
                        // TODO: Implement rotation
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.center_focus_strong, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _imagePositions[_selectedImageIndex!] = Offset.zero;
                          _imageScales[_selectedImageIndex!] = 1.0;
                        });
                      },
                    ),
                  ],
                ),
              ),

            // Выбор шаблона
            Container(
              height: 100,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _templates.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTemplateIndex = index;
                      _resetImagePositions();
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedTemplateIndex == index
                            ? _borderColor
                            : Colors.grey[700]!,
                        width: 2,
                      ),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: _templates[index],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Панель настроек
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Настройки фона
                  Row(
                    children: [
                      Text('Фон:', style: TextStyle(color: Colors.grey[300])),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: buttonStyle,
                        onPressed: _pickBackgroundImage,
                        child: const Text('Изображение'),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showColorPicker = !_showColorPicker;
                          });
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _backgroundColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: _showColorPicker
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : null,
                        ),
                      ),
                    ],
                  ),
                  if (_showColorPicker)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ColorPicker(
                        pickerColor: _backgroundColor,
                        onColorChanged: _changeBackgroundColor,
                        pickerAreaHeightPercent: isMobile ? 0.4 : 0.3,
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Настройки скругления
                  Row(
                    children: [
                      Text('Скругление:', style: TextStyle(color: Colors.grey[300])),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: _borderColor,
                            inactiveTrackColor: Colors.grey[700],
                            thumbColor: _borderColor,
                            overlayColor: _borderColor.withOpacity(0.2),
                            valueIndicatorColor: _borderColor,
                          ),
                          child: Slider(
                            min: 0,
                            max: 50,
                            value: _borderRadius,
                            onChanged: (val) => setState(() => _borderRadius = val),
                          ),
                        ),
                      ),
                      Container(
                        width: 40,
                        alignment: Alignment.center,
                        child: Text(
                          _borderRadius.round().toString(),
                          style: TextStyle(color: Colors.grey[300]),
                        ),
                      ),
                    ],
                  ),

                  // Настройки рамки
                  Row(
                    children: [
                      Text('Толщина рамки:', style: TextStyle(color: Colors.grey[300])),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: _borderColor,
                            inactiveTrackColor: Colors.grey[700],
                            thumbColor: _borderColor,
                          ),
                          child: Slider(
                            min: 0,
                            max: 10,
                            value: _borderWidth,
                            onChanged: (val) => setState(() => _borderWidth = val),
                          ),
                        ),
                      ),
                      Container(
                        width: 40,
                        alignment: Alignment.center,
                        child: Text(
                          _borderWidth.round().toString(),
                          style: TextStyle(color: Colors.grey[300]),
                        ),
                      ),
                    ],
                  ),

                  // Цвет рамки
                  Row(
                    children: [
                      Text('Цвет рамки:', style: TextStyle(color: Colors.grey[300])),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Dialog(
                                backgroundColor: Colors.grey[900],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Выберите цвет рамки',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        height: isMobile ? 200 : 300,
                                        child: ColorPicker(
                                          pickerColor: _borderColor,
                                          onColorChanged: _changeBorderColor,
                                          pickerAreaHeightPercent: 0.8,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          backgroundColor: _borderColor,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          'Готово',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _borderColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _borderColor.withOpacity(0.5),
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}