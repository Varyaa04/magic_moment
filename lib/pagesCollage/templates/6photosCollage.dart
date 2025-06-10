import 'package:flutter/material.dart';
import 'base_collage.dart';

class SixPhotosCollage extends BaseCollage {
  final Widget? placeholder;

  const SixPhotosCollage({
    Key? key,
    required super.images,
    required int layoutIndex,
    required super.borderColor,
    required super.positions,
    required super.scales,
    required super.rotations,
    required super.onPositionChanged,
    required super.onScaleChanged,
    required super.onRotationChanged,
    super.onImageTapped,
    super.selectedImageIndex,
    super.selectedImageDecoration,
    required super.borderWidth,
    this.placeholder,
  }) : super(key: key, templateIndex: layoutIndex);

  @override
  Widget buildLayout(Size size) {
    if (images.length < 6) {
      return const Center(
        child: Text(
          'Need at least 6 photos',
          style: TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }

    final width = size.width;
    final height = size.height;
    final halfWidth = (width - borderWidth) / 2;
    final halfHeight = (height - borderWidth) / 2;
    final thirdWidth = (width - 2 * borderWidth) / 3;
    final thirdHeight = (height - 2 * borderWidth) / 3;
    final sixthWidth = (width - 5 * borderWidth) / 6;
    final sixthHeight = (height - 5 * borderWidth) / 6;

    List<Rect> getBounds(int layoutIndex) {
      switch (layoutIndex) {
        case 0: // Сетка 3x2
          return [
            Rect.fromLTWH(0, 0, thirdWidth, halfHeight),
            Rect.fromLTWH(thirdWidth + borderWidth, 0, thirdWidth, halfHeight),
            Rect.fromLTWH(
                2 * thirdWidth + 2 * borderWidth, 0, thirdWidth, halfHeight),
            Rect.fromLTWH(0, halfHeight + borderWidth, thirdWidth, halfHeight),
            Rect.fromLTWH(thirdWidth + borderWidth, halfHeight + borderWidth,
                thirdWidth, halfHeight),
            Rect.fromLTWH(2 * thirdWidth + 2 * borderWidth,
                halfHeight + borderWidth, thirdWidth, halfHeight),
          ];
        case 1: // Вертикальное разделение
          return [
            Rect.fromLTWH(0, 0, sixthWidth, height),
            Rect.fromLTWH(sixthWidth + borderWidth, 0, sixthWidth, height),
            Rect.fromLTWH(
                2 * sixthWidth + 2 * borderWidth, 0, sixthWidth, height),
            Rect.fromLTWH(
                3 * sixthWidth + 3 * borderWidth, 0, sixthWidth, height),
            Rect.fromLTWH(
                4 * sixthWidth + 4 * borderWidth, 0, sixthWidth, height),
            Rect.fromLTWH(
                5 * sixthWidth + 5 * borderWidth, 0, sixthWidth, height),
          ];
        case 2: // Горизонтальное разделение
          return [
            Rect.fromLTWH(0, 0, width, sixthHeight),
            Rect.fromLTWH(0, sixthHeight + borderWidth, width, sixthHeight),
            Rect.fromLTWH(
                0, 2 * sixthHeight + 2 * borderWidth, width, sixthHeight),
            Rect.fromLTWH(
                0, 3 * sixthHeight + 3 * borderWidth, width, sixthHeight),
            Rect.fromLTWH(
                0, 4 * sixthHeight + 4 * borderWidth, width, sixthHeight),
            Rect.fromLTWH(
                0, 5 * sixthHeight + 5 * borderWidth, width, sixthHeight),
          ];
        case 3: // Большой центр, пять маленьких
          return [
            Rect.fromLTWH(width / 4, height / 4, width / 2, height / 2),
            Rect.fromLTWH(borderWidth, borderWidth, thirdWidth, thirdHeight),
            Rect.fromLTWH(width - thirdWidth - borderWidth, borderWidth,
                thirdWidth, thirdHeight),
            Rect.fromLTWH(borderWidth, height - thirdHeight - borderWidth,
                thirdWidth, thirdHeight),
            Rect.fromLTWH(width - thirdWidth - borderWidth,
                height - thirdHeight - borderWidth, thirdWidth, thirdHeight),
            Rect.fromLTWH(width / 2 - thirdWidth / 2,
                height / 2 - thirdHeight / 2, thirdWidth, thirdHeight),
          ];
        case 4: // Сетка 2x3
          return [
            Rect.fromLTWH(0, 0, halfWidth, thirdHeight),
            Rect.fromLTWH(halfWidth + borderWidth, 0, halfWidth, thirdHeight),
            Rect.fromLTWH(0, thirdHeight + borderWidth, halfWidth, thirdHeight),
            Rect.fromLTWH(halfWidth + borderWidth, thirdHeight + borderWidth,
                halfWidth, thirdHeight),
            Rect.fromLTWH(
                0, 2 * thirdHeight + 2 * borderWidth, halfWidth, thirdHeight),
            Rect.fromLTWH(halfWidth + borderWidth,
                2 * thirdHeight + 2 * borderWidth, halfWidth, thirdHeight),
          ];
        case 5: // Большой слева, пять маленьких справа
          return [
            Rect.fromLTWH(0, 0, halfWidth, height),
            Rect.fromLTWH(
                halfWidth + borderWidth, 0, halfWidth / 2, thirdHeight),
            Rect.fromLTWH(halfWidth + borderWidth + halfWidth / 2, 0,
                halfWidth / 2, thirdHeight),
            Rect.fromLTWH(halfWidth + borderWidth, thirdHeight + borderWidth,
                halfWidth / 2, thirdHeight),
            Rect.fromLTWH(halfWidth + borderWidth + halfWidth / 2,
                thirdHeight + borderWidth, halfWidth / 2, thirdHeight),
            Rect.fromLTWH(halfWidth + borderWidth,
                2 * thirdHeight + 2 * borderWidth, halfWidth, thirdHeight),
          ];
        case 6: // Большой верх, пять маленьких нижние
          return [
            Rect.fromLTWH(0, 0, width, halfHeight),
            Rect.fromLTWH(0, halfHeight + borderWidth, thirdWidth, thirdHeight),
            Rect.fromLTWH(thirdWidth + borderWidth, halfHeight + borderWidth,
                thirdWidth, thirdHeight),
            Rect.fromLTWH(2 * thirdWidth + 2 * borderWidth,
                halfHeight + borderWidth, thirdWidth, thirdHeight),
            Rect.fromLTWH(0, halfHeight + thirdHeight + 2 * borderWidth,
                halfWidth, thirdHeight),
            Rect.fromLTWH(
                halfWidth + borderWidth,
                halfHeight + thirdHeight + 2 * borderWidth,
                halfWidth,
                thirdHeight),
          ];
        case 7: // Маленькие накладки
          return [
            Rect.fromLTWH(0, 0, width, height),
            Rect.fromLTWH(width / 4, height / 4, width / 4, height / 4),
            Rect.fromLTWH(width / 2, height / 4, width / 4, height / 4),
            Rect.fromLTWH(width / 4, height / 2, width / 4, height / 4),
            Rect.fromLTWH(width / 2, height / 2, width / 4, height / 4),
            Rect.fromLTWH(3 * width / 4, 3 * height / 4, width / 4, height / 4),
          ];
        case 8: // Угловые и центральные наложения
          return [
            Rect.fromLTWH(0, 0, width, height),
            Rect.fromLTWH(borderWidth, borderWidth, thirdWidth, thirdHeight),
            Rect.fromLTWH(width - thirdWidth - borderWidth, borderWidth,
                thirdWidth, thirdHeight),
            Rect.fromLTWH(borderWidth, height - thirdHeight - borderWidth,
                thirdWidth, thirdHeight),
            Rect.fromLTWH(width - thirdWidth - borderWidth,
                height - thirdHeight - borderWidth, thirdWidth, thirdHeight),
            Rect.fromLTWH(width / 2 - thirdWidth / 2,
                height / 2 - thirdHeight / 2, thirdWidth, thirdHeight),
          ];
        case 9: // Диагональная сетка
          return [
            Rect.fromLTWH(0, 0, thirdWidth, thirdHeight),
            Rect.fromLTWH(thirdWidth + borderWidth, 0, thirdWidth, thirdHeight),
            Rect.fromLTWH(
                2 * thirdWidth + 2 * borderWidth, 0, thirdWidth, thirdHeight),
            Rect.fromLTWH(
                0, thirdHeight + borderWidth, thirdWidth, thirdHeight),
            Rect.fromLTWH(thirdWidth + borderWidth, thirdHeight + borderWidth,
                thirdWidth, thirdHeight),
            Rect.fromLTWH(2 * thirdWidth + 2 * borderWidth,
                thirdHeight + borderWidth, thirdWidth, thirdHeight),
          ];
        default:
          return [
            Rect.fromLTWH(0, 0, thirdWidth, halfHeight),
            Rect.fromLTWH(thirdWidth + borderWidth, 0, thirdWidth, halfHeight),
            Rect.fromLTWH(
                2 * thirdWidth + 2 * borderWidth, 0, thirdWidth, halfHeight),
            Rect.fromLTWH(0, halfHeight + borderWidth, thirdWidth, halfHeight),
            Rect.fromLTWH(thirdWidth + borderWidth, halfHeight + borderWidth,
                thirdWidth, halfHeight),
            Rect.fromLTWH(2 * thirdWidth + 2 * borderWidth,
                halfHeight + borderWidth, thirdWidth, halfHeight),
          ];
      }
    }

    final bounds = getBounds(templateIndex);

    for (var i = 0; i < bounds.length; i++) {
      if (bounds[i].width <= 0 || bounds[i].height <= 0) {
        debugPrint(
            'Invalid bounds at index $i for template $templateIndex: ${bounds[i]}');
        return const Center(
          child: Text(
            'Invalid template bounds',
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        );
      }
    }

    final defaultPlaceholder = Container(
      color: Colors.grey[600],
      child: const Center(
        child: Icon(Icons.image, color: Colors.white, size: 24),
      ),
    );

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        for (int i = 0; i < 6; i++)
          Positioned.fromRect(
            rect: bounds[i],
            child: images[i] is MemoryImage &&
                    (images[i] as MemoryImage).bytes.isEmpty
                ? Container(
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: borderColor, width: borderWidth),
                    ),
                    child: placeholder ?? defaultPlaceholder,
                  )
                : buildImage(i, bounds[i]),
          ),
      ],
    );
  }
}
