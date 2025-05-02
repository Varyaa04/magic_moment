import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';

class ToolsPanel extends StatelessWidget {
  final Function(String) onToolSelected;

  const ToolsPanel({
    required this.onToolSelected,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    return Container(
      height: 100,
      color: Colors.black.withOpacity(0.7),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _buildToolButton(
            icon: FluentIcons.crop_24_filled,
            label: appLocalizations?.crop ?? 'Crop',
            tool: 'crop',
          ),
          _buildToolButton(
            icon: FluentIcons.brightness_high_24_filled,
            label: appLocalizations?.adjust ?? 'Adjust',
            tool: 'adjust',
          ),
          _buildToolButton(
            icon: Icons.filter_b_and_w,
            label: appLocalizations?.filters ?? 'Filters',
            tool: 'filters',
          ),
          _buildToolButton(
            icon: FluentIcons.text_effects_20_regular,
            label: appLocalizations?.effects ?? 'Effects',
            tool: 'effects',
          ),
          _buildToolButton(
            icon: FluentIcons.eraser_20_filled,
            label: appLocalizations?.eraser ?? 'Eraser',
            tool: 'eraser',
          ),
          _buildToolButton(
            icon: FluentIcons.ink_stroke_24_regular,
            label: appLocalizations?.draw ?? 'Draw',
            tool: 'draw',
          ),
          _buildToolButton(
            icon: FluentIcons.text_field_24_regular,
            label: appLocalizations?.text ?? 'Text',
            tool: 'text',
          ),
          _buildToolButton(
            icon: FluentIcons.emoji_sparkle_24_regular,
            label: appLocalizations?.emoji ?? 'Emoji',
            tool: 'emoji',
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required String tool,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => onToolSelected(tool),
            icon: Icon(icon, size: 28),
            color: Colors.white,
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}