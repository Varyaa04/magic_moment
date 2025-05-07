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
    final appLocalizations = AppLocalizations.of(context);

    // Запрос разрешений
    if (!kIsWeb) {
      final permission = await Permission.photos.request();
      if (permission.isDenied || permission.isPermanentlyDenied) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(appLocalizations?.permissionDeniedTitle ?? 'Permission Denied'),
            content: Text(appLocalizations?.permissionDenied ?? 'Please grant photo access to select images.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(appLocalizations?.ok ?? 'OK'),
              ),
            ],
          ),
        );
        return;
      }
    }

    try {
      final pickedFiles = await picker.pickMultiImage(
        imageQuality: 100,
        maxHeight: 1000,
        maxWidth: 1000,
      );

      if (pickedFiles.isEmpty) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(appLocalizations?.errorTitle ?? 'Error'),
            content: Text(appLocalizations?.selectedNon ?? 'No images selected.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(appLocalizations?.ok ?? 'OK'),
              ),
            ],
          ),
        );
        return;
      }

      // Проверяем количество выбранных изображений
      if (pickedFiles.length < 2) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(appLocalizations?.errorTitle ?? 'Error'),
            content: Text(appLocalizations?.tooFewImages ?? 'Please select at least 2 images for a collage.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(appLocalizations?.ok ?? 'OK'),
              ),
            ],
          ),
        );
        return;
      }

      if (pickedFiles.length > 6) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(appLocalizations?.errorTitle ?? 'Error'),
            content: Text(
              appLocalizations?.tooManyImages ?? 'You selected more than 6 images. Only the first 6 will be used.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(appLocalizations?.ok ?? 'OK'),
              ),
            ],
          ),
        );
      }

      // Очищаем предыдущий выбор
      selectedImages.clear();

      // Берем максимум 6 изображений
      for (final file in pickedFiles.take(6)) {
        final imageFile = File(file.path);
        if (!kIsWeb && !await imageFile.exists()) {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(appLocalizations?.errorTitle ?? 'Error'),
              content: Text('File ${file.path} not found.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(appLocalizations?.ok ?? 'OK'),
                ),
              ],
            ),
          );
          return;
        }
        selectedImages.add(imageFile);
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
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(appLocalizations?.errorTitle ?? 'Error'),
          content: Text('${appLocalizations?.error ?? 'An error occurred'}: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(appLocalizations?.ok ?? 'OK'),
            ),
          ],
        ),
      );
    }
  }

  // Функция для выбора фото из галереи или камеры
  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await picker.pickImage(source: source);
      if (image == null) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)?.errorTitle ?? 'Error'),
            content: Text(AppLocalizations.of(context)?.selectedNon ?? 'No image selected.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)?.ok ?? 'OK'),
              ),
            ],
          ),
        );
        return;
      }

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditPage(imageBytes: bytes, imageId: DateTime.now().microsecondsSinceEpoch,),
          ),
        );
      } else {
        final file = File(image.path);
        if (!await file.exists()) {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(AppLocalizations.of(context)?.errorTitle ?? 'Error'),
              content: Text('File ${file.path} not found.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)?.ok ?? 'OK'),
                ),
              ],
            ),
          );
          return;
        }
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditPage(imageBytes: file,imageId: DateTime.now().microsecondsSinceEpoch,),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)?.errorTitle ?? 'Error'),
          content: Text('${AppLocalizations.of(context)?.error ?? 'An error occurred'}: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)?.ok ?? 'OK'),
            ),
          ],
        ),
      );
    }
  }

  // Диалог выбора источника изображения
  void _showImageSourceDialog() {
    final appLocalizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(appLocalizations?.choose ?? 'Choose Image Source'),
          content: Text(appLocalizations?.from ?? 'Select an image from:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
              child: Text(appLocalizations?.camera ?? 'Camera'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
              child: Text(appLocalizations?.gallery ?? 'Gallery'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
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
                      tooltip: appLocalizations?.settings ?? 'Settings',
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
                            appLocalizations?.challengeText ?? 'Create amazing moments!',
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
                          text: appLocalizations?.change ?? 'Edit Photo',
                          icon: FluentIcons.image_24_regular,
                        ),
                        const SizedBox(height: 10),
                        CustomButton(
                          onPressed: getImages,
                          text: appLocalizations?.create ?? 'Create',
                          secondaryText: appLocalizations?.collage ?? 'Collage',
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