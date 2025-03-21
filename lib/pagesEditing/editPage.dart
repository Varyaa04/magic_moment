import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/language_provider.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'package:provider/provider.dart';

class EditPage extends StatelessWidget {
  final File? imageFile;

  const EditPage({super.key, this.imageFile});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Column(
          children: [
            // Верхняя панель с кнопками "Назад" и "Сохранить"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(FluentIcons.arrow_left_16_filled),
                  color: Colors.white,
                  iconSize: 30,
                  tooltip: appLocalizations.back,
                ),
                IconButton(
                  onPressed: () {
                    // Логика сохранения
                  },
                  icon: const Icon(Icons.save_alt_rounded),
                  color: Colors.white,
                  iconSize: 30,
                  tooltip: appLocalizations.save,
                ),
              ],
            ),

            const SizedBox(height: 10),
            // Контейнер для загруженной фотографии
            if (imageFile != null)
              Image.file(
                imageFile!,
                width: 400,
                height: 470,
                fit: BoxFit.cover,
              )
            else
              Container(
                color: Colors.grey,
                width: 400,
                height: 470,
                child: const Center(
                  child: Icon(
                    Icons.image,
                    color: Colors.white,
                  ),
                ),
              ),

            const SizedBox(height: 10),
            // Нижняя панель с кнопками "Назад" и "Вперед"
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () {
                    // Логика для кнопки "Назад"
                  },
                  icon: const Icon(FluentIcons.arrow_hook_up_left_16_regular),
                  color: Colors.white,
                  iconSize: 30,
                  tooltip: appLocalizations.back,
                ),
                IconButton(
                  onPressed: () {
                    // Логика для кнопки "Вперед"
                  },
                  icon: const Icon(FluentIcons.arrow_hook_up_right_16_filled),
                  color: Colors.white,
                  iconSize: 30,
                  tooltip: appLocalizations.next,
                ),
              ],
            ),
            Container(
              height: 2,
              color: Colors.white,
            ),
            const SizedBox(height: 2,),
            SizedBox(
              height: 100, // Увеличиваем высоту ленты, чтобы вместить текст
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: List.generate(8, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // Центрируем содержимое
                      children: [
                        IconButton(
                          onPressed: () {
                            print('Кнопка ${index + 1} нажата');
                          },
                          icon: Icon(
                            _getIconForIndex(index), // Иконка для кнопки
                            color: Colors.white,
                            size: 30,
                          ),
                          tooltip: 'Кнопка ${index + 1}', // Подсказка
                        ),
                        const SizedBox(height: 4), // Отступ между иконкой и текстом
                        Text(
                          _getLabelForIndex(index), // Текст под кнопкой
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLabelForIndex(int index) {

    final appLocalizations = AppLocalizations.of(index as BuildContext)!;
    final languageProvider = Provider.of<LanguageProvider>(index as BuildContext);
    switch (index) {
      case 0:
        return appLocalizations.crop;
      case 1:
        return appLocalizations.brightness;
      case 2:
        return appLocalizations.contrast;
      case 3:
        return appLocalizations.adjust;
      case 4:
        return appLocalizations.filters;
      case 5:
        return appLocalizations.draw;
      case 6:
        return appLocalizations.text;
      case 7:
        return appLocalizations.effects;
      default:
        return 'Кнопка';
    }
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return FluentIcons.image_split_20_filled;
      case 1:
        return FluentIcons.brightness_high_16_filled;
      case 2:
        return Icons.contrast;
      case 3:
        return FluentIcons.edit_20_filled;
      case 4:
        return Icons.filter;
      case 5:
        return FluentIcons.draw_image_20_filled;
      case 6:
        return FluentIcons.text_field_16_filled;
      case 7:
        return FluentIcons.emoji_sparkle_16_filled;
        default:
        return FluentIcons.emoji_sparkle_16_filled;
    }
  }
}
