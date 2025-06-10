import 'package:flutter/material.dart';

class ResizablePhotoWidget extends StatefulWidget {
  final String? imagePath;
  final ImageProvider? imageProvider;
  final double initialScale;
  final Offset initialPosition;
  final double initialRotation;
  final Function(Offset) onPositionChanged;
  final Function(double) onScaleChanged;
  final Function(double) onRotationChanged;
  final VoidCallback? onTap;
  final Rect bounds;

  const ResizablePhotoWidget({
    Key? key,
    this.imagePath,
    this.imageProvider,
    required this.initialScale,
    required this.initialPosition,
    required this.initialRotation,
    required this.onPositionChanged,
    required this.onScaleChanged,
    required this.onRotationChanged,
    this.onTap,
    required this.bounds,
  }) : assert(imagePath != null || imageProvider != null, 'Either imagePath or imageProvider must be provided'),
        super(key: key);

  @override
  State<ResizablePhotoWidget> createState() => _ResizablePhotoWidgetState();
}

class _ResizablePhotoWidgetState extends State<ResizablePhotoWidget> {
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
  void didUpdateWidget(ResizablePhotoWidget oldWidget) {
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
        if (widget.bounds.width < 1.0 || widget.bounds.height < 1.0) return; // Пропустить, если границы недействительны
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
      child: ClipRect(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..translate(
              _position.dx * (context.size?.width ?? 0),
              _position.dy * (context.size?.height ?? 0),
            )
            ..rotateZ(_rotation)
            ..scale(_scale),
          child: widget.imageProvider != null
              ? Image(
            image: widget.imageProvider!,
            fit: BoxFit.cover,
          )
              : Image.asset(
            widget.imagePath!,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}