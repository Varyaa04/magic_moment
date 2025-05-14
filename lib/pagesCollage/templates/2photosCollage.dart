import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

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

  Widget _buildImage(int index, Widget image) {
    return GestureDetector(
      onTap: () => widget.onImageTapped?.call(index),
      onScaleUpdate: (details) {
        _debouncer.run(() {
          setState(() {
            widget.onPositionChanged(
                index,
                widget.positions[index] +
                    Offset(
                      details.focalPointDelta.dx / 300,
                      details.focalPointDelta.dy / 300,
                    ));
            if (details.scale != 1.0) {
              final newScale = widget.scales[index] +
                  (details.scale > 1.0 ? 0.05 : -0.05);
              widget.onScaleChanged(index, newScale.clamp(0.5, 2.0));
            }
            if (details.rotation != 0) {
              widget.onRotationChanged(
                  index,
                  widget.rotations[index] +
                      details.rotation * 5 * math.pi / 180);
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
          decoration: widget.selectedImageDecoration(index),
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
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        return SizedBox(
          width: size,
          height: size,
          child: switch (widget.layoutIndex) {
            0 => Row(
              children: [
                Expanded(
                    child: _buildImage(
                        0, Image(image: widget.images[0], fit: BoxFit.cover))),
                Container(width: 4, color: widget.borderColor),
                Expanded(
                    child: _buildImage(
                        1, Image(image: widget.images[1], fit: BoxFit.cover))),
              ],
            ),
            1 => Column(
              children: [
                Expanded(
                    child: _buildImage(
                        0, Image(image: widget.images[0], fit: BoxFit.cover))),
                Container(height: 4, color: widget.borderColor),
                Expanded(
                    child: _buildImage(
                        1, Image(image: widget.images[1], fit: BoxFit.cover))),
              ],
            ),
            2 => Stack(
              children: [
                Positioned.fill(
                    child: _buildImage(
                        0, Image(image: widget.images[0], fit: BoxFit.cover))),
                Align(
                  alignment: Alignment.bottomRight,
                  child: SizedBox(
                    width: size / 3,
                    height: size / 3,
                    child: _buildImage(
                        1, Image(image: widget.images[1], fit: BoxFit.cover)),
                  ),
                ),
              ],
            ),
            3 => Column(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildImage(
                      0, Image(image: widget.images[0], fit: BoxFit.cover)),
                ),
                Container(height: 4, color: widget.borderColor),
                Expanded(
                  flex: 1,
                  child: _buildImage(
                      1, Image(image: widget.images[1], fit: BoxFit.cover)),
                ),
              ],
            ),
            4 => Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildImage(
                      0, Image(image: widget.images[0], fit: BoxFit.cover)),
                ),
                Container(width: 4, color: widget.borderColor),
                Expanded(
                  flex: 1,
                  child: _buildImage(
                      1, Image(image: widget.images[1], fit: BoxFit.cover)),
                ),
              ],
            ),
            5 => GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildImage(0, Image(image: widget.images[0], fit: BoxFit.cover)),
                _buildImage(1, Image(image: widget.images[1], fit: BoxFit.cover)),
              ],
            ),
            6 => Column(
              children: [
                Expanded(
                    child: _buildImage(
                        0, Image(image: widget.images[0], fit: BoxFit.cover))),
                Container(height: 4, color: widget.borderColor),
                Expanded(
                    child: _buildImage(
                        1, Image(image: widget.images[1], fit: BoxFit.cover))),
              ],
            ),
            7 => Row(
              children: [
                Expanded(
                    child: _buildImage(
                        0, Image(image: widget.images[0], fit: BoxFit.cover))),
                Container(width: 4, color: widget.borderColor),
                Expanded(
                    child: _buildImage(
                        1, Image(image: widget.images[1], fit: BoxFit.cover))),
              ],
            ),
            8 => Stack(
              children: [
                Positioned.fill(
                    child: _buildImage(
                        0, Image(image: widget.images[0], fit: BoxFit.cover))),
                Center(
                  child: Container(
                    width: size / 2,
                    height: size / 2,
                    decoration: BoxDecoration(
                      border: Border.all(color: widget.borderColor, width: 4),
                    ),
                    child: _buildImage(
                        1, Image(image: widget.images[1], fit: BoxFit.cover)),
                  ),
                ),
              ],
            ),
            9 => Stack(
              children: [
                Positioned.fill(
                    child: _buildImage(
                        0, Image(image: widget.images[0], fit: BoxFit.cover))),
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: size / 3,
                    height: size / 3,
                    decoration: BoxDecoration(
                      border: Border.all(color: widget.borderColor),
                    ),
                    child: _buildImage(
                        1, Image(image: widget.images[1], fit: BoxFit.cover)),
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