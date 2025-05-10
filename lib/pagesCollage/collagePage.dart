import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/rendering.dart';
import 'package:MagicMoment/pagesEditing/editPage.dart';
import 'package:MagicMoment/pagesEditing/toolsPanel.dart';
import 'package:MagicMoment/pagesEditing/image_utils.dart';
import 'package:MagicMoment/pagesCollage/templates/2photos_collage.dart';
import 'package:MagicMoment/pagesCollage/templates/3photos_collage.dart';
import 'package:MagicMoment/pagesCollage/templates/4photos_collage.dart';
import 'package:MagicMoment/pagesCollage/templates/5photos_collage.dart';
import 'package:MagicMoment/pagesCollage/templates/6photos_collage.dart';

class CollageEditorPage extends StatefulWidget {
  final List<Uint8List> images;
  const CollageEditorPage({super.key, required this.images});

  @override
  State<CollageEditorPage> createState() => _CollageEditorPageState();
}

class _CollageEditorPageState extends State<CollageEditorPage> {
  Color _backgroundColor = Colors.white;
  Uint8List? _backgroundImage;
  double _borderRadius = 12;
  double _borderWidth = 2;
  Color _borderColor = Colors.black;
  final GlobalKey _collageKey = GlobalKey();
  int _selectedTemplateIndex = 0;
  late List<Widget> _templates;

  @override
  void initState() {
    super.initState();
    _templates = _generateTemplates();
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
        SnackBar(content: Text('Ошибка экспорта: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактор коллажа'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _exportAndEdit,
            tooltip: 'Редактировать коллаж',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RepaintBoundary(
              key: _collageKey,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _backgroundImage == null ? _backgroundColor : null,
                  image: _backgroundImage != null
                      ? DecorationImage(
                    image: MemoryImage(_backgroundImage!),
                    fit: BoxFit.cover,
                  )
                      : null,
                  borderRadius: BorderRadius.circular(_borderRadius),
                  border: Border.all(color: _borderColor, width: _borderWidth),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_borderRadius),
                  child: _templates[_selectedTemplateIndex],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _templates.length,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => setState(() => _selectedTemplateIndex = index),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedTemplateIndex == index ? Colors.blue : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _templates[index],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('Фон:'),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _pickBackgroundImage,
                      child: const Text('Изображение'),
                    ),
                    const SizedBox(width: 8),
                    ...[
                      Colors.white,
                      Colors.black,
                      Colors.blue,
                      Colors.green,
                      Colors.red,
                      Colors.yellow
                    ].map((color) => GestureDetector(
                      onTap: () => _changeBackgroundColor(color),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _backgroundColor == color ? Colors.grey.shade800 : Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Скругление:'),
                    Expanded(
                      child: Slider(
                        min: 0,
                        max: 50,
                        value: _borderRadius,
                        onChanged: (val) => setState(() => _borderRadius = val),
                      ),
                    )
                  ],
                ),
                Row(
                  children: [
                    const Text('Толщина рамки:'),
                    Expanded(
                      child: Slider(
                        min: 0,
                        max: 10,
                        value: _borderWidth,
                        onChanged: (val) => setState(() => _borderWidth = val),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
          const ToolsPanel(onToolSelected: _noop),
        ],
      ),
    );
  }

  static void _noop(String _) {}
}
