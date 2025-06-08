import 'package:flutter/material.dart';
import 'package:MagicMoment/pagesCollage/templates/2photosCollage.dart';
import 'package:MagicMoment/pagesCollage/templates/3photosCollage.dart';
import 'package:MagicMoment/pagesCollage/templates/4photosCollage.dart';
import 'package:MagicMoment/pagesCollage/templates/5photosCollage.dart';
import 'package:MagicMoment/pagesCollage/templates/6photosCollage.dart';

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
  final double borderWidth;

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
    this.borderWidth = 2.0,
  }) : super(key: key);

  @override
  _EditablePhotoWidgetState createState() => _EditablePhotoWidgetState();
}

class _EditablePhotoWidgetState extends State<EditablePhotoWidget>
    with SingleTickerProviderStateMixin {
  late double _scale;
  late Offset _position;
  late double _rotation;
  double _previousScale = 1.0;
  Offset _startFocalPoint = Offset.zero;
  late AnimationController _animationController;
  late Animation<Offset> _flingAnimation;
  Offset _velocity = Offset.zero;

  @override
  void initState() {
    super.initState();
    _scale = widget.initialScale;
    _position = widget.initialPosition;
    _rotation = widget.initialRotation;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _flingAnimation = Tween<Offset>(begin: _position, end: _position).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    )..addListener(() {
      setState(() {
        _position = _flingAnimation.value;
        widget.onPositionChanged(_position);
      });
    });
  }

  @override
  void didUpdateWidget(EditablePhotoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scale = widget.initialScale;
    _position = widget.initialPosition;
    _rotation = widget.initialRotation;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _isOutOfBounds(Offset position, double scale) {
    final imageWidth = widget.bounds.width * scale;
    final imageHeight = widget.bounds.height * scale;
    final offsetX = position.dx * widget.bounds.width;
    final offsetY = position.dy * widget.bounds.height;

    final left = offsetX - imageWidth / 2;
    final right = offsetX + imageWidth / 2;
    final top = offsetY - imageHeight / 2;
    final bottom = offsetY + imageHeight / 2;

    return left > widget.bounds.width / 2 ||
        right < -widget.bounds.width / 2 ||
        top > widget.bounds.height / 2 ||
        bottom < -widget.bounds.height / 2;
  }

  void _startFlingAnimation(Offset velocity) {
    final imageWidth = widget.bounds.width * _scale;
    final imageHeight = widget.bounds.height * _scale;
    final maxOffsetX = (imageWidth - widget.bounds.width) / (2 * imageWidth);
    final maxOffsetY = (imageHeight - widget.bounds.height) / (2 * imageHeight);

    final endPosition = Offset(
      (_position.dx + velocity.dx / 1000).clamp(-maxOffsetX, maxOffsetX),
      (_position.dy + velocity.dy / 1000).clamp(-maxOffsetY, maxOffsetY),
    );

    _flingAnimation = Tween<Offset>(begin: _position, end: endPosition).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bounds.width <= 0 || widget.bounds.height <= 0) {
      debugPrint('Invalid bounds: ${widget.bounds}');
      return const SizedBox.shrink();
    }

    final shouldClip = _rotation != 0 || _scale > 1.5 || _isOutOfBounds(_position, _scale);

    return GestureDetector(
      onTap: widget.onTap,
      onScaleStart: (details) {
        _previousScale = _scale;
        _startFocalPoint = details.focalPoint;
        _animationController.stop();
      },
      onScaleUpdate: (details) {
        if (widget.bounds.width < 1.0 || widget.bounds.height < 1.0) return;

        setState(() {
          _scale = (_previousScale * details.scale).clamp(0.5, 2.0);
          widget.onScaleChanged(_scale);

          final delta = details.focalPoint - _startFocalPoint;
          final newPosition = _position +
              Offset(
                delta.dx / widget.bounds.width,
                delta.dy / widget.bounds.height,
              );

          final imageWidth = widget.bounds.width * _scale;
          final imageHeight = widget.bounds.height * _scale;
          final maxOffsetX = (imageWidth - widget.bounds.width) / (2 * imageWidth);
          final maxOffsetY = (imageHeight - widget.bounds.height) / (2 * imageHeight);

          _position = Offset(
            newPosition.dx.clamp(-maxOffsetX, maxOffsetX),
            newPosition.dy.clamp(-maxOffsetY, maxOffsetY),
          );
          widget.onPositionChanged(_position);

          if (details.rotation != 0) {
            _rotation = widget.initialRotation + details.rotation;
            widget.onRotationChanged(_rotation);
          }

          _startFocalPoint = details.focalPoint;
        });
      },
      onScaleEnd: (details) {
        _velocity = details.velocity.pixelsPerSecond;
        if (_velocity.distance > 200) {
          _startFlingAnimation(_velocity);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: widget.decoration?.copyWith(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRect(
          clipper: shouldClip ? _CellClipper(widget.bounds.inflate(widget.borderWidth)) : null,
          child: Transform(
            transform: Matrix4.identity()
              ..translate(
                _position.dx * widget.bounds.width,
                _position.dy * widget.bounds.height,
              )
              ..rotateZ(_rotation)
              ..scale(_scale),
            alignment: Alignment.center,
            child: Image(
              image: widget.imageProvider,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[600],
                child: const Center(child: Icon(Icons.error, color: Colors.red, size: 24)),
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

class PhotosCollage extends StatelessWidget {
  final List<ImageProvider> images;
  final int templateIndex;
  final int imageCount;
  final Color borderColor;
  final List<Offset> positions;
  final List<double> scales;
  final List<double> rotations;
  final Function(int, Offset) onPositionChanged;
  final Function(int, double) onScaleChanged;
  final Function(int, double) onRotationChanged;
  final Function(int)? onImageTapped;
  final ValueNotifier<int?> selectedImageIndex;
  final BoxDecoration? Function(int)? selectedImageDecoration;
  final double borderWidth;

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
    this.selectedImageDecoration,
    this.borderWidth = 2.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget collage;
    switch (imageCount) {
      case 2:
        collage = TwoPhotosCollage(
          images: images,
          layoutIndex: templateIndex,
          borderColor: borderColor,
          positions: positions,
          scales: scales,
          rotations: rotations,
          onPositionChanged: onPositionChanged,
          onScaleChanged: onScaleChanged,
          onRotationChanged: onRotationChanged,
          onImageTapped: onImageTapped,
          selectedImageIndex: selectedImageIndex.value,
          selectedImageDecoration: selectedImageDecoration,
          borderWidth: borderWidth,
        );
        break;
      case 3:
        collage = ThreePhotosCollage(
          images: images,
          layoutIndex: templateIndex,
          borderColor: borderColor,
          positions: positions,
          scales: scales,
          rotations: rotations,
          onPositionChanged: onPositionChanged,
          onScaleChanged: onScaleChanged,
          onRotationChanged: onRotationChanged,
          onImageTapped: onImageTapped,
          selectedImageIndex: selectedImageIndex.value,
          selectedImageDecoration: selectedImageDecoration,
          borderWidth: borderWidth,
        );
        break;
      case 4:
        collage = FourPhotosCollage(
          images: images,
          layoutIndex: templateIndex,
          borderColor: borderColor,
          positions: positions,
          scales: scales,
          rotations: rotations,
          onPositionChanged: onPositionChanged,
          onScaleChanged: onScaleChanged,
          onRotationChanged: onRotationChanged,
          onImageTapped: onImageTapped,
          selectedImageIndex: selectedImageIndex.value,
          selectedImageDecoration: selectedImageDecoration,
          borderWidth: borderWidth,
        );
        break;
      case 5:
        collage = FivePhotosCollage(
          images: images,
          layoutIndex: templateIndex,
          borderColor: borderColor,
          positions: positions,
          scales: scales,
          rotations: rotations,
          onPositionChanged: onPositionChanged,
          onScaleChanged: onScaleChanged,
          onRotationChanged: onRotationChanged,
          onImageTapped: onImageTapped,
          selectedImageIndex: selectedImageIndex.value,
          selectedImageDecoration: selectedImageDecoration,
          borderWidth: borderWidth,
        );
        break;
      case 6:
        collage = SixPhotosCollage(
          images: images,
          layoutIndex: templateIndex,
          borderColor: borderColor,
          positions: positions,
          scales: scales,
          rotations: rotations,
          onPositionChanged: onPositionChanged,
          onScaleChanged: onScaleChanged,
          onRotationChanged: onRotationChanged,
          onImageTapped: onImageTapped,
          selectedImageIndex: selectedImageIndex.value,
          selectedImageDecoration: selectedImageDecoration,
          borderWidth: borderWidth,
        );
        break;
      default:
        collage = const Center(
          child: Text(
            'Unsupported image count',
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        );
    }

    return ValueListenableBuilder<int?>(
      valueListenable: selectedImageIndex,
      builder: (context, selectedIndex, child) {
        return collage;
      },
    );
  }
}