import 'package:MagicMoment/pagesCollage/collagePage.dart';
import 'package:MagicMoment/pagesEditing/editPage.dart';
import 'package:MagicMoment/pagesSettings/settingsPage.dart';
import 'package:MagicMoment/themeWidjets/buildButtonIcon.dart';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker_web/image_picker_web.dart' as web_picker;


class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  final ImagePicker picker = ImagePicker();
  List<Uint8List> selectedImages = [];

  // Функция выбора изображений для коллажа
  Future<void> getImages() async {
    final appLocalizations = AppLocalizations.of(context);
    List<Uint8List> imageBytesList = [];

    // Разрешения на мобилке
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
      if (kIsWeb) {
        final pickedImages = await web_picker.ImagePickerWeb.getMultiImagesAsBytes();
        if (pickedImages != null && pickedImages.isNotEmpty) {
          imageBytesList.addAll(pickedImages.take(6));
        }
      } else {
        final picker = ImagePicker();
        final pickedFiles = await picker.pickMultiImage(imageQuality: 100, maxWidth: 1000, maxHeight: 1000);

        if (pickedFiles.isNotEmpty) {
          for (final file in pickedFiles.take(6)) {
            imageBytesList.add(await file.readAsBytes());
          }
        }
      }

      if (imageBytesList.length < 2) {
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

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CollageEditorPage(images: imageBytesList),
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
      Uint8List? bytes;

      if (kIsWeb) {
        if (source == ImageSource.gallery) {
          bytes = await web_picker.ImagePickerWeb.getImageAsBytes();
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera not supported on web')),
          );
          return;
        }
      } else {
        final XFile? image = await picker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 1024,
          maxHeight: 1024,
        );

        if (image == null) return;
        bytes = await image.readAsBytes();
      }

      if (bytes == null || bytes.isEmpty || !mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditPage(
            imageBytes: bytes,
            imageId: DateTime.now().microsecondsSinceEpoch,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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
            if (!kIsWeb) // Показываем кнопку камеры только не на вебе
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