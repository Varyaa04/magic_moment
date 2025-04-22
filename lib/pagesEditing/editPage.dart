import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:image_cropper/image_cropper.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'cropPanel.dart';
import 'brightnessPanel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

class EditPage extends StatefulWidget {
  final dynamic imageBytes;

  const EditPage({super.key, required this.imageBytes});

  @override
  _EditPageState createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  bool _showCropPanel = false;
  bool _showBrightPanel = false;
  CropAspectRatioPreset _selectedCropPreset = CropAspectRatioPreset.original;
  late Uint8List _currentImage;
  late Uint8List _originalImage;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeImage();
  }

  Future<void> _initializeImage() async {
    try {
      if (widget.imageBytes is File) {
        final file = widget.imageBytes as File;
        _currentImage = await file.readAsBytes();
      } else if (widget.imageBytes is Uint8List) {
        _currentImage = widget.imageBytes as Uint8List;
      } else {
        throw Exception('Unsupported image type');
      }
      _originalImage = Uint8List.fromList(_currentImage);
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading image: ${e.toString()}')),
        );
      }
    }
  }

  void _toggleCropPanel() {
    setState(() {
      _showCropPanel = !_showCropPanel;
      if (_showBrightPanel) _showBrightPanel = false;
    });
  }

  void _toggleBrightPanel() {
    setState(() {
      _showBrightPanel = !_showBrightPanel;
      if (_showCropPanel) _showCropPanel = false;
    });
  }

  void _handleButtonPress(int index) {
    switch (index) {
      case 0: // Crop
        _toggleCropPanel();
        break;
      case 1: // Brightness
        _toggleBrightPanel();
        break;
      default:
        debugPrint('Button $index pressed');
    }
  }

  void _updateImage(Uint8List newImage) {
    if (!mounted) return;
    setState(() {
      _currentImage = newImage;
    });
  }

  Future<void> _saveImage() async {
    if (!_isInitialized || !mounted) return;

    try {
      if (kIsWeb) {
        await _downloadImageWeb(_currentImage);
      } else {
        await _saveImageToGallery(_currentImage);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.save ?? 'Image saved'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _downloadImageWeb(Uint8List bytes) async {
    try {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'edited_image_${DateTime.now().millisecondsSinceEpoch}.png')
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      debugPrint('Web download error: $e');
      throw Exception('Failed to download image: $e');
    }
  }

  Future<void> _saveImageToGallery(Uint8List bytes) async {
    try {
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/image_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(imagePath);
      await file.writeAsBytes(bytes);

      const channel = MethodChannel('gallery_saver');
      await channel.invokeMethod('saveImage', imagePath);
    } on PlatformException catch (e) {
      debugPrint('Failed to save image: ${e.message}');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: Colors.black,
            child: Column(
              children: [
                // Top toolbar
                SafeArea(
                  bottom: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(FluentIcons.arrow_left_16_filled),
                        color: Colors.white,
                      ),
                      IconButton(
                        onPressed: _isInitialized ? _saveImage : null,
                        icon: const Icon(Icons.save_alt_rounded),
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),

                // Image area
                Expanded(
                  child: _isInitialized
                      ? InteractiveViewer(
                    child: Center(
                      child: Image.memory(
                        _currentImage,
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                      : const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),

                // Bottom tools panel
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          onPressed: _showCropPanel
                              ? _toggleCropPanel
                              : _showBrightPanel
                              ? _toggleBrightPanel
                              : null,
                          icon: const Icon(FluentIcons.arrow_hook_up_left_16_regular),
                          color: Colors.white,
                        ),
                        IconButton(
                          onPressed: _showCropPanel
                              ? _applyCrop
                              : _showBrightPanel
                              ? () {
                            _toggleBrightPanel();
                            _originalImage = Uint8List.fromList(_currentImage);
                          }
                              : null,
                          icon: const Icon(FluentIcons.arrow_hook_up_right_16_filled),
                          color: Colors.white,
                        ),
                      ],
                    ),
                    Container(height: 1, color: Colors.white.withOpacity(0.3)),
                    _buildToolsPanel(context),
                  ],
                ),
              ],
            ),
          ),

          //  панель обрезки
          if (_showCropPanel)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CropPanel(
                onCancel: _toggleCropPanel,
                onApply: _applyCrop,
                currentPreset: _selectedCropPreset,
                onCropTypeSelected: (preset) {
                  if (mounted) {
                    setState(() {
                      _selectedCropPreset = preset;
                    });
                  }
                },
              ),
            ),

          //  панель параметров
          if (_showBrightPanel)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: BrightnessPanel(
                onCancel: _toggleBrightPanel,
                onApply: _toggleBrightPanel,
                originalImage: _originalImage,
                onImageChanged: _updateImage,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolsPanel(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: List.generate(8, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _handleButtonPress(index),
                  icon: Icon(
                    _getIconForIndex(index),
                    size: 28,
                  ),
                  color: Colors.white,
                ),
                const SizedBox(height: 4),
                Text(
                  _getLabelForIndex(index, context),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _getLabelForIndex(int index, BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    switch (index) {
      case 0: return appLocalizations?.crop ?? 'Crop';
      case 1: return appLocalizations?.parametrs ?? 'Parametrs';
      case 2: return appLocalizations?.adjust ?? 'Adjust';
      case 3: return appLocalizations?.filters ?? 'Filters';
      case 4: return appLocalizations?.draw ?? 'Draw';
      case 5: return appLocalizations?.text ?? 'Text';
      case 6: return appLocalizations?.effects ?? 'Effects';
      case 7: return appLocalizations?.noise ?? 'Noise';
      default: return 'button';
    }
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0: return FluentIcons.crop_24_filled;
      case 1: return FluentIcons.brightness_high_24_filled;
      case 2: return FluentIcons.settings_24_regular;
      case 3: return Icons.filter_b_and_w;
      case 4: return FluentIcons.ink_stroke_24_regular;
      case 5: return FluentIcons.text_field_24_regular;
      case 6: return FluentIcons.emoji_sparkle_24_regular;
      case 7: return Icons.noise_aware;
      default: return Icons.error;
    }
  }

  Future<void> _applyCrop() async {

  }
}