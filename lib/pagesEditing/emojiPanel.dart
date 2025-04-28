import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';

class EmojiPanel extends StatefulWidget {
  final Function(String, double, Offset) onEmojiSelected;
  final VoidCallback onCancel;
  final VoidCallback onApply;

  const EmojiPanel({
    required this.onEmojiSelected,
    required this.onCancel,
    required this.onApply,
    Key? key,
  }) : super(key: key);

  @override
  _EmojiPanelState createState() => _EmojiPanelState();
}

class _EmojiPanelState extends State<EmojiPanel> {
  double _emojiSize = 48.0;
  String? _selectedEmoji;
  Offset _emojiPosition = Offset(0.5, 0.5); // Нормализованные координаты (0-1)

  final List<String> _emojis = [
    '😀', '😂', '😍', '🤔', '😎', '😢', '😡', '👋',
    '❤️', '👍', '👎', '✨', '🎉', '🔥', '💯', '🌟'
  ];

  void _applyEmoji() {
    if (_selectedEmoji != null) {
      widget.onEmojiSelected(_selectedEmoji!, _emojiSize, _emojiPosition);
      widget.onApply();
    } else {
      widget.onCancel();
    }
  }

  void _updateEmojiPosition(DragUpdateDetails details, Size panelSize) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    setState(() {
      _emojiPosition = Offset(
        (localPosition.dx / panelSize.width).clamp(0.0, 1.0),
        (localPosition.dy / panelSize.height).clamp(0.0, 1.0),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Emoji size slider
          Row(
            children: [
              Text(appLocalizations?.size ?? 'Size:',
                  style: TextStyle(color: Colors.white)),
              Expanded(
                child: Slider(
                  value: _emojiSize,
                  min: 24,
                  max: 96,
                  divisions: 6,
                  label: _emojiSize.round().toString(),
                  onChanged: (value) => setState(() => _emojiPosition = value as ui.Offset),
                ),
              ),
            ],
          ),

          // Emoji selection grid
          SizedBox(
            height: 60,
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _emojis.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedEmoji = _emojis[index];
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _selectedEmoji == _emojis[index]
                          ? Colors.blue.withOpacity(0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _emojis[index],
                        style: TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Emoji position indicator
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onPanUpdate: (details) => _updateEmojiPosition(details, constraints.biggest),
                  onTapDown: (details) => _updateEmojiPosition(
                      DragUpdateDetails(globalPosition: details.globalPosition),
                      constraints.biggest
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: _selectedEmoji != null
                          ? Text(
                        _selectedEmoji!,
                        style: TextStyle(fontSize: _emojiSize),
                      )
                          : Text(
                        appLocalizations?.selectEmoji ?? 'Select an emoji',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: Text(appLocalizations?.cancel ?? 'Cancel',
                    style: TextStyle(color: Colors.white)),
              ),
              SizedBox(width: 16),
              ElevatedButton(
                onPressed: _selectedEmoji != null ? _applyEmoji : null,
                child: Text(appLocalizations?.apply ?? 'Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}