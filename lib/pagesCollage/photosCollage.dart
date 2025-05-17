import 'dart:math' as math;
import 'package:flutter/material.dart';

class EditablePhotoWidget extends StatefulWidget {
  final ImageProvider imageProvider;
  final double initialScale;
  final Offset initialPosition;
  final double initialRotation;
  final Rect bounds;
  final Function(Offset) onPositionChanged;
  final Function(double) onScaleChanged;
  final Function(double) onRotationChanged;
  final VoidCallback? onTap;
  final BoxDecoration? decoration;

  const EditablePhotoWidget({
    Key? key,
    required this.imageProvider,
    required this.initialScale,
    required this.initialPosition,
    required this.initialRotation,
    required this.bounds,
    required this.onPositionChanged,
    required this.onScaleChanged,
    required this.onRotationChanged,
    this.onTap,
    this.decoration,
  }) : super(key: key);

  @override
  _EditablePhotoWidgetState createState() => _EditablePhotoWidgetState();
}

class _EditablePhotoWidgetState extends State<EditablePhotoWidget> {
  late double _scale;
  late Offset _position;
  late double _rotation;
  double _previousScale = 1.0;
  Offset _startFocalPoint = Offset.zero;

  @override
  void initState() {
    super.initState();
    _scale = widget.initialScale;
    _position = widget.initialPosition;
    _rotation = widget.initialRotation;
  }

  @override
  void didUpdateWidget(EditablePhotoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialScale != widget.initialScale) _scale = widget.initialScale;
    if (oldWidget.initialPosition != widget.initialPosition) _position = widget.initialPosition;
    if (oldWidget.initialRotation != widget.initialRotation) _rotation = widget.initialRotation;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onScaleStart: (details) {
        _previousScale = _scale;
        _startFocalPoint = details.focalPoint;
      },
      onScaleUpdate: (details) {
        setState(() {
          // Update scale
          _scale = (_previousScale * details.scale).clamp(0.5, 2.0);
          widget.onScaleChanged(_scale);

          // Update position with boundary constraints
          final delta = details.focalPoint - _startFocalPoint;
          final newPosition = _position + Offset(
            delta.dx / widget.bounds.width,
            delta.dy / widget.bounds.height,
          );

          // Calculate maximum offsets to keep image within bounds
          final imageWidth = widget.bounds.width * _scale;
          final imageHeight = widget.bounds.height * _scale;
          final maxOffsetX = (imageWidth - widget.bounds.width) / (2 * imageWidth);
          final maxOffsetY = (imageHeight - widget.bounds.height) / (2 * imageHeight);

          _position = Offset(
            newPosition.dx.clamp(-maxOffsetX, maxOffsetX),
            newPosition.dy.clamp(-maxOffsetY, maxOffsetY),
          );
          widget.onPositionChanged(_position);

          // Update rotation
          if (details.rotation != 0) {
            _rotation = widget.initialRotation + details.rotation;
            widget.onRotationChanged(_rotation);
          }
        });
      },
      child: ClipRect(
        clipper: _CellClipper(widget.bounds),
        child: Container(
          width: widget.bounds.width,
          height: widget.bounds.height,
          decoration: widget.decoration,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()
              ..translate(
                _position.dx * widget.bounds.width,
                _position.dy * widget.bounds.height,
              )
              ..rotateZ(_rotation)
              ..scale(_scale),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image(
                image: widget.imageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CellClipper extends CustomClipper<Rect> {
  final Rect bounds;

  _CellClipper(this.bounds);

  @override
  Rect getClip(Size size) => bounds;

  @override
  bool shouldReclip(_CellClipper oldClipper) => oldClipper.bounds != bounds;
}

class PhotosCollage extends StatefulWidget {
  final List<ImageProvider> images;
  final int templateIndex;
  final int imageCount;
  final ValueNotifier<Color> borderColor;
  final List<Offset> positions;
  final List<double> scales;
  final List<double> rotations;
  final Function(int, Offset) onPositionChanged;
  final Function(int, double) onScaleChanged;
  final Function(int, double) onRotationChanged;
  final Function(int)? onImageTapped;
  final ValueNotifier<int?> selectedImageIndex;
  final BoxDecoration? Function(int) selectedImageDecoration;

  const PhotosCollage({
    Key? key,
    required this.images,
    required this.templateIndex,
    required this.imageCount,
    required this.borderColor,
    required this.positions,
    required this.scales,
    required this.rotations,
    required this.onPositionChanged,
    required this.onScaleChanged,
    required this.onRotationChanged,
    this.onImageTapped,
    required this.selectedImageIndex,
    required this.selectedImageDecoration,
  }) : super(key: key);

  @override
  _PhotosCollageState createState() => _PhotosCollageState();
}

class _PhotosCollageState extends State<PhotosCollage> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (widget.images.isEmpty || widget.imageCount < 1) {
          return const Center(
            child: Text(
              'No photos available',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }
        if (widget.imageCount != widget.images.length ||
            widget.imageCount != widget.positions.length ||
            widget.imageCount != widget.scales.length ||
            widget.imageCount != widget.rotations.length) {
          debugPrint(
              'Invalid collage state: images=${widget.images.length}, '
                  'imageCount=${widget.imageCount}, '
                  'positions=${widget.positions.length}, '
                  'scales=${widget.scales.length}, '
                  'rotations=${widget.rotations.length}');
          return const Center(
            child: Text(
              'Error: Invalid collage configuration',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          );
        }

        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final Map<int, Rect> cellBounds = {};

        List<Widget> buildChildren(int templateIndex) {
          if (widget.imageCount < 2) {
            return [
              const Center(
                child: Text(
                  'Add at least 2 photos',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ];
          }

          Widget buildImage(int index) {
            return AnimatedOpacity(
              opacity: widget.selectedImageIndex.value == index ? 1.0 : 0.9,
              duration: const Duration(milliseconds: 200),
              child: EditablePhotoWidget(
                imageProvider: widget.images[index],
                initialScale: widget.scales[index],
                initialPosition: widget.positions[index],
                initialRotation: widget.rotations[index],
                bounds: cellBounds[index] ?? Rect.fromLTWH(0, 0, size, size),
                onPositionChanged: (offset) => widget.onPositionChanged(index, offset),
                onScaleChanged: (scale) => widget.onScaleChanged(index, scale),
                onRotationChanged: (rotation) => widget.onRotationChanged(index, rotation),
                onTap: () => widget.onImageTapped?.call(index),
                decoration: widget.selectedImageDecoration(index),
              ),
            );
          }

          final validTemplateIndex = templateIndex.clamp(0, 9);
          // Template definitions remain the same as in the original file
          // (omitted for brevity, but keep the switch-case block from the original)
          switch (validTemplateIndex) {
            case 0:
              final crossAxisCount = math.max(2, math.sqrt(widget.imageCount).ceil());
              return List.generate(widget.imageCount, (i) {
                final row = i ~/ crossAxisCount;
                final col = i % crossAxisCount;
                final cellWidth = size / crossAxisCount;
                final cellHeight = size / crossAxisCount;
                cellBounds[i] = Rect.fromLTWH(col * cellWidth, row * cellHeight, cellWidth, cellHeight);
                return Positioned(
                  left: col * cellWidth,
                  top: row * cellHeight,
                  width: cellWidth,
                  height: cellHeight,
                  child: buildImage(i),
                );
              });
          // Add cases 1-9 as in the original file
            default:
              return [
                const Center(
                  child: Text(
                    'Invalid template index',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ];
          }
        }

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: buildChildren(widget.templateIndex),
          ),
        );
      },
    );
  }
}