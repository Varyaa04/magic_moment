import 'package:flutter/material.dart';
import 'base_collage.dart';

class TwoPhotosCollage extends BaseCollage {
  final Widget? placeholder;

  const TwoPhotosCollage({
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
    if (images.length < 2) {
      return const Center(
        child: Text(
          'Need at least 2 photos',
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
        case 0: // Vertical split
          return [
            Rect.fromLTWH(0, 0, halfWidth, height),
            Rect.fromLTWH(halfWidth + borderWidth, 0, halfWidth, height),
          ];
        case 1: // Horizontal split
          return [
            Rect.fromLTWH(0, 0, width, halfHeight),
            Rect.fromLTWH(0, halfHeight + borderWidth, width, halfHeight),
          ];
        case 2: // 2:1 vertical
          return [
            Rect.fromLTWH(0, 0, 2 * thirdWidth + borderWidth, height),
            Rect.fromLTWH(2 * thirdWidth + 2 * borderWidth, 0, thirdWidth, height),
          ];
        case 3: // 2:1 horizontal
          return [
            Rect.fromLTWH(0, 0, width, 2 * thirdHeight + borderWidth),
            Rect.fromLTWH(0, 2 * thirdHeight + 2 * borderWidth, width, thirdHeight),
          ];
        case 4: // Diagonal split
          return [
            Rect.fromLTWH(0, 0, halfWidth, halfHeight),
            Rect.fromLTWH(halfWidth + borderWidth, halfHeight + borderWidth, halfWidth, halfHeight),
          ];
        case 5: // Small top, large bottom
          return [
            Rect.fromLTWH(0, 0, width, thirdHeight),
            Rect.fromLTWH(0, thirdHeight + borderWidth, width, 2 * thirdHeight + borderWidth),
          ];
        case 6: // Large left, small right
          return [
            Rect.fromLTWH(0, 0, 2 * thirdWidth + borderWidth, height),
            Rect.fromLTWH(2 * thirdWidth + 2 * borderWidth, 0, thirdWidth, height),
          ];
        case 7: // Small overlay
          return [
            Rect.fromLTWH(0, 0, width, height),
            Rect.fromLTWH(width / 4, height / 4, width / 2, height / 2),
          ];
        case 8: // Corner overlay
          return [
            Rect.fromLTWH(0, 0, width, height),
            Rect.fromLTWH(borderWidth, borderWidth, width / 3, height / 3),
          ];
        case 9: // Large bottom, small top
          return [
            Rect.fromLTWH(0, thirdHeight + borderWidth, width, 2 * thirdHeight + borderWidth),
            Rect.fromLTWH(0, 0, width, thirdHeight),
          ];
        default:
          return [
            Rect.fromLTWH(0, 0, halfWidth, height),
            Rect.fromLTWH(halfWidth + borderWidth, 0, halfWidth, height),
          ];
      }
    }

    final bounds = getBounds(templateIndex);

    for (var i = 0; i < bounds.length; i++) {
      if (bounds[i].width <= 0 || bounds[i].height <= 0) {
        debugPrint('Invalid bounds at index $i for template $templateIndex: ${bounds[i]}');
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
        for (int i = 0; i < 2; i++)
          Positioned.fromRect(
            rect: bounds[i],
            child: images[i] is MemoryImage && (images[i] as MemoryImage).bytes.isEmpty
                ? Container(
              decoration: BoxDecoration(
                border: Border.all(color: borderColor, width: borderWidth),
              ),
              child: placeholder ?? defaultPlaceholder,
            )
                : buildImage(i, bounds[i]),
          ),
      ],
    );
  }
}