import 'package:MagicMoment/pagesCollage/collagePage.dart';
import 'package:MagicMoment/pagesEditing/editPage.dart';
import 'package:MagicMoment/pagesSettings/settingsPage.dart';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'themeWidjets/buildButtonIcon.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  final ImagePicker picker = ImagePicker();
  List<File> selectedImages = [];

  // Функция выбора изображений для коллажа
  Future<void> getImages() async {
    final appLocalizations = AppLocalizations.of(context)!;

    // Запрос разрешений
    if (!kIsWeb && await Permission.photos.request().isDenied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appLocalizations.permissionDenied)),
      );
      return;
    }

    try {
      final pickedFiles = await picker.pickMultiImage(
        imageQuality: 100,
        maxHeight: 1000,
        maxWidth: 1000,
      );

      if (pickedFiles == null || pickedFiles.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appLocalizations.selectedNon)),
        );
        return;
      }

      // Очищаем предыдущий выбор
      selectedImages.clear();

      // Берем максимум 6 изображений
      for (final file in pickedFiles.take(6)) {
        selectedImages.add(File(file.path));
      }

      // Проверяем что файлы существуют
      for (final file in selectedImages) {
        if (!await file.exists()) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File ${file.path} not found')),
          );
          return;
        }
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CollagePage(images: selectedImages),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  // Функция для выбора фото из галереи или камеры
  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await picker.pickImage(source: source);
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditPage(imageBytes: bytes),
            ),
          );
        } else {
          final file = File(image.path);
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditPage(imageBytes: file),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
      );
    }
  }

  // Диалог выбора источника изображения
  void _showImageSourceDialog() {
    final appLocalizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(appLocalizations.choose),
          content: Text(appLocalizations.from),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
              child: Text(appLocalizations.camera),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
              child: Text(appLocalizations.gallery),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: colorScheme.onInverseSurface,
        child: Row(
          children: [
            // Левая часть с изображением
            Container(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              child: Image.asset(
                'lib/assets/icons/photos.png',
                fit: BoxFit.contain,
              ),
            ),

            // Правая часть с контентом
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Кнопка настроек
                  Container(
                    margin: const EdgeInsets.only(top: 10, right: 25),
                    child: IconButton(
                      iconSize: 30,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings),
                      color: colorScheme.onSecondary,
                      tooltip: appLocalizations.settings,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Заголовок и описание
                  Container(
                    margin: const EdgeInsets.only(top: 40, right: 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Magic Moment',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            color: colorScheme.onSecondary,
                            fontFamily: 'LilitaOne-Regular',
                          ),
                        ),
                        Container(
                          width: 200,
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            appLocalizations.challengeText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSecondary,
                              fontFamily: 'PTSansNarrow-Regular',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Блок с кнопками
                  Container(
                    margin: const EdgeInsets.only(top: 20, right: 25),
                    child: Column(
                      children: [
                        CustomButton(
                          onPressed: _showImageSourceDialog,
                          text: appLocalizations.change,
                          icon: FluentIcons.image_24_regular,
                        ),
                        const SizedBox(height: 10),
                        CustomButton(
                          onPressed: getImages,
                          text: appLocalizations.create,
                          secondaryText: appLocalizations.collage,
                          icon: FluentIcons.layout_column_two_split_left_24_regular,
                        ),
                      ],
                    ),
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