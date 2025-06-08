import 'package:flutter/material.dart';
import 'base_collage.dart';

class FourPhotosCollage extends BaseCollage {
  final Widget? placeholder;

  const FourPhotosCollage({
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
    if (images.length < 4) {
      return const Center(
        child: Text(
          'Need at least 4 photos',
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
    final quarterWidth = (width - 3 * borderWidth) / 4;
    final quarterHeight = (height - 3 * borderWidth) / 4;

    List<Rect> getBounds(int layoutIndex) {
      switch (layoutIndex) {
        case 0: // 2x2 grid
          return [
            Rect.fromLTWH(0, 0, halfWidth, halfHeight),
            Rect.fromLTWH(halfWidth + borderWidth, 0, halfWidth, halfHeight),
            Rect.fromLTWH(0, halfHeight + borderWidth, halfWidth, halfHeight),
            Rect.fromLTWH(halfWidth + borderWidth, halfHeight + borderWidth,
                halfWidth, halfHeight),
          ];
        case 1: // Vertical split
          return [
            Rect.fromLTWH(0, 0, quarterWidth, height),
            Rect.fromLTWH(quarterWidth + borderWidth, 0, quarterWidth, height),
            Rect.fromLTWH(
                2 * quarterWidth + 2 * borderWidth, 0, quarterWidth, height),
            Rect.fromLTWH(
                3 * quarterWidth + 3 * borderWidth, 0, quarterWidth, height),
          ];
        case 2: // Horizontal split
          return [
            Rect.fromLTWH(0, 0, width, quarterHeight),
            Rect.fromLTWH(0, quarterHeight + borderWidth, width, quarterHeight),
            Rect.fromLTWH(
                0, 2 * quarterHeight + 2 * borderWidth, width, quarterHeight),
            Rect.fromLTWH(
                0, 3 * quarterHeight + 3 * borderWidth, width, quarterHeight),
          ];
        case 3: // Large left, three small right
          return [
            Rect.fromLTWH(0, 0, halfWidth, height),
            Rect.fromLTWH(halfWidth + borderWidth, 0, halfWidth, thirdHeight),
            Rect.fromLTWH(halfWidth + borderWidth, thirdHeight + borderWidth,
                halfWidth, thirdHeight),
            Rect.fromLTWH(halfWidth + borderWidth,
                2 * thirdHeight + 2 * borderWidth, halfWidth, thirdHeight),
          ];
        case 4: // Large top, three small bottom
          return [
            Rect.fromLTWH(0, 0, width, halfHeight),
            Rect.fromLTWH(0, halfHeight + borderWidth, thirdWidth, halfHeight),
            Rect.fromLTWH(thirdWidth + borderWidth, halfHeight + borderWidth,
                thirdWidth, halfHeight),
            Rect.fromLTWH(2 * thirdWidth + 2 * borderWidth,
                halfHeight + borderWidth, thirdWidth, halfHeight),
          ];
        case 5: // 3:1 vertical
          return [
            Rect.fromLTWH(0, 0, 3 * quarterWidth + 2 * borderWidth, height),
            Rect.fromLTWH(3 * quarterWidth + 3 * borderWidth, 0, quarterWidth,
                thirdHeight),
            Rect.fromLTWH(3 * quarterWidth + 3 * borderWidth,
                thirdHeight + borderWidth, quarterWidth, thirdHeight),
            Rect.fromLTWH(3 * quarterWidth + 3 * borderWidth,
                2 * thirdHeight + 2 * borderWidth, quarterWidth, thirdHeight),
          ];
        case 6: // 3:1 horizontal
          return [
            Rect.fromLTWH(0, 0, width, 3 * quarterHeight + 2 * borderWidth),
            Rect.fromLTWH(0, 3 * quarterHeight + 3 * borderWidth, thirdWidth,
                quarterHeight),
            Rect.fromLTWH(thirdWidth + borderWidth,
                3 * quarterHeight + 3 * borderWidth, thirdWidth, quarterHeight),
            Rect.fromLTWH(2 * thirdWidth + 2 * borderWidth,
                3 * quarterHeight + 3 * borderWidth, thirdWidth, quarterHeight),
          ];
        case 7: // Small overlay
          return [
            Rect.fromLTWH(0, 0, width, height),
            Rect.fromLTWH(width / 4, height / 4, width / 2, thirdHeight),
            Rect.fromLTWH(width / 4, height / 4 + thirdHeight + borderWidth,
                width / 2, thirdHeight),
            Rect.fromLTWH(
                width / 4,
                height / 4 + 2 * thirdHeight + 2 * borderWidth,
                width / 2,
                thirdHeight),
          ];
        case 8: // Corner overlays
          return [
            Rect.fromLTWH(0, 0, width, height),
            Rect.fromLTWH(borderWidth, borderWidth, thirdWidth, thirdHeight),
            Rect.fromLTWH(width - thirdWidth - borderWidth, borderWidth,
                thirdWidth, thirdHeight),
            Rect.fromLTWH(borderWidth, height - thirdHeight - borderWidth,
                thirdWidth, thirdHeight),
          ];
        case 9: // Diagonal grid
          return [
            Rect.fromLTWH(0, 0, halfWidth, halfHeight),
            Rect.fromLTWH(halfWidth + borderWidth, 0, halfWidth, halfHeight),
            Rect.fromLTWH(0, halfHeight + borderWidth, halfWidth, halfHeight),
            Rect.fromLTWH(halfWidth + borderWidth, halfHeight + borderWidth,
                halfWidth, halfHeight),
          ];
        default:
          return [
            Rect.fromLTWH(0, 0, halfWidth, halfHeight),
            Rect.fromLTWH(halfWidth + borderWidth, 0, halfWidth, halfHeight),
            Rect.fromLTWH(0, halfHeight + borderWidth, halfWidth, halfHeight),
            Rect.fromLTWH(halfWidth + borderWidth, halfHeight + borderWidth,
                halfWidth, halfHeight),
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
        for (int i = 0; i < 4; i++)
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
