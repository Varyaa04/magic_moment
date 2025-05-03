import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'exampleFilters.dart';

class FiltersPanel extends StatefulWidget {
  final Uint8List imageBytes;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;

  const FiltersPanel({
    required this.imageBytes,
    required this.onCancel,
    required this.onApply,
    Key? key,
  }) : super(key: key);

  @override
  _FiltersPanelState createState() => _FiltersPanelState();
}

class _FiltersPanelState extends State<FiltersPanel> {
  late Uint8List _currentImageBytes;
  double _scaleFactor = 1.0;
  bool _isProcessing = false;
  List<double> _currentFilter = [ // Добавляем переменную для хранения текущего фильтра
    1.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 1.0, 0.0
  ];

  final Map<String, List<double>> _filters = {
    'Original': [
      1.0, 0.0, 0.0, 0.0, 0.0,
      0.0, 1.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 1.0, 0.0
    ],
    'Black & White': bw,
    'Sepia': sepium,
    'Purple': purple,
    'Yellow': yellow,
    'Cyan': cyan,
    'Old Times': oldTimes,
    'Cold Life': coldLife,
    'Milk': milk,
    'Shining': shining,
    'Warmth': warmth,
    'Contrast': contrast,
    'Vintage': vintage,
    'Ice': ice,
    'Retro': retro,
    'Shades': shades,
    'Emotions': emotions,
    'Misty': misty,
    'Heatwave': heatwave,
    'Sadness': sadness,
    'Bright Day': brightDay,
    'Shadow': shadow,
    'Mushroom': mushroom,
    'Cold Light': coldLight,
    'Serenity': serenity,
    'Fragments': fragments,
    'Winter Morning': winterMorning,
    'Graphite': graphite,
    'Anxiety': anxiety,
    'Quiet Night': quietNight,
    'Bunnies': bunnies,
    'Summer Freshness': summerFreshness,
    'Calm Waves': calmWaves,
    'Vibrant Life': vibrantLife,
    'Misty Morning': mistyMorning,
    'Sunlit Grove': sunlitGrove,
    'Twilight Shadows': twilightShadows,
    'Crystal Clear': crystalClear,
    'Dreamy Softness': dreamySoftness,
    'Warm Vintage': warmVintage,
    'Cold Winter': coldWinter,
    'Playful Colors': playfulColors,
    'Monochrome Elegance': monochromeElegance,
    'Ethereal Glow': etherealGlow,
    'Polarized Effect': polarizedEffect,
    'Bold Contrast': boldContrast,
    'Nostalgic Fade': nostalgicFade,
    'Vibrant Mood': vibrantMood,
    'Serene Pastels': serenePastels,
    'Cyber Style': cyberStyle,
    'Retro Look': retroLook,
    'Feel Good': feelGood,
    'Faded Dream': fadedDream,
    'High Key': highKey,
    'Low Key': lowKey,
    'Elegant Dark': elegantDark,
    'Light & Shadow': lightAndShadow,
    'Classic Style': classicStyle,
    'Glowing Edges': glowingEdges,
    'Soft Glow': softGlow,
    'Sepia Tone': sepiaTone,
    'Night Vision': nightVision,
    'Muted Harmony': mutedHarmony,
    'Silvery Moonlight': silveryMoonlight,
    'Brilliant Highlight': brilliantHighlight,
    'Cool Blue': coolBlue,
    'Warm Sunset': warmSunset,
    'Foggy Vision': foggyVision,
    'Fresh Mint': freshMint,
    'Artistic Blend': artisticBlend,
    'Faded Light': fadedLight,
    'Clear Night': clearNight,  };

  @override
  void initState() {
    super.initState();
    _currentImageBytes = widget.imageBytes;
    _verifyImage(widget.imageBytes);
  }

