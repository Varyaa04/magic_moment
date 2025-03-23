import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';


class EditPage extends StatelessWidget {
  final dynamic imageBytes;

  const EditPage({super.key, this.imageBytes});
  
  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
            if (imageBytes != null)
              if (kIsWeb == true)
                Image.memory(
                  imageBytes as Uint8List, // Для веба
                  width: 400,
                  height: 470,
                  fit: BoxFit.contain,
                  )
                else
                    Image.file(
                      imageBytes as File, // Для мобильных/десктоп
                      width: 400,
                      height: 470,
                      fit: BoxFit.contain,
                    )
            else
              Container(
                color: Colors.grey,
                width: 400,
                height: 470,
                child:const Center(
                  child:  Icon(
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
            const SizedBox(height: 2),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: List.generate(8, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                          },
                          icon: Icon(
                            _getIconForIndex(index), // Иконка для кнопки
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FutureBuilder<String>(
                          future: _getLabelForIndex(index, context),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Text(
                                'Загрузка...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              );
                            } else if (snapshot.hasError) {
                              return const Text(
                                'Ошибка',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              );
                            } else {
                              return Text(
                                snapshot.data ?? 'Кнопка',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              );
                            }
                          },
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

  Future<String> _getLabelForIndex(int index, BuildContext context) async {
    final appLocalizations = AppLocalizations.of(context);
    if (appLocalizations == null) {
      return 'Кнопка'; // Fallback, если AppLocalizations недоступен
    }
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
        return 'Кнопка'; // Fallback для неизвестных индексов
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
        return FluentIcons.edit_settings_20_regular;
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