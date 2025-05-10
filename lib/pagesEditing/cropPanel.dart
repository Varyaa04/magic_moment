import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class CropPanel extends StatefulWidget {
  final Uint8List image;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;
  final Function(Uint8List, {String? action, String? operationType, Map<String, dynamic>? parameters}) onUpdateImage;

  const CropPanel({
    required this.image,
    required this.onCancel,
    required this.onApply,
    required this.onUpdateImage,
    super.key,
  });

  @override
  State<CropPanel> createState() => _CropPanelState();
}

class _CropPanelState extends State<CropPanel> {
  ui.Image? _image;
  Rect _cropRect = Rect.zero;
  double _scale = 1.0;
  Size _displaySize = Size.zero;
  bool _loading = true;

  final Map<String, double?> _aspectRatios = {
    'Free': null,
    '1:1': 1.0,
    '4:3': 4 / 3,
    '3:4': 3 / 4,
    '16:9': 16 / 9,
    '9:16': 9 / 16,
  };
  String _selectedRatio = 'Free';

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  Future<void> _decodeImage() async {
    final codec = await ui.instantiateImageCodec(widget.image);
    final frame = await codec.getNextFrame();
    final img = frame.image;
    final imgSize = Size(img.width.toDouble(), img.height.toDouble());

    final maxW = MediaQuery.of(context).size.width * 0.9;
    final maxH = MediaQuery.of(context).size.height * 0.6;
    double w = imgSize.width;
    double h = imgSize.height;
    if (w > maxW) {
      w = maxW;
      h = w / (imgSize.width / imgSize.height);
    }
    if (h > maxH) {
      h = maxH;
      w = h * (imgSize.width / imgSize.height);
    }

    final scale = imgSize.width / w;
    final cropW = w * 0.8 * scale;
    final cropH = h * 0.8 * scale;
    final left = (imgSize.width - cropW) / 2;
    final top = (imgSize.height - cropH) / 2;

    setState(() {
      _image = img;
      _displaySize = Size(w, h);
      _scale = scale;
      _cropRect = Rect.fromLTWH(left, top, cropW, cropH);
      _loading = false;
    });
  }

  Future<void> _applyCrop() async {
    if (_image == null) return;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final dstRect = Rect.fromLTWH(0, 0, _cropRect.width, _cropRect.height);
    canvas.drawImageRect(_image!, _cropRect, dstRect, Paint());

    final pic = recorder.endRecording();
    final result = await pic.toImage(_cropRect.width.toInt(), _cropRect.height.toInt());
    final byteData = await result.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    final bytes = byteData.buffer.asUint8List();
    await widget.onUpdateImage(
      bytes,
      action: 'Crop applied',
      operationType: 'crop',
      parameters: {
        'aspect': _selectedRatio,
        'left': _cropRect.left,
        'top': _cropRect.top,
        'width': _cropRect.width,
        'height': _cropRect.height,
      },
    );
    widget.onApply(bytes);
  }

  void _applyAspect(String ratioKey) {
    final ratio = _aspectRatios[ratioKey];
    if (_image == null || ratio == null) return;
    final current = _cropRect;
    double w = current.width;
    double h = w / ratio;
    if (h > _image!.height - current.top) {
      h = _image!.height - current.top;
      w = h * ratio;
    }
    setState(() {
      _selectedRatio = ratioKey;
      _cropRect = Rect.fromLTWH(current.left, current.top, w, h);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Expanded(
              child: Center(
                child: SizedBox(
                  width: _displaySize.width,
                  height: _displaySize.height,
                  child: Stack(
                    children: [
                      Image.memory(widget.image, fit: BoxFit.contain),
                      Positioned.fromRect(
                        rect: Rect.fromLTWH(
                          _cropRect.left / _scale,
                          _cropRect.top / _scale,
                          _cropRect.width / _scale,
                          _cropRect.height / _scale,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[900],
              child: Column(
                children: [
                  Wrap(
                    spacing: 8,
                    children: _aspectRatios.keys.map((e) => ChoiceChip(
                      label: Text(e, style: const TextStyle(color: Colors.white)),
                      selected: _selectedRatio == e,
                      onSelected: (_) => _applyAspect(e),
                      selectedColor: Colors.blue,
                      backgroundColor: Colors.grey[800],
                    )).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: widget.onCancel,
                        child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                      ),
                      ElevatedButton(
                        onPressed: _applyCrop,
                        child: const Text('Apply'),
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
