import 'package:MagicMoment/pagesEditing/collagePage.dart';
import 'package:MagicMoment/pagesEditing/editPage.dart';
import 'package:MagicMoment/pagesSettings/settingsPage.dart';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'dart:io';
import 'themeWidjets/buildButtonIcon.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/language_provider.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'package:provider/provider.dart';

// Функция для выбора фото из галереи
Future<void> _pickImage(ImageSource source, BuildContext context) async{
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: source);

  if( pickedFile != null){
    File imageFile = File(pickedFile.path);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditPage(imageFile: imageFile,), //передача изображения
        ),
    );
  }
}

// Функция для отображения диалога выбора
void _showImagePickerDialog(BuildContext context) {
  final appLocalizations = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title:  Text(appLocalizations.choose),
        content: Text(appLocalizations.from),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera, context);
            },
            child:  Text(appLocalizations.camera),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery, context);
            },
            child: Text(appLocalizations.gallery),
          ),
        ],
      );
    },
  );
}


class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: Colors.white,
        child: Row(
          children: [
            // Левая часть с изображением
            Expanded(
              child: Image.asset(
                'lib/assets/icons/photos.png',
                fit: BoxFit.contain,
              ),
            ),

            // Правая часть с текстом и кнопками
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Верхняя часть с иконкой настроек
                  Container(
                    margin: const EdgeInsets.only(top: 10, right: 25),
                    child: Tooltip(
                      message: appLocalizations.settings,
                      child: IconButton(
                      iconSize: 30,
                      onPressed: () async {
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsPage()),
                        );
                      },
                      icon: const Icon(Icons.settings),
                      color: Colors.black,
                    ),
                  ),
                  ),
                  const SizedBox(height: 10),

                  // Блок с текстом "Magic Moment" и описанием
                  Container(
                    margin: const EdgeInsets.only(top: 40, right: 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Magic Moment',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            color: Colors.black,
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
                          child:  Text(
                            appLocalizations.challengeText,
                            textAlign: TextAlign.justify,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black,
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
                          onPressed: () async{
                            _showImagePickerDialog(context);
                          },
                          text: appLocalizations.change,
                          icon: FluentIcons.image_24_regular,
                        ),
                        const SizedBox(height: 10),
                        CustomButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => CollagePage(images: [File('path1.jpg'), File('path2.jpg')]))
                            );
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