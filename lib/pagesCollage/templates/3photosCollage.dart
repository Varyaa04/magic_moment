import 'package:flutter/material.dart';
import 'base_collage.dart';

class ThreePhotosCollage extends BaseCollage {
  final Widget? placeholder;

  const ThreePhotosCollage({
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
    if (images.length < 3) {
      return const Center(
        child: Text(
          'Need at least 3 photos',
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

    List<Rect> getBounds(int layoutIndex) {
      switch (layoutIndex) {
        case 0: // Вертикальное разделение
          return [
            Rect.fromLTWH(0, 0, thirdWidth, height),
            Rect.fromLTWH(thirdWidth + borderWidth, 0, thirdWidth, height),
            Rect.fromLTWH(
                2 * thirdWidth + 2 * borderWidth, 0, thirdWidth, height),
          ];
        case 1: // Горизонтальное разделение
          return [
            Rect.fromLTWH(0, 0, width, thirdHeight),
            Rect.fromLTWH(0, thirdHeight + borderWidth, width, thirdHeight),
            Rect.fromLTWH(
                0, 2 * thirdHeight + 2 * borderWidth, width, thirdHeight),
          ];
        case 2: // 2:1 по вертикали
          return [
            Rect.fromLTWH(0, 0, 2 * thirdWidth + borderWidth, height),
            Rect.fromLTWH(
                2 * thirdWidth + 2 * borderWidth, 0, thirdWidth, halfHeight),
            Rect.fromLTWH(2 * thirdWidth + 2 * borderWidth,
                halfHeight + borderWidth, thirdWidth, halfHeight),
          ];
        case 3: // 1:1 по горизонтали
          return [
            Rect.fromLTWH(0, 0, width, 2 * thirdHeight + borderWidth),
            Rect.fromLTWH(
                0, 2 * thirdHeight + 2 * borderWidth, halfWidth, thirdHeight),
            Rect.fromLTWH(halfWidth + borderWidth,
                2 * thirdHeight + 2 * borderWidth, halfWidth, thirdHeight),
          ];
        case 4: // Сетка
          return [
            Rect.fromLTWH(0, 0, halfWidth, halfHeight),
            Rect.fromLTWH(halfWidth + borderWidth, 0, halfWidth, halfHeight),
            Rect.fromLTWH(0, halfHeight + borderWidth, width, halfHeight),
          ];
        case 5: // Большой верхний, два маленьких нижних
          return [
            Rect.fromLTWH(0, 0, width, 2 * thirdHeight + borderWidth),
            Rect.fromLTWH(
                0, 2 * thirdHeight + 2 * borderWidth, halfWidth, thirdHeight),
            Rect.fromLTWH(halfWidth + borderWidth,
                2 * thirdHeight + 2 * borderWidth, halfWidth, thirdHeight),
          ];
        case 6: // Большой слева, два маленьких справа
          return [
            Rect.fromLTWH(0, 0, 2 * thirdWidth + borderWidth, height),
            Rect.fromLTWH(
                2 * thirdWidth + 2 * borderWidth, 0, thirdWidth, halfHeight),
            Rect.fromLTWH(2 * thirdWidth + 2 * borderWidth,
                halfHeight + borderWidth, thirdWidth, halfHeight),
          ];
        case 7: // Маленькое наложение
          return [
            Rect.fromLTWH(0, 0, width, height),
            Rect.fromLTWH(width / 4, height / 4, width / 2, halfHeight),
            Rect.fromLTWH(width / 4, height / 4 + halfHeight + borderWidth,
                width / 2, halfHeight / 2),
          ];
        case 8: // Угловое наложение
          return [
            Rect.fromLTWH(0, 0, width, height),
            Rect.fromLTWH(borderWidth, borderWidth, thirdWidth, thirdHeight),
            Rect.fromLTWH(width - thirdWidth - borderWidth,
                height - thirdHeight - borderWidth, thirdWidth, thirdHeight),
          ];
        case 9: // Диагональное разделение
          return [
            Rect.fromLTWH(0, 0, halfWidth, halfHeight),
            Rect.fromLTWH(halfWidth + borderWidth, halfHeight + borderWidth,
                halfWidth, halfHeight),
            Rect.fromLTWH(0, halfHeight + borderWidth, halfWidth, halfHeight),
          ];
        default:
          return [
            Rect.fromLTWH(0, 0, thirdWidth, height),
            Rect.fromLTWH(thirdWidth + borderWidth, 0, thirdWidth, height),
            Rect.fromLTWH(
                2 * thirdWidth + 2 * borderWidth, 0, thirdWidth, height),
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
        for (int i = 0; i < 3; i++)
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
