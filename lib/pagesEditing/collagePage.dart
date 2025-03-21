import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/language_provider.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'package:provider/provider.dart';

class CollagePage extends StatelessWidget {
  final List<File> images; // Список фотографий

  const CollagePage({super.key, required this.images});

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
                    // Логика сохранения коллажа
                  },
                  icon: const Icon(Icons.save_alt_outlined),
                  color: Colors.white,
                  iconSize: 30,
                  tooltip: appLocalizations.save,
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Контейнер для превью коллажа
            Container(
              width: 400,
              height: 470,
              color: Colors.grey,
              child: const Center(
                child: const Text(
                  'Превью коллажа',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Лента с шаблонами коллажей
            SizedBox(
              height: 120, // Высота ленты с шаблонами
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCollageTemplate(1), // Шаблон 1
                  _buildCollageTemplate(2), // Шаблон 2
                  _buildCollageTemplate(3), // Шаблон 3
                  _buildCollageTemplate(4), // Шаблон 4
                  _buildCollageTemplate(5), // Шаблон 5
                ],
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
          ],
        ),
      ),
    );
  }

  // Виджет для отображения шаблона коллажа
  Widget _buildCollageTemplate(int templateNumber) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              // Логика выбора шаблона
              print('Выбран шаблон $templateNumber');
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Шаблон $templateNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Шаблон $templateNumber',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}