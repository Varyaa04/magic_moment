import 'package:flutter/material.dart';
import 'dart:async';
import 'resizable_photo_widget.dart';

class FivePhotosTemplates {
  static List<Widget> getTemplates(
      List<ImageProvider> images,
      Color borderColor,
      List<Offset> positions,
      List<double> scales,
      List<double> rotations,
      Function(int, Offset) onPositionChanged,
      Function(int, double) onScaleChanged,
      Function(int, double) onRotationChanged,
      Function(int) onImageTapped, [
        int? selectedImageIndex,
        BoxDecoration? Function(int)? selectedImageDecoration,
      ]) {
    return List.generate(
      10,
          (index) => _FivePhotosCollage(
        images: images,
        templateIndex: index,
        borderColor: borderColor,
        positions: positions,
        scales: scales,
        rotations: rotations,
        onPositionChanged: onPositionChanged,
        onScaleChanged: onScaleChanged,
        onRotationChanged: onRotationChanged,
        onImageTapped: onImageTapped,
        selectedImageIndex: selectedImageIndex,
        selectedImageDecoration: selectedImageDecoration,
      ),
    );
  }
}

class _FivePhotosCollage extends StatefulWidget {
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

  const _FivePhotosCollage({
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

  @override
  _FivePhotosCollageState createState() => _FivePhotosCollageState();
}

class _FivePhotosCollageState extends State<_FivePhotosCollage> {
  final Debouncer _debouncer = Debouncer(milliseconds: 16);

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  Widget _buildImage(int index) {
    return Container(
      decoration: widget.selectedImageDecoration?.call(index),
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
        final size = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        return SizedBox(
          width: size,
          height: size,
          child: switch (widget.templateIndex) {
            0 => GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildImage(0),
                _buildImage(1),
                _buildImage(2),
                _buildImage(3),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: widget.borderColor, width: 2),
                  ),
                  child: _buildImage(4),
                ),
              ],
            ),
            1 => Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildImage(0)),
                      Container(width: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(1)),
                    ],
                  ),
                ),
                Container(height: 4, color: widget.borderColor),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildImage(2)),
                      Container(width: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(3)),
                      Container(width: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(4)),
                    ],
                  ),
                ),
              ],
            ),
            2 => Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _buildImage(0)),
                      Container(height: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(1)),
                    ],
                  ),
                ),
                Container(width: 4, color: widget.borderColor),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _buildImage(2)),
                      Container(height: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(3)),
                      Container(height: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(4)),
                    ],
                  ),
                ),
              ],
            ),
            3 => Column(
              children: [
                Expanded(child: _buildImage(0)),
                Container(height: 4, color: widget.borderColor),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildImage(1)),
                      Container(width: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(2)),
                      Container(width: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(3)),
                    ],
                  ),
                ),
                Container(height: 4, color: widget.borderColor),
                Expanded(child: _buildImage(4)),
              ],
            ),
            4 => Stack(
              children: [
                Positioned.fill(child: _buildImage(0)),
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: size * 0.25,
                    height: size * 0.25,
                    child: _buildImage(1),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    width: size * 0.25,
                    height: size * 0.25,
                    child: _buildImage(2),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    width: size * 0.25,
                    height: size * 0.25,
                    child: _buildImage(3),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    width: size * 0.25,
                    height: size * 0.25,
                    child: _buildImage(4),
                  ),
                ),
              ],
            ),
            5 => Column(
              children: [
                Expanded(flex: 2, child: _buildImage(0)),
                Container(height: 4, color: widget.borderColor),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildImage(1),
                      _buildImage(2),
                      _buildImage(3),
                      _buildImage(4),
                    ],
                  ),
                ),
              ],
            ),
            6 => Row(
              children: [
                Expanded(flex: 2, child: _buildImage(0)),
                Container(width: 4, color: widget.borderColor),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _buildImage(1)),
                      Container(height: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(2)),
                      Container(height: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(3)),
                      Container(height: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(4)),
                    ],
                  ),
                ),
              ],
            ),
            7 => Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildImage(0)),
                      Container(width: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(1)),
                    ],
                  ),
                ),
                Container(height: 4, color: widget.borderColor),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildImage(2)),
                      Container(width: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(3)),
                      Container(width: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(4)),
                    ],
                  ),
                ),
              ],
            ),
            8 => Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _buildImage(0)),
                      Container(height: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(1)),
                    ],
                  ),
                ),
                Container(width: 4, color: widget.borderColor),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _buildImage(2)),
                      Container(height: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(3)),
                      Container(height: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(4)),
                    ],
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
                    width: size * 0.25,
                    height: size * 0.25,
                    child: _buildImage(1),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    width: size * 0.25,
                    height: size * 0.25,
                    child: _buildImage(2),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    width: size * 0.25,
                    height: size * 0.25,
                    child: _buildImage(3),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: size * 0.25,
                    height: size * 0.25,
                    child: _buildImage(4),
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