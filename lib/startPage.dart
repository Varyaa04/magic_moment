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
  Future getImages() async {
    final appLocalizations = AppLocalizations.of(context)!;
    final pickedFile = await picker.pickMultiImage(
        imageQuality: 100,
        maxHeight: 1000,
        maxWidth: 1000);
    List<XFile> xfilePick = pickedFile;

    if (xfilePick.isNotEmpty) {
      for (var i = 0; i < xfilePick.length && i <= 5; i++) {
        selectedImages.add(File(xfilePick[i].path));
      }
      setState(() {});

      // После выбора изображений переходим на страницу коллажа
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CollagePage(images: selectedImages),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appLocalizations.selectedNon)));
    }
  }

  // Функция для выбора фото из галереи
  Future<void> _pickImage(ImageSource source) async {
    final image = await picker.pickImage(source: source);
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes(); // Для веба
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditPage(imageBytes: bytes),
          ),
        );
      } else {
        final file = File(image.path); // Для мобильных/десктоп
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditPage(imageBytes: file),
          ),
        );
      }
    }
  }

  // Функция для выбора нескольких изображений из галереи для коллажа
  void _dialogChoose() {
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
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _pickImage(ImageSource.camera);
                });
              },
              child: Text(appLocalizations.camera),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _pickImage(ImageSource.gallery);
                });
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
          Container(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          child: Image.asset(
            'lib/assets/icons/photos.png',
            fit: BoxFit.contain,
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, right: 25),
                    child: Tooltip(
                      message: appLocalizations.settings,
                      child: IconButton(
                        iconSize: 30,
                        onPressed: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.settings),
                        color: colorScheme.onSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

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
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            appLocalizations.challengeText,
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSecondary,
                              fontFamily: 'PTSansNarrow-Regular',
                            ),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Блок с кнопками
                  Container(
                    margin: const EdgeInsets.only(top: 20, right: 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CustomButton(
                          onPressed: () {
                            _dialogChoose();
                          },
                          text: appLocalizations.change,
                          icon: FluentIcons.image_24_regular,
                        ),
                        const SizedBox(height: 10),
                        CustomButton(
                          onPressed: () {
                            getImages();
                          },
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