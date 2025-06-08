import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'templates/2photosCollage.dart';
import 'templates/3photosCollage.dart';
import 'templates/4photosCollage.dart';
import 'templates/5photosCollage.dart';
import 'templates/6photosCollage.dart';

class TemplatePreview extends StatelessWidget {
  final int imageCount;
  final int templateIndex;
  final Color borderColor;

  const TemplatePreview({
    Key? key,
    required this.imageCount,
    required this.templateIndex,
    required this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
// Placeholder image provider for preview
    final placeholderImage =
        MemoryImage(Uint8List(0)); // Empty image for preview
    final images = List.generate(imageCount, (_) => placeholderImage);
    final positions = List.generate(imageCount, (_) => Offset.zero);
    final scales = List.generate(imageCount, (_) => 1.0);
    final rotations = List.generate(imageCount, (_) => 0.0);

// Placeholder callback functions
    void onPositionChanged(int index, Offset offset) {}
    void onScaleChanged(int index, double scale) {}
    void onRotationChanged(int index, double rotation) {}

    Widget collage;
    switch (imageCount) {
      case 2:
        collage = TwoPhotosCollage(
          images: images,
          layoutIndex:
              templateIndex, // Changed from templateIndex to layoutIndex
          borderColor: borderColor,
          positions: positions,
          scales: scales,
          rotations: rotations,
          onPositionChanged: onPositionChanged,
          onScaleChanged: onScaleChanged,
          onRotationChanged: onRotationChanged,
          borderWidth: 2.0,
          placeholder: Container(
            color: Colors.grey[400],
            child: const Center(
                child: Icon(Icons.image, color: Colors.white, size: 16)),
          ),
        );
        break;
      case 3:
        collage = ThreePhotosCollage(
          images: images,
          layoutIndex:
              templateIndex, // Changed from templateIndex to layoutIndex
          borderColor: borderColor,
          positions: positions,
          scales: scales,
          rotations: rotations,
          onPositionChanged: onPositionChanged,
          onScaleChanged: onScaleChanged,
          onRotationChanged: onRotationChanged,
          borderWidth: 2.0,
          placeholder: Container(
            color: Colors.grey[400],
            child: const Center(
                child: Icon(Icons.image, color: Colors.white, size: 16)),
          ),
        );
        break;
      case 4:
        collage = FourPhotosCollage(
          images: images,
          layoutIndex:
              templateIndex, // Changed from templateIndex to layoutIndex
          borderColor: borderColor,
          positions: positions,
          scales: scales,
          rotations: rotations,
          onPositionChanged: onPositionChanged,
          onScaleChanged: onScaleChanged,
          onRotationChanged: onRotationChanged,
          borderWidth: 2.0,
          placeholder: Container(
            color: Colors.grey[400],
            child: const Center(
                child: Icon(Icons.image, color: Colors.white, size: 16)),
          ),
        );
        break;
      case 5:
        collage = FivePhotosCollage(
          images: images,
          layoutIndex:
              templateIndex, // Changed from templateIndex to layoutIndex
          borderColor: borderColor,
          positions: positions,
          scales: scales,
          rotations: rotations,
          onPositionChanged: onPositionChanged,
          onScaleChanged: onScaleChanged,
          onRotationChanged: onRotationChanged,
          borderWidth: 2.0,
          placeholder: Container(
            color: Colors.grey[400],
            child: const Center(
                child: Icon(Icons.image, color: Colors.white, size: 16)),
          ),
        );
        break;
      case 6:
        collage = SixPhotosCollage(
          images: images,
          layoutIndex:
              templateIndex, // Changed from templateIndex to layoutIndex
          borderColor: borderColor,
          positions: positions,
          scales: scales,
          rotations: rotations,
          onPositionChanged: onPositionChanged,
          onScaleChanged: onScaleChanged,
          onRotationChanged: onRotationChanged,
          borderWidth: 2.0,
          placeholder: Container(
            color: Colors.grey[400],
            child: const Center(
                child: Icon(Icons.image, color: Colors.white, size: 16)),
          ),
        );
        break;
      default:
        collage = const Center(
          child: Text(
            'Unsupported image count',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
        );
    }

    return Container(
      color: Colors.grey[800],
      child: ClipRect(
        child: collage,
      ),
    );
  }
}
