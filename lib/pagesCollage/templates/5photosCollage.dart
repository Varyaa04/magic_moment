import 'package:flutter/material.dart';
import 'base_collage.dart';

class FivePhotosCollage extends BaseCollage {
  final Widget? placeholder;

  const FivePhotosCollage({
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
    if (images.length < 5) {
      return const Center(
        child: Text(
          'Need at least 5 photos',
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
    final fifthWidth = (width - 4 * borderWidth) / 5;
    final fifthHeight = (height - 4 * borderWidth) / 5;

    List<Rect> getBounds(int layoutIndex) {
      switch (layoutIndex) {
        case 0: // Вертикальное разделение
          return [
            Rect.fromLTWH(0, 0, fifthWidth, height),
            Rect.fromLTWH(fifthWidth + borderWidth, 0, fifthWidth, height),
            Rect.fromLTWH(
                2 * fifthWidth + 2 * borderWidth, 0, fifthWidth, height),
            Rect.fromLTWH(
                3 * fifthWidth + 3 * borderWidth, 0, fifthWidth, height),
            Rect.fromLTWH(
                4 * fifthWidth + 4 * borderWidth, 0, fifthWidth, height),
          ];
        case 1: // Горизонтальное разделение
          return [
            Rect.fromLTWH(0, 0, width, fifthHeight),
            Rect.fromLTWH(0, fifthHeight + borderWidth, width, fifthHeight),
            Rect.fromLTWH(
                0, 2 * fifthHeight + 2 * borderWidth, width, fifthHeight),
            Rect.fromLTWH(
                0, 3 * fifthHeight + 3 * borderWidth, width, fifthHeight),
            Rect.fromLTWH(
                0, 4 * fifthHeight + 4 * borderWidth, width, fifthHeight),
          ];
        case 2: // Сетка 3x2 с одним большим
          return [
            Rect.fromLTWH(0, 0, 2 * thirdWidth + borderWidth, height),
            Rect.fromLTWH(
                2 * thirdWidth + 2 * borderWidth, 0, thirdWidth, thirdHeight),
            Rect.fromLTWH(2 * thirdWidth + 2 * borderWidth,
                thirdHeight + borderWidth, thirdWidth, thirdHeight),
            Rect.fromLTWH(2 * thirdWidth + 2 * borderWidth,
                2 * thirdHeight + 2 * borderWidth, thirdWidth, thirdHeight),
            Rect.fromLTWH(0, 2 * thirdHeight + 2 * borderWidth,
                2 * thirdWidth + borderWidth, thirdHeight),
          ];
        case 3: // Сетка 2x3 с одним большим
          return [
            Rect.fromLTWH(0, 0, width, 2 * thirdHeight + borderWidth),
            Rect.fromLTWH(
                0, 2 * thirdHeight + 2 * borderWidth, thirdWidth, thirdHeight),
            Rect.fromLTWH(thirdWidth + borderWidth,
                2 * thirdHeight + 2 * borderWidth, thirdWidth, thirdHeight),
            Rect.fromLTWH(2 * thirdWidth + 2 * borderWidth,
                2 * thirdHeight + 2 * borderWidth, thirdWidth, thirdHeight),
            Rect.fromLTWH(2 * thirdWidth + 2 * borderWidth, 0, thirdWidth,
                2 * thirdHeight + borderWidth),
          ];
        case 4: // Большой центр, четыре угла
          return [
            Rect.fromLTWH(width / 4, height / 4, width / 2, height / 2),
            Rect.fromLTWH(borderWidth, borderWidth, thirdWidth, thirdHeight),
            Rect.fromLTWH(width - thirdWidth - borderWidth, borderWidth,
                thirdWidth, thirdHeight),
            Rect.fromLTWH(borderWidth, height - thirdHeight - borderWidth,
                thirdWidth, thirdHeight),
            Rect.fromLTWH(width - thirdWidth - borderWidth,
                height - thirdHeight - borderWidth, thirdWidth, thirdHeight),
          ];
        case 5: // Большой слева, четыре маленьких справа
          return [
            Rect.fromLTWH(0, 0, halfWidth, height),
            Rect.fromLTWH(halfWidth + borderWidth, 0, halfWidth, halfHeight),
            Rect.fromLTWH(halfWidth + borderWidth, halfHeight + borderWidth,
                halfWidth, halfHeight),
            Rect.fromLTWH(
                halfWidth + borderWidth, 0, halfWidth / 2, halfHeight / 2),
            Rect.fromLTWH(halfWidth + borderWidth + halfWidth / 2,
                halfHeight / 2 + borderWidth, halfWidth / 2, halfHeight / 2),
          ];
        case 6: // Большой верх, четыре маленьких низа
          return [
            Rect.fromLTWH(0, 0, width, halfHeight),
            Rect.fromLTWH(
                0, halfHeight + borderWidth, halfWidth, halfHeight / 2),
            Rect.fromLTWH(halfWidth + borderWidth, halfHeight + borderWidth,
                halfWidth, halfHeight / 2),
            Rect.fromLTWH(0, halfHeight + halfHeight / 2 + 2 * borderWidth,
                halfWidth, halfHeight / 2),
            Rect.fromLTWH(
                halfWidth + borderWidth,
                halfHeight + halfHeight / 2 + 2 * borderWidth,
                halfWidth,
                halfHeight / 2),
          ];
        case 7: // Маленькие наложения
          return [
            Rect.fromLTWH(0, 0, width, height),
            Rect.fromLTWH(width / 4, height / 4, width / 4, height / 4),
            Rect.fromLTWH(width / 2, height / 4, width / 4, height / 4),
            Rect.fromLTWH(width / 4, height / 2, width / 4, height / 4),
            Rect.fromLTWH(width / 2, height / 2, width / 4, height / 4),
          ];
        case 8: // Угловые наложения с центром
          return [
            Rect.fromLTWH(width / 4, height / 4, width / 2, height / 2),
            Rect.fromLTWH(borderWidth, borderWidth, thirdWidth, thirdHeight),
            Rect.fromLTWH(width - thirdWidth - borderWidth, borderWidth,
                thirdWidth, thirdHeight),
            Rect.fromLTWH(borderWidth, height - thirdHeight - borderWidth,
                thirdWidth, thirdHeight),
            Rect.fromLTWH(width - thirdWidth - borderWidth,
                height - thirdHeight - borderWidth, thirdWidth, thirdHeight),
          ];
        case 9: // Диагональное разделение
          return [
            Rect.fromLTWH(0, 0, halfWidth, halfHeight),
            Rect.fromLTWH(halfWidth + borderWidth, 0, halfWidth, halfHeight),
            Rect.fromLTWH(0, halfHeight + borderWidth, halfWidth, halfHeight),
            Rect.fromLTWH(halfWidth + borderWidth, halfHeight + borderWidth,
                halfWidth, halfHeight),
            Rect.fromLTWH(width / 4, height / 4, width / 2, height / 2),
          ];
        default:
          return [
            Rect.fromLTWH(0, 0, fifthWidth, height),
            Rect.fromLTWH(fifthWidth + borderWidth, 0, fifthWidth, height),
            Rect.fromLTWH(
                2 * fifthWidth + 2 * borderWidth, 0, fifthWidth, height),
            Rect.fromLTWH(
                3 * fifthWidth + 3 * borderWidth, 0, fifthWidth, height),
            Rect.fromLTWH(
                4 * fifthWidth + 4 * borderWidth, 0, fifthWidth, height),
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
        for (int i = 0; i < 5; i++)
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
