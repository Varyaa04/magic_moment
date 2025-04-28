import 'package:flutter/material.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';


class AdjustButtonsPanel extends StatelessWidget {
  final VoidCallback onBack;
  final ValueChanged<int> onToolSelected;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool isUndoAvailable;
  final bool isRedoAvailable;

  const AdjustButtonsPanel({
    required this.onBack,
    required this.onToolSelected,
    required this.onUndo,
    required this.onRedo,
    required this.isUndoAvailable,
    required this.isRedoAvailable,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Заголовок с кнопкой назад и undo/redo
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.white,
                  onPressed: onBack,
                ),
                Text(
                  appLocalizations?.adjust ?? 'Регулировки',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.undo),
                  color: isUndoAvailable ? Colors.white : Colors.grey,
                  onPressed: isUndoAvailable ? onUndo : null,
                ),
                IconButton(
                  icon: const Icon(Icons.redo),
                  color: isRedoAvailable ? Colors.white : Colors.grey,
                  onPressed: isRedoAvailable ? onRedo : null,
                ),
              ],
            ),
          ),

          // Инструменты регулировки
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 15),
              children: [
                _buildToolButton(
                  icon: FluentIcons.brightness_high_24_filled,
                  label: appLocalizations?.brightness ?? 'Яркость',
                  index: 0,
                ),
                const SizedBox(width: 15,),
                _buildToolButton(
                  icon: Icons.contrast,
                  label: appLocalizations?.contrast ?? 'Контраст',
                  index: 1,
                ),
                const SizedBox(width: 15,),
                _buildToolButton(
                  icon: Icons.exposure,
                  label: appLocalizations?.exposure ?? 'Экспозиция',
                  index: 2,
                ),
                const SizedBox(width: 15,),
                _buildToolButton(
                  icon: Icons.gradient,
                  label: appLocalizations?.saturation ?? 'Насыщенность',
                  index: 3,
                ),
                const SizedBox(width: 15,),
                _buildToolButton(
                  icon: Icons.grain,
                  label: appLocalizations?.noise ?? 'Зернистость',
                  index: 4,
                ),
                const SizedBox(width: 15,),
                _buildToolButton(
                  icon: Icons.waves,
                  label: appLocalizations?.smooth ?? 'Гладкость',
                  index: 5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required int index,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => onToolSelected(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Container(
          width: 50, // Further decreased width
          height: 40, // Further decreased height
          decoration: BoxDecoration(
            color: Colors.grey[800],
            shape: BoxShape.circle,
          ),
          child: Center(
              child: _buildIcon(icon),
                ),
              ),
              const SizedBox(height: 15,width: 10,),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
    );
  }

  Widget _buildIcon(IconData icon) {
    try {
      return Icon(
        icon,
        color: Colors.white,
        size: 24,
      );
    } catch (e) {
      debugPrint('Error loading icon: $e');
      return const Icon(
        Icons.error_outline,
        color: Colors.red,
        size: 24,
      );
    }
  }
}