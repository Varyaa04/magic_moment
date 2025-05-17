import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'resizable_photo_widget.dart';

class TwoPhotosCollage extends StatefulWidget {
  final List<ImageProvider> images;
  final int layoutIndex;
  final Color borderColor;
  final List<Offset> positions;
  final List<double> scales;
  final List<double> rotations;
  final Function(int, Offset) onPositionChanged;
  final Function(int, double) onScaleChanged;
  final Function(int, double) onRotationChanged;
  final Function(int)? onImageTapped;
  final int? selectedImageIndex;
  final BoxDecoration? Function(int) selectedImageDecoration;

  const TwoPhotosCollage({
    Key? key,
    required this.images,
    required this.layoutIndex,
    required this.borderColor,
    required this.positions,
    required this.scales,
    required this.rotations,
    required this.onPositionChanged,
    required this.onScaleChanged,
    required this.onRotationChanged,
    this.onImageTapped,
    this.selectedImageIndex,
    required this.selectedImageDecoration,
  }) : super(key: key);

  @override
  _TwoPhotosCollageState createState() => _TwoPhotosCollageState();
}

class _TwoPhotosCollageState extends State<TwoPhotosCollage> {
  final _debouncer = Debouncer(milliseconds: 16);

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  Widget _buildImage(int index) {
    return Container(
      decoration: widget.selectedImageDecoration(index),
      child: ResizablePhotoWidget(
        imageProvider: widget.images[index],
        initialScale: widget.scales[index],
        initialPosition: widget.positions[index] * 100,
        initialRotation: widget.rotations[index],
        onPositionChanged: (offset) => widget.onPositionChanged(index, offset),
        onScaleChanged: (scale) => widget.onScaleChanged(index, scale),
        onRotationChanged: (rotation) => widget.onRotationChanged(index, rotation),
        onTap: () => widget.onImageTapped?.call(index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        return SizedBox(
          width: size,
          height: size,
          child: switch (widget.layoutIndex) {
            0 => Row(
              children: [
                Expanded(child: _buildImage(0)),
                Container(width: 4, color: widget.borderColor),
                Expanded(child: _buildImage(1)),
              ],
            ),
            1 => Column(
              children: [
                Expanded(child: _buildImage(0)),
                Container(height: 4, color: widget.borderColor),
                Expanded(child: _buildImage(1)),
              ],
            ),
            2 => Stack(
              children: [
                Positioned.fill(child: _buildImage(0)),
                Align(
                  alignment: Alignment.bottomRight,
                  child: SizedBox(
                    width: size / 3,
                    height: size / 3,
                    child: _buildImage(1),
                  ),
                ),
              ],
            ),
            3 => Column(
              children: [
                Expanded(flex: 2, child: _buildImage(0)),
                Container(height: 4, color: widget.borderColor),
                Expanded(flex: 1, child: _buildImage(1)),
              ],
            ),
            4 => Row(
              children: [
                Expanded(flex: 2, child: _buildImage(0)),
                Container(width: 4, color: widget.borderColor),
                Expanded(flex: 1, child: _buildImage(1)),
              ],
            ),
            5 => GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildImage(0),
                _buildImage(1),
              ],
            ),
            6 => Column(
              children: [
                Expanded(child: _buildImage(0)),
                Container(height: 4, color: widget.borderColor),
                Expanded(child: _buildImage(1)),
              ],
            ),
            7 => Row(
              children: [
                Expanded(child: _buildImage(0)),
                Container(width: 4, color: widget.borderColor),
                Expanded(child: _buildImage(1)),
              ],
            ),
            8 => Stack(
              children: [
                Positioned.fill(child: _buildImage(0)),
                Center(
                  child: Container(
                    width: size / 2,
                    height: size / 2,
                    decoration: BoxDecoration(
                      border: Border.all(color: widget.borderColor, width: 4),
                    ),
                    child: _buildImage(1),
                  ),
                ),
              ],
            ),
            9 => Stack(
              children: [
                Positioned.fill(child: _buildImage(0)),
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: size / 3,
                    height: size / 3,
                    decoration: BoxDecoration(
                      border: Border.all(color: widget.borderColor),
                    ),
                    child: _buildImage(1),
                  ),
                ),
              ],
            ),
            _ => const Center(child: Text('Invalid template index')),
          },
        );
      },
    );
  }
}

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}