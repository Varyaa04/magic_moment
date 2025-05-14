import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:MagicMoment/database/magicMomentDatabase.dart';
import 'package:MagicMoment/pagesEditing/background/removeBackground.dart';
import 'package:MagicMoment/pagesEditing/background/blurBackground.dart';
import 'package:MagicMoment/pagesEditing/background/changeBackground.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';

import '../../themeWidjets/colorPicker.dart';

class BackgroundRemovalPanel extends StatefulWidget {
  final Uint8List image;
  final int imageId;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;
  final Function(Uint8List,
      {String? action,
      String? operationType,
      Map<String, dynamic>? parameters}) onUpdateImage;

  const BackgroundRemovalPanel({
    required this.image,
    required this.imageId,
    required this.onCancel,
    required this.onApply,
    required this.onUpdateImage,
    super.key,
  });

  @override
  State<BackgroundRemovalPanel> createState() => _BackgroundRemovalPanelState();
}

class _BackgroundRemovalPanelState extends State<BackgroundRemovalPanel> {
  late ui.Image _backgroundImage;
  Uint8List? _previewImage;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String _currentOperation = '';
  final String _apiKeyBg = 'cHoupRUPfmtWNYmiy6uu9t8Y'; // Replace with secure storage
  Color _selectedBackgroundColor = Colors.white;
  double _blurIntensity = 0.5;
  Uint8List? _backgroundImageBytes;
  BackgroundMode _backgroundMode = BackgroundMode.color;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.image);
      final frame = await codec.getNextFrame();
      _backgroundImage = frame.image;
      setState(() {
        _isInitialized = true;
        _previewImage = widget.image;
      });
      debugPrint('Image loaded successfully');
    } catch (e) {
      debugPrint('Error loading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)?.error ?? 'Error'}: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickBackgroundImage() async {
    try {
      Uint8List? bytes;
      if (kIsWeb) {
        bytes = await ImagePickerWeb.getImageAsBytes();
      } else {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          bytes = await pickedFile.readAsBytes();
        }
      }
      if (bytes == null || bytes.isEmpty) {
        debugPrint('No background image picked');
        return;
      }
      setState(() {
        _backgroundImageBytes = bytes;
        _backgroundMode = BackgroundMode.image;
        debugPrint('Background image picked');
      });
    } catch (e) {
      debugPrint('Error picking background image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)?.error ?? 'Error'}: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _selectBackgroundColor() async {
    Color tempColor = _selectedBackgroundColor;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)?.selectColor ?? 'Select Background Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColor,
              onColorChanged: (color) => tempColor = color,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedBackgroundColor = tempColor;
                  _backgroundImageBytes = null;
                  _backgroundMode = BackgroundMode.color;
                });
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)?.apply ?? 'Apply'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectBlurIntensity() async {
    double tempIntensity = _blurIntensity;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)?.blurIntensity ?? 'Blur Intensity'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: tempIntensity,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label: tempIntensity.toStringAsFixed(1),
                    onChanged: (value) => setState(() => tempIntensity = value),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _blurIntensity = tempIntensity;
                });
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)?.apply ?? 'Apply'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processImage(String operation) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _currentOperation = operation;
    });

    try {
      Uint8List? resultBytes;
      String? backgroundColorHex;

      if (operation == 'remove_bg') {
        resultBytes = await removeBackgroundFromBytes(
          imageBytes: widget.image,
          apiKey: _apiKeyBg,
        );
      } else if (operation == 'blur_bg') {
        resultBytes = await blurBackgroundWithRemoveBg(
          imageBytes: widget.image,
          apiKey: _apiKeyBg,
          blurIntensity: _blurIntensity, // Pass blur intensity
        );
      } else if (operation == 'change_bg') {
        if (_backgroundMode == BackgroundMode.color) {
          backgroundColorHex =
          '#${_selectedBackgroundColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';
        }

        resultBytes = await changeBackgroundWithRemoveBg(
          imageBytes: widget.image,
          apiKey: _apiKeyBg,
          colorHex: _backgroundMode == BackgroundMode.color ? backgroundColorHex : null,
          backgroundImageBytes: _backgroundMode == BackgroundMode.image ? _backgroundImageBytes : null,
        );
      }

      if (resultBytes != null && mounted) {
        // Save to database
        final db = await MagicMomentDatabase.instance.database;
        final history = EditHistory(
          imageId: widget.imageId,
          operationType: operation,
          operationParameters: {
            if (operation == 'blur_bg') 'blur_intensity': _blurIntensity,
            if (operation == 'change_bg' && backgroundColorHex != null)
              'background_color': backgroundColorHex,
            if (operation == 'change_bg' && _backgroundImageBytes != null)
              'background_image': 'custom',
          },
          operationDate: DateTime.now(),
        );
        final historyId = await MagicMomentDatabase.instance.insertHistory(history);
        await MagicMomentDatabase.instance.updateCurrentState(
          widget.imageId,
          historyId,
          null,
        );

        // Update image in database
        final imageData = await MagicMomentDatabase.instance.getImage(widget.imageId);
        if (imageData != null) {
          final updatedImage = ImageData(
            imageId: imageData.imageId,
            filePath: kIsWeb ? 'memory://image_${widget.imageId}.png' : imageData.filePath,
            fileName: imageData.fileName,
            fileSize: resultBytes.length,
            width: imageData.width,
            height: imageData.height,
            creationDate: imageData.creationDate,
            lastModified: DateTime.now(),
            originalImageId: imageData.originalImageId,
          );
          await MagicMomentDatabase.instance.updateImage(updatedImage);
        }

        setState(() {
          _previewImage = resultBytes;
        });
        widget.onUpdateImage(
          resultBytes,
          action: 'Background $operation',
          operationType: operation,
          parameters: history.operationParameters,
        );
        widget.onApply(resultBytes);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.processingError ?? 'Image processing failed'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error processing image ($operation): $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.error ?? 'Error'}: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _currentOperation = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.6),
        title: Text(localizations?.backgroundEditing ?? 'Background Editing'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onCancel,
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 60),
          Expanded(
            child: _isInitialized
                ? Center(
              child: AspectRatio(
                aspectRatio: _backgroundImage.width / _backgroundImage.height,
                child: Stack(
                  children: [
                    Image.memory(
                      _previewImage ?? widget.image,
                      fit: BoxFit.contain,
                    ),
                    if (_backgroundMode == BackgroundMode.color && _previewImage == null)
                      Container(
                        color: _selectedBackgroundColor,
                      ),
                    if (_backgroundMode == BackgroundMode.image && _backgroundImageBytes != null && _previewImage == null)
                      Image.memory(
                        _backgroundImageBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                  ],
                ),
              ),
            )
                : const Center(child: CircularProgressIndicator()),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            color: Colors.black.withOpacity(0.75),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.image_not_supported,
                      label: localizations?.removeBackground ?? 'Remove Background',
                      operation: 'remove_bg',
                      color: Colors.deepPurpleAccent,
                    ),
                    _buildActionButton(
                      icon: Icons.blur_on,
                      label: localizations?.blurBackground ?? 'Blur Background',
                      operation: 'blur_bg',
                      color: Colors.blueAccent,
                      onLongPress: _selectBlurIntensity,
                    ),
                    _buildActionButton(
                      icon: Icons.palette,
                      label: localizations?.changeBackground ?? 'Change Background',
                      operation: 'change_bg',
                      color: Colors.greenAccent,
                      onLongPress: _showBackgroundOptions,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_isProcessing)
                  Column(
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        _getProcessingText(localizations),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      const LinearProgressIndicator(
                        backgroundColor: Colors.grey,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String operation,
    required Color color,
    VoidCallback? onLongPress,
  }) {
    final isCurrentOperation = _currentOperation == operation;
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          color: isCurrentOperation ? Colors.white : color,
          onPressed: _isProcessing ? null : () => _processImage(operation),
          onLongPress: onLongPress,
          style: IconButton.styleFrom(
            backgroundColor: isCurrentOperation ? color : Colors.transparent,
            padding: const EdgeInsets.all(12),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isCurrentOperation ? Colors.white : Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showBackgroundOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final localizations = AppLocalizations.of(context);
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    localizations?.backgroundOptions ?? 'Background Options',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<BackgroundMode>(
                          title: Row(
                            children: [
                              const Icon(Icons.color_lens, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(localizations?.selectColor ?? 'Use Color',
                                  style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                          value: BackgroundMode.color,
                          groupValue: _backgroundMode,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _backgroundMode = value;
                                _backgroundImageBytes = null;
                              });
                              this.setState(() {
                                _backgroundMode = value;
                                _backgroundImageBytes = null;
                              });
                            }
                          },
                          activeColor: Colors.greenAccent,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<BackgroundMode>(
                          title: Row(
                            children: [
                              const Icon(Icons.image, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(localizations?.selectImage ?? 'Use Image',
                                  style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                          value: BackgroundMode.image,
                          groupValue: _backgroundMode,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _backgroundMode = value;
                                _selectedBackgroundColor = Colors.white;
                              });
                              this.setState(() {
                                _backgroundMode = value;
                                _selectedBackgroundColor = Colors.white;
                              });
                              _pickBackgroundImage();
                            }
                          },
                          activeColor: Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_backgroundMode == BackgroundMode.color)
                        Column(
                          children: [
                            Text(localizations?.currentColor ?? 'Selected Color',
                                style: const TextStyle(color: Colors.white)),
                            const SizedBox(height: 6),
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _selectedBackgroundColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                            const SizedBox(height: 6),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _selectBackgroundColor();
                              },
                              icon: const Icon(Icons.palette),
                              label: Text(localizations?.selectColor ?? 'Change Color'),
                            ),
                          ],
                        ),
                      if (_backgroundMode == BackgroundMode.image && _backgroundImageBytes != null)
                        Column(
                          children: [
                            Text(localizations?.selectedImage ?? 'Selected Image',
                                style: const TextStyle(color: Colors.white)),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.memory(
                                _backgroundImageBytes!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _pickBackgroundImage();
                              },
                              icon: const Icon(Icons.image),
                              label: Text(localizations?.selectImage ?? 'Change Image'),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(localizations?.close ?? 'Close',
                        style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getProcessingText(AppLocalizations? localizations) {
    switch (_currentOperation) {
      case 'remove_bg':
        return localizations?.removingBackground ?? 'Removing Background...';
      case 'blur_bg':
        return localizations?.blurringBackground ?? 'Blurring Background...';
      case 'change_bg':
        return localizations?.changingBackground ?? 'Changing Background...';
      default:
        return localizations?.processingImage ?? 'Processing Image...';
    }
  }
}

enum BackgroundMode { color, image }