import 'package:flutter/material.dart';
import 'resizable_photo_widget.dart';

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
  }) : super(key: key);

  Widget buildImage(int index, Size size) {
    return Container(
      decoration: selectedImageDecoration?.call(index),
      child: ResizablePhotoWidget(
        imageProvider: images[index],
        initialScale: scales[index],
        initialPosition: positions[index] * 100,
        initialRotation: rotations[index],
        onPositionChanged: (offset) => onPositionChanged(index, offset),
        onScaleChanged: (scale) => onScaleChanged(index, scale),
        onRotationChanged: (rotation) => onRotationChanged(index, rotation),
        onTap: () => onImageTapped?.call(index),
      ),
    );
  }

  Widget buildLayout(Size size);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        return SizedBox(
          width: size.width,
          height: size.height,
          child: buildLayout(size),
        );
      },
    );
  }
}