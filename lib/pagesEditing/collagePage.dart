import 'dart:io';
import 'package:MagicMoment/pagesEditing/editPage.dart';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/language_provider.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class CollagePage extends StatefulWidget {
  final List<File> images; // Список фотографий

  const CollagePage({super.key, required this.images});

  @override
  State<CollagePage> createState() => _CollagePageState();
}

class _CollagePageState extends State<CollagePage> {
  int selectedTemplate = 1; // Выбранный шаблон коллажа

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
        Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditPage(imageBytes: widget.images.first),
                  ),
                );
              },
              icon: const Icon(FluentIcons.arrow_right_16_filled),
              color: Colors.white,
              iconSize: 30,
              tooltip: appLocalizations.nextEdit,
            ),
          ],
        ),
      ),

      const SizedBox(height: 10),

      // Контейнер для превью коллажа
      Container(
        width: 400,
        height: 470,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          border: Border.all(color: Colors.white24),
        ),
        child: _buildCollagePreview(selectedTemplate),
      ),

      const SizedBox(height: 10),

      // Лента с шаблонами коллажей
      SizedBox(
        height: 120,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: List.generate(5, (index) =>
              _buildCollageTemplate(index + 1),
          ),
        ),
      ),

        const SizedBox(height: 10),
        // Нижняя панель с кнопками
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(FluentIcons.arrow_hook_up_left_16_regular),
                color: Colors.white,
                iconSize: 30,
                tooltip: appLocalizations.back,
              ),
              IconButton(
                onPressed: () {
                  // Логика сохранения коллажа
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(appLocalizations.collage)),
                  );
                },
                icon: const Icon(FluentIcons.save_16_regular),
                color: Colors.white,
                iconSize: 30,
                tooltip: appLocalizations.save,
              ),
            ],
          ),
        ),
        ],
      ),
    ),
    );
  } // This closing brace was missing

  // Виджет для отображения шаблона коллажа
  Widget _buildCollageTemplate(int templateNumber) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                selectedTemplate = templateNumber;
              });
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: templateNumber == selectedTemplate
                    ? Colors.blue
                    : Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
                border: templateNumber == selectedTemplate
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(
                  '$templateNumber',
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
            '$templateNumber',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // Виджет для отображения превью коллажа
  Widget _buildCollagePreview(int templateNumber) {
    switch (templateNumber) {
      case 1:
        return StaggeredGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: Image.file(widget.images[0], fit: BoxFit.cover),
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: Image.file(widget.images[1], fit: BoxFit.cover),
            ),
          ],
        );
      case 2:
        return StaggeredGrid.count(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            StaggeredGridTile.count(
              crossAxisCellCount: 2,
              mainAxisCellCount: 2,
              child: Image.file(widget.images[0], fit: BoxFit.cover),
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: Image.file(widget.images[1], fit: BoxFit.cover),
            ),
            StaggeredGridTile.count(
              crossAxisCellCount: 1,
              mainAxisCellCount: 1,
              child: Image.file(widget.images[2], fit: BoxFit.cover),
            ),
          ],
        );
    // Добавьте другие шаблоны по аналогии
      default:
        return Center(
          child: Text(
            '$templateNumber',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        );
    }
  }
}