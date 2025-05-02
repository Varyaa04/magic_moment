import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

class CropPanel extends StatelessWidget {
  final Uint8List image;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;

  const CropPanel({
    required this.image,
    required this.onCancel,
    required this.onApply,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: onCancel,
              ),
              title: const Text('Crop Image'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () async {
                    // Реальная логика обрезки будет здесь
                    // Пока просто возвращаем оригинальное изображение
                    onApply(image);
                  },
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: Image.memory(image, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }
}