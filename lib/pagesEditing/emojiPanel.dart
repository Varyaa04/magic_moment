import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';

class EmojiPanel extends StatefulWidget {
  final Uint8List originalImage;
  final Function(Uint8List) onImageChanged;
  final VoidCallback onCancel;
  final VoidCallback onApply;

  const EmojiPanel({
    required this.originalImage,
    required this.onImageChanged,
    required this.onCancel,
    required this.onApply,
    Key? key,
  }) : super(key: key);

  @override
  _EmojiPanelState createState() => _EmojiPanelState();
}

class _EmojiPanelState extends State<EmojiPanel> {
  double _emojiSize = 48.0;
  Offset _emojiPosition = Offset(0.5, 0.5);
  String? _selectedEmoji;
  List<Offset> _emojiPositions = [];

  final List<String> _emojis = [
    '😀',
    '😂',
    '😍',
    '🤔',
    '😎',
    '😢',
    '😡',
    '👋',
    '❤️',
    '👍',
    '👎',
    '✨',
    '🎉',
    '🔥',
    '💯',
    '🌟'
  ];

  Future<void> _applyEmoji() async {
    if (_selectedEmoji == null) return;

    final ui.Picture picture = _createPictureWithEmoji();

    widget.onApply();
  }

  ui.Picture _createPictureWithEmoji() {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    // Draw selected emoji
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
          text: _selectedEmoji, style: TextStyle(fontSize: _emojiSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    final Offset emojiOffset =
        _emojiPosition - Offset(textPainter.width / 2, textPainter.height / 2);
    textPainter.paint(canvas, emojiOffset);

    return recorder.endRecording();
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
          // ... (other widgets remain the same)

          // Image with selected emoji
          Expanded(
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _emojiPosition = Offset(
                    details.localPosition.dx,
                    details.localPosition.dy,
                  );
                });
              },
              child: CustomPaint(
                painter:
                    _EmojiPainter(_selectedEmoji, _emojiPosition, _emojiSize),
                child: Image.memory(
                  widget.originalImage,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // ... (other widgets remain the same)

          // Save button
          TextButton(
            onPressed: widget.onApply,
            child: Text(appLocalizations?.save ?? 'Save'),
          ),
        ],
      ),
    );
  }
}

class _EmojiPainter extends CustomPainter {
  final String? _emoji;
  final Offset _position;
  final double _size;

  _EmojiPainter(this._emoji, this._position, this._size);

  @override
  void paint(Canvas canvas, Size size) {
    if (_emoji != null) {
      final TextPainter textPainter = TextPainter(
        text: TextSpan(text: _emoji, style: TextStyle(fontSize: _size)),
        textDirection: TextDirection.ltr,
      )..layout();
      final Offset emojiOffset =
          _position - Offset(textPainter.width / 2, textPainter.height / 2);
      textPainter.paint(canvas, emojiOffset);
    }
  }

  @override
  bool shouldRepaint(covariant _EmojiPainter oldDelegate) {
    return oldDelegate._emoji != _emoji ||
        oldDelegate._position != _position ||
        oldDelegate._size != _size;
  }
}
