import 'package:flutter/material.dart';
import 'dart:async';

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
    return List.generate(10, (index) => _FivePhotosCollage(
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
    ));
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

  Widget _buildImage(int index, Widget image) {
    return GestureDetector(
      onTap: () => widget.onImageTapped?.call(index),
      onScaleUpdate: (details) {
        _debouncer.run(() {
          setState(() {
            widget.onPositionChanged(index, widget.positions[index] + Offset(
              details.focalPointDelta.dx / 300,
              details.focalPointDelta.dy / 300,
            ));
            if (details.scale != 1.0) {
              widget.onScaleChanged(index, (widget.scales[index] * details.scale).clamp(0.5, 2.0));
            }
            if (details.rotation != 0) {
              widget.onRotationChanged(index, widget.rotations[index] + details.rotation / 2);
            }
          });
        });
      },
      onScaleEnd: (details) {
        _debouncer.run(() {
          setState(() {
            widget.onScaleChanged(index, widget.scales[index].clamp(0.5, 2.0));
          });
        });
      },
      child: RepaintBoundary(
        child: Container(
          decoration: widget.selectedImageDecoration?.call(index),
          child: Transform.translate(
            offset: widget.positions[index] * 100,
            child: Transform.rotate(
              angle: widget.rotations[index],
              child: Transform.scale(
                scale: widget.scales[index],
                child: image,
              ),
            ),
          ),
        ),
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
                _buildImage(0, Image(image: widget.images[0], fit: BoxFit.cover)),
                _buildImage(1, Image(image: widget.images[1], fit: BoxFit.cover)),
                _buildImage(2, Image(image: widget.images[2], fit: BoxFit.cover)),
                _buildImage(3, Image(image: widget.images[3], fit: BoxFit.cover)),
                Container(
                  decoration: BoxDecoration(border: Border.all(color: widget.borderColor, width: 2)),
                  child: _buildImage(4, Image(image: widget.images[4], fit: BoxFit.cover)),
                ),
              ],
            ),
            1 => Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildImage(0, Image(image: widget.images[0], fit: BoxFit.cover))),
                      Container(width: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(1, Image(image: widget.images[1], fit: BoxFit.cover))),
                    ],
                  ),
                ),
                Container(height: 4, color: widget.borderColor),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildImage(2, Image(image: widget.images[2], fit: BoxFit.cover))),
                      Container(width: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(3, Image(image: widget.images[3], fit: BoxFit.cover))),
                      Container(width: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(4, Image(image: widget.images[4], fit: BoxFit.cover))),
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
                      Expanded(child: _buildImage(0, Image(image: widget.images[0], fit: BoxFit.cover))),
                      Container(height: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(1, Image(image: widget.images[1], fit: BoxFit.cover))),
                    ],
                  ),
                ),
                Container(width: 4, color: widget.borderColor),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _buildImage(2, Image(image: widget.images[2], fit: BoxFit.cover))),
                      Container(height: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(3, Image(image: widget.images[3], fit: BoxFit.cover))),
                      Container(height: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(4, Image(image: widget.images[4], fit: BoxFit.cover))),
                    ],
                  ),
                ),
              ],
            ),
            3 => Column(
              children: [
                Expanded(child: _buildImage(0, Image(image: widget.images[0], fit: BoxFit.cover))),
                Container(height: 4, color: widget.borderColor),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildImage(1, Image(image: widget.images[1], fit: BoxFit.cover))),
                      Container(width: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(2, Image(image: widget.images[2], fit: BoxFit.cover))),
                      Container(width: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(3, Image(image: widget.images[3], fit: BoxFit.cover))),
                    ],
                  ),
                ),
                Container(height: 4, color: widget.borderColor),
                Expanded(child: _buildImage(4, Image(image: widget.images[4], fit: BoxFit.cover))),
              ],
            ),
            4 => Stack(
              children: [
                Positioned.fill(child: _buildImage(0, Image(image: widget.images[0], fit: BoxFit.cover))),
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: size * 0.25,
                    height: size * 0.25,
                    child: _buildImage(1, Image(image: widget.images[1], fit: BoxFit.cover)),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    width: size * 0.25,
                    height: size * 0.25,
                    child: _buildImage(2, Image(image: widget.images[2], fit: BoxFit.cover)),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    width: size * 0.25,
                    height: size * 0.25,
                    child: _buildImage(3, Image(image: widget.images[3], fit: BoxFit.cover)),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    width: size * 0.25,
                    height: size * 0.25,
                    child: _buildImage(4, Image(image: widget.images[4], fit: BoxFit.cover)),
                  ),
                ),
              ],
            ),
            5 => Column(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildImage(0, Image(image: widget.images[0], fit: BoxFit.cover)),
                ),
                Container(height: 4, color: widget.borderColor),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildImage(1, Image(image: widget.images[1], fit: BoxFit.cover)),
                      _buildImage(2, Image(image: widget.images[2], fit: BoxFit.cover)),
                      _buildImage(3, Image(image: widget.images[3], fit: BoxFit.cover)),
                      _buildImage(4, Image(image: widget.images[4], fit: BoxFit.cover)),
                    ],
                  ),
                ),
              ],
            ),
            6 => Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildImage(0, Image(image: widget.images[0], fit: BoxFit.cover)),
                ),
                Container(width: 4, color: widget.borderColor),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _buildImage(1, Image(image: widget.images[1], fit: BoxFit.cover))),
                      Container(height: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(2, Image(image: widget.images[2], fit: BoxFit.cover))),
                      Container(height: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(3, Image(image: widget.images[3], fit: BoxFit.cover))),
                      Container(height: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(4, Image(image: widget.images[4], fit: BoxFit.cover))),
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
                      Expanded(child: _buildImage(0, Image(image: widget.images[0], fit: BoxFit.cover))),
                      Container(width: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(1, Image(image: widget.images[1], fit: BoxFit.cover))),
                    ],
                  ),
                ),
                Container(height: 4, color: widget.borderColor),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildImage(2, Image(image: widget.images[2], fit: BoxFit.cover))),
                      Container(width: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(3, Image(image: widget.images[3], fit: BoxFit.cover))),
                      Container(width: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(4, Image(image: widget.images[4], fit: BoxFit.cover))),
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
                      Expanded(child: _buildImage(0, Image(image: widget.images[0], fit: BoxFit.cover))),
                      Container(height: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(1, Image(image: widget.images[1], fit: BoxFit.cover))),
                    ],
                  ),
                ),
                Container(width: 4, color: widget.borderColor),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _buildImage(2, Image(image: widget.images[2], fit: BoxFit.cover))),
                      Container(height: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(3, Image(image: widget.images[3], fit: BoxFit.cover))),
                      Container(height: 4, color: widget.borderColor),
                      Expanded(child: _buildImage(4, Image(image: widget.images[4], fit: BoxFit.cover))),
                    ],
                  ),
                ),
              ],
            ),
            9 => Stack(
              children: [
                Positioned.fill(child: _buildImage(0, Image(image: widget.images[0], fit: BoxFit.cover))),
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: size * 0.25,
                    height: size * 0.25,
                    child: _buildImage(1, Image(image: widget.images[1], fit: BoxFit.cover)),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    width: size * 0.25,
                    height: size * 0.25,
                    child: _buildImage(2, Image(image: widget.images[2], fit: BoxFit.cover)),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    width: size * 0.25,
                    height: size * 0.25,
                    child: _buildImage(3, Image(image: widget.images[3], fit: BoxFit.cover)),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: size * 0.25,
                    height: size * 0.25,
                    child: _buildImage(4, Image(image: widget.images[4], fit: BoxFit.cover)),
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