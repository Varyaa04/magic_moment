import 'package:flutter/material.dart';
import '../photosCollage.dart';

abstract class BaseCollage extends StatelessWidget {
  final List<ImageProvider> images;
  final int templateIndex;
  final Color borderColor;
  final List<Offset> positions;
  final List<double> scales;
  final List<double> rotations;
  final Function(int, Offset) onPositionChanged;
  final Function(int, double) onScaleChanged;
  final Function(int, double) onRotationChanged;
  final Function(int)? onImageTapped;
  final int? selectedImageIndex;
  final BoxDecoration? Function(int)? selectedImageDecoration;
  final double borderWidth;

  const BaseCollage({
    Key? key,
    required this.images,
    required this.templateIndex,
    required this.borderColor,
    required this.positions,
    required this.scales,
    required this.rotations,
    required this.onPositionChanged,
    required this.onScaleChanged,
    required this.onRotationChanged,
    this.onImageTapped,
    this.selectedImageIndex,
    this.selectedImageDecoration,
    required this.borderWidth,
  }) : super(key: key);

  Widget buildImage(int index, Rect bounds) {
    if (bounds.width <= 0 || bounds.height <= 0) {
      debugPrint('Invalid bounds for image $index: $bounds');
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(borderWidth / 2),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: ClipRect(
        child: EditablePhotoWidget(
          imageProvider: images[index],
          initialScale: scales[index],
          initialPosition: positions[index],
          initialRotation: rotations[index],
          bounds: Rect.fromLTWH(
            0,
            0,
            bounds.width - borderWidth,
            bounds.height - borderWidth,
          ),
          onPositionChanged: (offset) => onPositionChanged(index, offset),
          onScaleChanged: (scale) => onScaleChanged(index, scale),
          onRotationChanged: (rotation) => onRotationChanged(index, rotation),
          onTap: () => onImageTapped?.call(index),
          decoration: selectedImageDecoration?.call(index),
          borderWidth: borderWidth,
        ),
      ),
    );
  }

  Widget buildLayout(Size size);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (size.width <= 0 || size.height <= 0) {
          return const Center(
            child: Text(
              'Invalid size',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          );
        }
        return SizedBox(
          width: size.width,
          height: size.height,
          child: ClipRect(
            child: buildLayout(size),
          ),
        );
      },
    );
  }
}