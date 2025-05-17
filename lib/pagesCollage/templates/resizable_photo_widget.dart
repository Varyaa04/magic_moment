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
  }) : assert(imagePath != null || imageProvider != null, 'Either imagePath or imageProvider must be provided'),
        super(key: key);

  @override
  State<ResizablePhotoWidget> createState() => _ResizablePhotoWidgetState();
}

class _ResizablePhotoWidgetState extends State<ResizablePhotoWidget> {
  late double _scale;
  late Offset _position;
  late double _rotation;
  Offset _startingFocalPoint = Offset.zero;
  Offset _previousOffset = Offset.zero;
  double _previousScale = 1.0;
  double _previousRotation = 0.0;

  @override
  void initState() {
    super.initState();
    _scale = widget.initialScale;
    _position = widget.initialPosition;
    _rotation = widget.initialRotation;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: GestureDetector(
        onTap: widget.onTap,
        onScaleStart: (details) {
          _startingFocalPoint = details.focalPoint;
          _previousOffset = _position;
          _previousScale = _scale;
          _previousRotation = _rotation;
        },
        onScaleUpdate: (details) {
          final newScale = (_previousScale * details.scale).clamp(0.5, 2.0);
          final newRotation = _previousRotation + details.rotation;

          final delta = details.focalPoint - _startingFocalPoint;
          var newPosition = _previousOffset + delta;

          // Apply constraints based on scale and widget size
          final maxDx = ((context.size?.width ?? 0) * (newScale - 1) / 2) / newScale;
          final maxDy = ((context.size?.height ?? 0) * (newScale - 1) / 2) / newScale;

          newPosition = Offset(
            newPosition.dx.clamp(-maxDx, maxDx),
            newPosition.dy.clamp(-maxDy, maxDy),
          );

          setState(() {
            _scale = newScale;
            _rotation = newRotation;
            _position = newPosition;
          });

          widget.onScaleChanged(_scale);
          widget.onRotationChanged(_rotation);
          widget.onPositionChanged(_position / 100);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..translate(_position.dx, _position.dy)
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