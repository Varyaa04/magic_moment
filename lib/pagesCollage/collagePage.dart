import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/rendering.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_html/html.dart' as html;
import 'templates/2photos_collage.dart';
import 'templates/3photos_collage.dart';
import 'templates/4photos_collage.dart';
import 'templates/5photos_collage.dart';
import 'templates/6photos_collage.dart';

class CollagePage extends StatefulWidget {
  final List<File> images;

  const CollagePage({super.key, required this.images});

  @override
  _CollagePageState createState() => _CollagePageState();
}

class _CollagePageState extends State<CollagePage> {
  late List<ImageProvider> _imageProviders;
  late List<Widget> _collageTemplates;
  int _currentTemplateIndex = 0;
  final GlobalKey _collageKey = GlobalKey();
  bool _isSaving = false;
  bool _isLoading = true;
  double _borderWidth = 0.0;
  Color _borderColor = Colors.white;
  double _borderRadius = 8.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeImages();
  }

  Future<void> _initializeImages() async {
    setState(() => _isLoading = true);
    try {
      _imageProviders = [];
      for (var file in widget.images) {
        try {
          if (kIsWeb) {
            final bytes = await file.readAsBytes();
            _imageProviders.add(MemoryImage(bytes));
            debugPrint('Loaded web image, bytes: ${bytes.length}');
          } else {
            if (await file.exists()) {
              _imageProviders.add(FileImage(file));
              debugPrint('Loaded mobile image: ${file.path}');
            } else {
              debugPrint('File does not exist: ${file.path}');
            }
          }
        } catch (e) {
          debugPrint('Error loading image ${file.path}: $e');
        }
      }

      if (_imageProviders.isEmpty) {
        setState(() {
          _errorMessage = 'No valid images could be loaded';
          _isLoading = false;
        });
        return;
      }

      await _loadCollageTemplates();

      setState(() {
        _isLoading = false;
      });

      debugPrint('Loaded ${_imageProviders.length} images');
      debugPrint('Available templates: ${_collageTemplates.length}');
    } catch (e) {
      debugPrint('Error initializing images: $e');
      setState(() {
        _errorMessage = 'Failed to initialize images: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCollageTemplates() async {
    debugPrint('Loading templates for ${_imageProviders.length} images');
    try {
      switch (_imageProviders.length) {
        case 2:
          _collageTemplates = getTwoPhotosCollages(_imageProviders);
          break;
        case 3:
          _collageTemplates = getThreePhotosCollages(_imageProviders);
          break;
        case 4:
          _collageTemplates = getFourPhotosCollages(_imageProviders);
          break;
        case 5:
          _collageTemplates = getFivePhotosCollages(_imageProviders);
          break;
        case 6:
          _collageTemplates = getSixPhotosCollages(_imageProviders);
          break;
        default:
          _collageTemplates = [];
          setState(() {
            _errorMessage = 'Unsupported number of images: ${_imageProviders.length}. Please select 2-6 images.';
          });
      }

      if (_collageTemplates.isEmpty) {
        setState(() {
          _errorMessage = 'No templates available for ${_imageProviders.length} images';
        });
      }
    } catch (e) {
      debugPrint('Error loading templates: $e');
      setState(() {
        _errorMessage = 'Failed to load templates: $e';
      });
    }
  }

  void _changeTemplate(int index) {
    if (index >= 0 && index < _collageTemplates.length) {
      setState(() {
        _currentTemplateIndex = index;
      });
    }
  }

  void _nextTemplate() {
    if (_currentTemplateIndex < _collageTemplates.length - 1) {
      setState(() {
        _currentTemplateIndex++;
      });
    }
  }

  void _previousTemplate() {
    if (_currentTemplateIndex > 0) {
      setState(() {
        _currentTemplateIndex--;
      });
    }
  }

  Future<void> _saveCollage() async {
    if (_isSaving || _isLoading || _collageTemplates.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final boundary = _collageKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Render boundary not found');
      }

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert image to byte data');
      }

      final pngBytes = byteData.buffer.asUint8List();

      if (kIsWeb) {
        final base64String = html.window.btoa(String.fromCharCodes(pngBytes));
        final dataUrl = 'data:image/png;base64,$base64String';
        final anchor = html.AnchorElement(href: dataUrl)
          ..setAttribute('download', 'collage.png')
          ..click();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collage downloaded successfully!')),
        );
      } else {
        if (!await _requestStoragePermission()) {
          throw Exception('Storage permission denied');
        }

        final result = await ImageGallerySaver.saveImage(pngBytes);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['isSuccess'] == true
                ? 'Collage saved successfully!'
                : 'Failed to save collage: ${result['errorMessage'] ?? 'Unknown error'}'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving collage: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save collage: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (kIsWeb) return true;

    final status = await Permission.storage.request();
    if (!status.isGranted) {
      debugPrint('Storage permission denied');
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(FluentIcons.arrow_left_16_filled),
                        color: Colors.white,
                        iconSize: 30,
                        tooltip: appLocalizations?.back ?? 'Back',
                      ),
                      IconButton(
                        onPressed: _isSaving || _isLoading || _collageTemplates.isEmpty ? null : _saveCollage,
                        icon: const Icon(FluentIcons.arrow_download_16_filled),
                        color: Colors.white,
                        iconSize: 30,
                        tooltip: appLocalizations?.save ?? 'Save',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Collage preview
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      border: _borderWidth > 0
                          ? Border.all(color: _borderColor, width: _borderWidth)
                          : null,
                      borderRadius: BorderRadius.circular(_borderRadius),
                    ),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : _errorMessage != null
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 50, color: Colors.white),
                          const SizedBox(height: 10),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(appLocalizations?.back ?? 'Back'),
                          ),
                        ],
                      ),
                    )
                        : _imageProviders.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 50, color: Colors.white),
                          const SizedBox(height: 10),
                          Text(
                            appLocalizations?.noImages ?? 'No valid images provided',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(appLocalizations?.back ?? 'Back'),
                          ),
                        ],
                      ),
                    )
                        : _collageTemplates.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 50, color: Colors.white),
                          const SizedBox(height: 10),
                          Text(
                            appLocalizations?.noTemplates ??
                                'No templates for ${_imageProviders.length} images',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(appLocalizations?.back ?? 'Back'),
                          ),
                        ],
                      ),
                    )
                        : RepaintBoundary(
                      key: _collageKey,
                      child: Container(
                        decoration: BoxDecoration(
                          border: _borderWidth > 0
                              ? Border.all(color: _borderColor, width: _borderWidth)
                              : null,
                          borderRadius: BorderRadius.circular(_borderRadius),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(_borderRadius),
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: _collageTemplates[_currentTemplateIndex],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Border controls
                if (!_isLoading && _errorMessage == null && _imageProviders.isNotEmpty && _collageTemplates.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.border_outer, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              appLocalizations?.borderWidth ?? 'Border Width',
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                        Slider(
                          value: _borderWidth,
                          min: 0,
                          max: 20,
                          divisions: 40,
                          label: _borderWidth.round().toString(),
                          onChanged: (value) {
                            setState(() => _borderWidth = value);
                          },
                          activeColor: Colors.blue,
                          inactiveColor: Colors.grey,
                        ),
                        Row(
                          children: [
                            const Icon(Icons.rounded_corner, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              appLocalizations?.borderRadius ?? 'Border Radius',
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                        Slider(
                          value: _borderRadius,
                          min: 0,
                          max: 50,
                          divisions: 50,
                          label: _borderRadius.round().toString(),
                          onChanged: (value) {
                            setState(() => _borderRadius = value);
                          },
                          activeColor: Colors.blue,
                          inactiveColor: Colors.grey,
                        ),
                        Row(
                          children: [
                            const Icon(Icons.color_lens, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              appLocalizations?.borderColor ?? 'Border Color',
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildColorButton(Colors.white),
                              const SizedBox(width: 8),
                              _buildColorButton(Colors.black),
                              const SizedBox(width: 8),
                              _buildColorButton(Colors.red),
                              const SizedBox(width: 8),
                              _buildColorButton(Colors.blue),
                              const SizedBox(width: 8),
                              _buildColorButton(Colors.green),
                              const SizedBox(width: 8),
                              _buildColorButton(Colors.yellow),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 10),

                // Template selector
                if (!_isLoading && _errorMessage == null && _collageTemplates.isNotEmpty)
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _collageTemplates.length,
                      itemBuilder: (context, index) => _buildCollageTemplate(index),
                    ),
                  ),

                const SizedBox(height: 10),

                // Bottom navigation
                if (!_isLoading && _errorMessage == null && _collageTemplates.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: _currentTemplateIndex > 0 ? _previousTemplate : null,
                          icon: const Icon(FluentIcons.arrow_hook_up_left_16_regular),
                          color: Colors.white,
                          iconSize: 30,
                          tooltip: appLocalizations?.previous ?? 'Previous',
                        ),
                        IconButton(
                          onPressed: _currentTemplateIndex < _collageTemplates.length - 1 ? _nextTemplate : null,
                          icon: const Icon(FluentIcons.arrow_hook_up_right_16_filled),
                          color: Colors.white,
                          iconSize: 30,
                          tooltip: appLocalizations?.next ?? 'Next',
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (_isSaving)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollageTemplate(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => _changeTemplate(index),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _currentTemplateIndex == index ? Colors.blue : Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
                border: _currentTemplateIndex == index
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: _collageTemplates[index],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Template ${index + 1}',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() => _borderColor = color);
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _borderColor == color ? Colors.white : Colors.grey,
            width: 2,
          ),
        ),
      ),
    );
  }
}