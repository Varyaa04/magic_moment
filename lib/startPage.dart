import 'package:MagicMoment/pagesCollage/collagePage.dart';
import 'package:MagicMoment/pagesEditing/editPage.dart';
import 'package:MagicMoment/pagesSettings/settingsPage.dart';
import 'package:MagicMoment/themeWidjets/buildButtonIcon.dart';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart' as mobile_picker;
import 'image_picker_helper.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  List<Uint8List> selectedImages = [];

  // Функция выбора изображений для коллажа
  Future<void> getImages() async {
    final appLocalizations = AppLocalizations.of(context);
    List<Uint8List>? imageBytesList;

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
      imageBytesList = await ImagePickerHelper.pickMultiImages();

      if (imageBytesList == null || imageBytesList.length < 2) {
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

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CollageEditorPage(images: imageBytesList!),
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
  Future<void> _pickImage(mobile_picker.ImageSource source) async {
    try {
      final bytes = await ImagePickerHelper.pickImage();
      debugPrint('Picked image bytes length: ${bytes?.length ?? 0}');

      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No image selected or invalid image data')),
          );
        }
        return;
      }

      if (!mounted) return;

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
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
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
            if (!kIsWeb)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage(mobile_picker.ImageSource.camera);
                },
                child: Text(appLocalizations?.camera ?? 'Camera'),
              ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImage(mobile_picker.ImageSource.gallery);
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 500;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: colorScheme.onInverseSurface,
        child: Row(
          children: [
            // Левая часть с изображением (всегда у края без отступа)
            Container(
              width: isSmallScreen ? screenWidth * 0.4 : screenWidth * 0.5,
              padding: EdgeInsets.zero,
              margin: EdgeInsets.zero,
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
                    margin: EdgeInsets.only(
                      top: isSmallScreen ? 10 : 20,
                      right: isSmallScreen ? 15 : 25,
                    ),
                    child: IconButton(
                      iconSize: isSmallScreen ? 25 : 30,
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
                    margin: EdgeInsets.only(
                      top: isSmallScreen ? 20 : 40,
                      right: isSmallScreen ? 15 : 25,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Magic Moment',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 22 : 26,
                            color: colorScheme.onSecondary,
                            fontFamily: 'LilitaOne-Regular',
                          ),
                        ),
                        Container(
                          width: isSmallScreen ? 180 : 200,
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            appLocalizations?.challengeText ?? 'Create amazing moments!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 13,
                              color: colorScheme.onSecondary,
                              fontFamily: 'PTSansNarrow-Regular',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Кнопки
                  Container(
                    margin: EdgeInsets.only(
                      top: isSmallScreen ? 15 : 20,
                      right: isSmallScreen ? 15 : 25,
                    ),
                    child: Column(
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: isSmallScreen ? 250 : 300),
                          child: CustomButton(
                            onPressed: _showImageSourceDialog,
                            text: appLocalizations?.change ?? 'Edit Photo',
                            icon: FluentIcons.image_24_regular,
                            isSmall: isSmallScreen,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: isSmallScreen ? 250 : 300),
                          child: CustomButton(
                            onPressed: getImages,
                            text: appLocalizations?.create ?? 'Create',
                            secondaryText: appLocalizations?.collage ?? 'Collage',
                            icon: FluentIcons.layout_column_two_split_left_24_regular,
                            isSmall: isSmallScreen,
                          ),
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