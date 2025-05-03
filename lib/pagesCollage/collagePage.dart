import 'dart:io';
import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

// Импортируем файлы с шаблонами
import '2photos_collage.dart';
import '3photos_collage.dart';
import '4photos_collage.dart';
import '5photos_collage.dart';
import '6photos_collage.dart';

class CollagePage extends StatefulWidget {
  final List<File> images;

  const CollagePage({super.key, required this.images});

  @override
  _CollagePageState createState() => _CollagePageState();
}

class _CollagePageState extends State<CollagePage> {
  late List<ImageProvider> _imageProviders;
  late List<Widget> _collageTemplates;
  int _currentTemplateIndex = 0;
  final GlobalKey _collageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _imageProviders = widget.images.map((file) => FileImage(file)).toList();
    _loadCollageTemplates();
  }

  void _loadCollageTemplates() {
    switch (widget.images.length) {
      case 2:
        _collageTemplates = getTwoPhotosCollages(_imageProviders);
        break;
      case 3:
        _collageTemplates = getThreePhotosCollages(_imageProviders);
        break;
      case 4:
        _collageTemplates = getFourPhotosCollages(_imageProviders);
        break;
      case 5:
        _collageTemplates = getFivePhotosCollages(_imageProviders);
        break;
      case 6:
        _collageTemplates = getSixPhotosCollages(_imageProviders);
        break;
      default:
        _collageTemplates = [];
    }
  }

  void _changeTemplate(int index) {
    setState(() {
      _currentTemplateIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Column(
          children: [
            // Верхняя панель с кнопками
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(FluentIcons.arrow_left_16_filled),
                  color: Colors.white,
                  iconSize: 30,
                  tooltip: appLocalizations.back,
                ),
                IconButton(
                  onPressed:(){}, //_saveCollage,
                  icon: const Icon(FluentIcons.arrow_right_16_filled),
                  color: Colors.white,
                  iconSize: 30,
                  tooltip: appLocalizations.save,
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Превью коллажа
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _collageTemplates.isNotEmpty
                    ? RepaintBoundary(
                  key: _collageKey,
                  child: _collageTemplates[_currentTemplateIndex],
                )
                    : Center(
                  child: Text(
                    'No templates available',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Лента с шаблонами
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _collageTemplates.length,
                itemBuilder: (context, index) => _buildCollageTemplate(index),
              ),
            ),

            const SizedBox(height: 10),

            // Нижняя панель
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: _previousTemplate,
                  icon: const Icon(FluentIcons.arrow_hook_up_left_16_regular),
                  color: Colors.white,
                  iconSize: 30,
                  tooltip: appLocalizations.cancel,
                ),
                IconButton(
                  onPressed: _nextTemplate,
                  icon: const Icon(FluentIcons.arrow_hook_up_right_16_filled),
                  color: Colors.white,
                  iconSize: 30,
                  tooltip: appLocalizations.returnd,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollageTemplate(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => _changeTemplate(index),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _currentTemplateIndex == index
                    ? Colors.blue
                    : Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
                border: _currentTemplateIndex == index
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _collageTemplates[index],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Template ${index + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  void _nextTemplate() {
    if (_currentTemplateIndex < _collageTemplates.length - 1) {
      setState(() {
        _currentTemplateIndex++;
      });
    }
  }

  void _previousTemplate() {
    if (_currentTemplateIndex > 0) {
      setState(() {
        _currentTemplateIndex--;
      });
    }
  }

  // Future<void> _saveCollage() async {
  //   try {
  //     RenderRepaintBoundary boundary = _collageKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  //     ui.Image image = await boundary.toImage();
  //     ByteData? byteData = (await image.toByteData(format: ui.ImageByteFormat.png)) as ByteData?;
  //     Uint8List pngBytes = byteData!.buffer.asUint8List();
  //
  //     // Сохраняем в галерею
  //     final result = await ImageGallerySaver.saveImage(pngBytes);
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Collage saved successfully!')),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Failed to save collage: $e')),
  //     );
  //   }
  // }
}