  Future<void> _verifyImage(Uint8List bytes) async {
    try {
      await _loadImage(bytes);
    } catch (e) {
      debugPrint('Image verification failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid image format')),
      );
      widget.onCancel();
    }
  }

  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(
            color: Colors.black.withOpacity(0.8),
            child: Column(
              children: [
              AppBar(
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onCancel,
              ),
              title: const Text('Filters'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _isProcessing ? null : () async {
                    // Применяем текущий фильр к оригинальному изображению перед сохранением
                    setState(() => _isProcessing = true);
                    try {
                      final ui.Image originalImage = await _loadImage(widget.imageBytes);
                      final ByteData? originalBytes = await originalImage.toByteData();

                      if (originalBytes == null) {
                        throw Exception("Failed to get byte data from image");
                      }

                      final Uint8List originalPixels = originalBytes.buffer.asUint8List();
                      final Uint8List filteredPixels = await _applyColorMatrix(
                        originalPixels,
                        originalImage.width,
                        originalImage.height,
                        _currentFilter, // Используем сохраненный фильтр
                      );

                      widget.onApply(filteredPixels);
                    } catch (e) {
                      debugPrint('Error applying final filter: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to apply filter: ${e.toString()}')),
                      );
                    } finally {
                      setState(() => _isProcessing = false);
                    }
                  },
                ),
              ],
            ),
                _buildScaleControlPanel(),
                Expanded(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    onInteractionUpdate: (ScaleUpdateDetails details) {
                      setState(() {
                        _scaleFactor = details.scale;
                      });
                    },
                    child: Center(
                      child: Image.memory(
                        _currentImageBytes,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Text('Failed to load image'));
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 150,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _filters.entries.map((entry) {
                      return _buildFilterPreview(entry.key, entry.value);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }



  Widget _buildScaleControlPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      height: 60,
      color: Colors.black.withOpacity(0.6),
      child: Row(
        children: [
          const Text('Scale:', style: TextStyle(color: Colors.white)),
          const SizedBox(width: 10),
          Expanded(
            child: Slider(
              value: _scaleFactor,
              min: 0.5,
              max: 3.0,
              onChanged: (value) {
                setState(() {
                  _scaleFactor = value;
                });
              },
            ),
          ),
          TextButton(
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
            onPressed: () {
              setState(() {
                _scaleFactor = 1.0;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPreview(String name, List<double> matrix) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          InkWell(
            onTap: () => _applyFilter(matrix),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: MemoryImage(widget.imageBytes),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.matrix(matrix),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(name, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Future<void> _applyFilter(List<double> matrix) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _currentFilter = matrix; // Сохраняем выбранный фильтр
    });

    try {
      final ui.Image originalImage = await _loadImage(widget.imageBytes);
      final ByteData? originalBytes = await originalImage.toByteData();

      if (originalBytes == null) {
        throw Exception("Failed to get byte data from image");
      }

      final Uint8List originalPixels = originalBytes.buffer.asUint8List();
      final Uint8List filteredPixels = await _applyColorMatrix(
        originalPixels,
        originalImage.width,
        originalImage.height,
        matrix,
      );

      setState(() {
        _currentImageBytes = filteredPixels;
      });

      if (_scaleFactor != 1.0) {
        final Uint8List scaledPixels = await _applyScale(
          filteredPixels,
          originalImage.width,
          originalImage.height,
          _scaleFactor,
        );

        setState(() {
          _currentImageBytes = scaledPixels;
        });
      }
    } catch (e) {
      debugPrint('Error applying filter: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to apply filter: ${e.toString()}')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<ui.Image> _loadImage(Uint8List bytes) async {
    try {
      debugPrint('Loading image of size: ${bytes.length} bytes');
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      debugPrint('Error loading image: $e');
      rethrow;
    }
  }
  Future<Uint8List> _applyColorMatrix(
      Uint8List pixels,
      int width,
      int height,
      List<double> matrix,
      ) async {
    final ByteData input = ByteData.sublistView(pixels);
    final ByteData output = ByteData(pixels.length);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int offset = (y * width + x) * 4;
        final int r = input.getUint8(offset);
        final int g = input.getUint8(offset + 1);
        final int b = input.getUint8(offset + 2);
        final int a = input.getUint8(offset + 3);

        final double newR = (r * matrix[0] + g * matrix[1] + b * matrix[2] + a * matrix[3] + matrix[4]).clamp(0, 255);
        final double newG = (r * matrix[5] + g * matrix[6] + b * matrix[7] + a * matrix[8] + matrix[9]).clamp(0, 255);
        final double newB = (r * matrix[10] + g * matrix[11] + b * matrix[12] + a * matrix[13] + matrix[14]).clamp(0, 255);
        final double newA = (r * matrix[15] + g * matrix[16] + b * matrix[17] + a * matrix[18] + matrix[19]).clamp(0, 255);

        output.setUint8(offset, newR.round());
        output.setUint8(offset + 1, newG.round());
        output.setUint8(offset + 2, newB.round());
        output.setUint8(offset + 3, newA.round());
      }
    }

    return Uint8List.view(output.buffer);
  }

  Future<Uint8List> _applyScale(
      Uint8List pixels,
      int width,
      int height,
      double scale,
      ) async {
    if (scale == 1.0) return pixels;

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint();

      final codec = await ui.instantiateImageCodec(pixels);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final newWidth = (width * scale).toInt();
      final newHeight = (height * scale).toInt();

      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()),
        paint,
      );

      final picture = recorder.endRecording();
      final scaledImage = await picture.toImage(newWidth, newHeight);
      final byteData = await scaledImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception("Failed to convert scaled image to bytes");
      }

      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error in _applyScale: $e');
      return pixels;
    }
  }
}