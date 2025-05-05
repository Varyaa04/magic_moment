import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'exampleFilters.dart';

class FiltersPanel extends StatefulWidget {
  final Uint8List imageBytes;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;

  const FiltersPanel({
    required this.imageBytes,
    required this.onCancel,
    required this.onApply,
    super.key,
  });

  @override
  _FiltersPanelState createState() => _FiltersPanelState();
}

class _FiltersPanelState extends State<FiltersPanel> {
  late Uint8List _currentImageBytes;
  double _scaleFactor = 1.0;
  bool _isProcessing = false;
  List<double> _currentFilter = [
    1.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ];

  final Map<String, List<double>> _filters = {
    'Original': [
      1.0, 0.0, 0.0, 0.0, 0.0,
      0.0, 1.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 1.0, 0.0,
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
    'Clear Night': clearNight,
  };

  @override
  void initState() {
    super.initState();
    _currentImageBytes = widget.imageBytes;
    _verifyImage(widget.imageBytes);
  }

  Future<void> _verifyImage(Uint8List bytes) async {
    try {
      final image = await _loadImage(bytes);
      await image.toByteData();
    } catch (e) {
      debugPrint('Image verification failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid image format')),
        );
        widget.onCancel();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(),
                _buildScaleControlPanel(),
                Expanded(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    onInteractionUpdate: (details) {
                      setState(() {
                        _scaleFactor = details.scale;
                      });
                    },
                    child: Center(
                      child: Image.memory(
                        _currentImageBytes,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                _buildFilterList(),
              ],
            ),
            if (_isProcessing)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.7),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: widget.onCancel,
      ),
      title: const Text('Filters', style: TextStyle(color: Colors.white)),
      actions: [
        IconButton(
          icon: const Icon(Icons.check, color: Colors.white),
          onPressed: _isProcessing
              ? null
              : () async {
            setState(() => _isProcessing = true);
            try {
              final filteredBytes = await _applyFilterToOriginal(_currentFilter);
              widget.onApply(filteredBytes);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to apply filter: ${e.toString()}')),
                );
              }
            } finally {
              setState(() => _isProcessing = false);
            }
          },
        ),
      ],
    );
  }

  Widget _buildScaleControlPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withOpacity(0.6),
      child: Row(
        children: [
          const Text('Scale:', style: TextStyle(color: Colors.white)),
          const SizedBox(width: 8),
          Expanded(
            child: Slider(
              value: _scaleFactor,
              min: 0.5,
              max: 3.0,
              divisions: 25,
              activeColor: Colors.blue,
              inactiveColor: Colors.grey.withOpacity(0.5),
              onChanged: (value) {
                setState(() {
                  _scaleFactor = value;
                });
              },
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _scaleFactor = 1.0;
              });
            },
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterList() {
    return Container(
      height: 150,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _filters.entries.map((entry) {
          return _buildFilterPreview(entry.key, entry.value);
        }).toList(),
      ),
    );
  }

  Widget _buildFilterPreview(String name, List<double> matrix) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _applyFilter(matrix),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _currentFilter == matrix ? Colors.blue : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: FutureBuilder<Uint8List>(
                  future: _generateFilterPreview(widget.imageBytes, matrix),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.error, color: Colors.red, size: 24),
                          );
                        },
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _generateFilterPreview(Uint8List bytes, List<double> matrix) async {
    try {
      final image = await _loadImage(bytes);
      final byteData = await image.toByteData();
      if (byteData == null) {
        throw Exception('Failed to get byte data for preview');
      }
      final pixels = byteData.buffer.asUint8List();
      return await _applyColorMatrix(pixels, image.width, image.height, matrix);
    } catch (e) {
      debugPrint('Error generating filter preview: $e');
      rethrow;
    }
  }

  Future<void> _applyFilter(List<double> matrix) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _currentFilter = matrix;
    });

    try {
      final filteredBytes = await _applyFilterToOriginal(matrix);
      setState(() {
        _currentImageBytes = filteredBytes;
      });
    } catch (e) {
      debugPrint('Error applying filter: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to apply filter')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<Uint8List> _applyFilterToOriginal(List<double> matrix) async {
    final image = await _loadImage(widget.imageBytes);
    final byteData = await image.toByteData();
    if (byteData == null) {
      throw Exception('Failed to get byte data from original image');
    }
    final pixels = byteData.buffer.asUint8List();
    var filteredPixels = await _applyColorMatrix(pixels, image.width, image.height, matrix);

    if (_scaleFactor != 1.0) {
      filteredPixels = await _applyScale(filteredPixels, image.width, image.height, _scaleFactor);
    }

    return filteredPixels;
  }

  Future<ui.Image> _loadImage(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      debugPrint('Error loading image: $e');
      throw Exception('Failed to load image: $e');
    }
  }

  Future<Uint8List> _applyColorMatrix(
      Uint8List pixels,
      int width,
      int height,
      List<double> matrix,
      ) async {
    try {
      final input = ByteData.sublistView(pixels);
      final output = ByteData(pixels.length);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final offset = (y * width + x) * 4;
          final r = input.getUint8(offset);
          final g = input.getUint8(offset + 1);
          final b = input.getUint8(offset + 2);
          final a = input.getUint8(offset + 3);

          final newR = (r * matrix[0] + g * matrix[1] + b * matrix[2] + a * matrix[3] + matrix[4]).clamp(0, 255);
          final newG = (r * matrix[5] + g * matrix[6] + b * matrix[7] + a * matrix[8] + matrix[9]).clamp(0, 255);
          final newB = (r * matrix[10] + g * matrix[11] + b * matrix[12] + a * matrix[13] + matrix[14]).clamp(0, 255);
          final newA = (r * matrix[15] + g * matrix[16] + b * matrix[17] + a * matrix[18] + matrix[19]).clamp(0, 255);

          output.setUint8(offset, newR.round());
          output.setUint8(offset + 1, newG.round());
          output.setUint8(offset + 2, newB.round());
          output.setUint8(offset + 3, newA.round());
        }
      }

      return Uint8List.view(output.buffer);
    } catch (e) {
      debugPrint('Error applying color matrix: $e');
      throw Exception('Failed to apply color matrix: $e');
    }
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
      final paint = Paint()..filterQuality = FilterQuality.high;

      final codec = await ui.instantiateImageCodec(pixels);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final newWidth = (width * scale).round();
      final newHeight = (height * scale).round();

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
        throw Exception('Failed to convert scaled image to bytes');
      }

      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error applying scale: $e');
      throw Exception('Failed to apply scale: $e');
    }
  }
}