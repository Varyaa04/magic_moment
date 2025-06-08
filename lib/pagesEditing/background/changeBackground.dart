import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:MagicMoment/themeWidjets/colorPicker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:MagicMoment/database/editHistory.dart';
import 'package:MagicMoment/database/magicMomentDatabase.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'base_background_editor.dart';
import 'package:image/image.dart' as img;

class ChangeBackgroundPage extends BaseBackgroundEditor {
  const ChangeBackgroundPage({
    required super.image,
    required super.imageId,
    required super.onCancel,
    required super.onApply,
    required super.onUpdateImage,
    super.key,
  }) : super(
    apiEndpoint: 'https://clipdrop-api.co/replace-background/v1',
    operationName: 'change_bg',
    defaultTitle: 'Change Background',
  );

  @override
  State<ChangeBackgroundPage> createState() => _ChangeBackgroundPageState();
}

class _ChangeBackgroundPageState
    extends BaseBackgroundEditorState<ChangeBackgroundPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  Uint8List? _currentImage;
  Uint8List? _selectedBackground;
  Color? _selectedColor;
  String? _backgroundSource;
  String? _errorMessage;
  bool _isInitialized = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  @override
  void dispose() {
    _isActive = false;
    debugPrint('Disposing ChangeBackgroundPage');
    super.dispose();
  }

  Future<void> _initialize() async {
    debugPrint(
        'Initializing ChangeBackgroundPage with image size: ${widget.image.length} bytes');
    try {
      if (widget.image.isEmpty) {
        throw Exception(
            AppLocalizations.of(context)?.noImages ?? 'No image provided');
      }
      historyStack.add({
        'image': widget.image,
        'action': _getActionName(AppLocalizations.of(context)),
        'operationType': 'init',
        'parameters': {},
      });
      historyIndex = 0;
      if (mounted) {
        setState(() {
          _currentImage = widget.image;
          _isInitialized = true;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Initialization error: $e\n$stackTrace');
      if (mounted) {
        _handleError(e.toString());
      }
    }
  }

  @override
  String _getActionName(AppLocalizations? localizations) {
    return localizations?.changeBackground ?? 'Change Background';
  }

  @override
  String _getLoadingText(AppLocalizations? localizations) {
    return localizations?.changingBackground ?? 'Changing background...';
  }

  @override
  String _getActionTooltip(AppLocalizations? localizations) {
    return localizations?.changeBackgroundTitle ?? 'Change background';
  }

  Future<void> _showSourceSelectionDialog() async {
    final localizations = AppLocalizations.of(context);

    if (!mounted || !_isActive) {
      debugPrint('ChangeBackgroundPage not mounted or inactive, aborting dialog');
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            localizations?.selectBackgroundSource ?? 'Select Background Source',
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.blue),
                  title: Text(
                    localizations?.deviceGallery ?? 'Device Gallery',
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    if (mounted && _isActive) {
                      Navigator.pop(context);
                      _getImageFromGallery();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.color_lens, color: Colors.blue),
                  title: Text(
                    localizations?.solidColor ?? 'Solid Color',
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    if (mounted && _isActive) {
                      Navigator.pop(context);
                      _showColorPicker();
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (mounted && _isActive) {
                  debugPrint('Canceling source selection dialog');
                  Navigator.pop(context);
                }
              },
              child: Text(
                localizations?.cancel ?? 'Cancel',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showColorPicker() async {
    final localizations = AppLocalizations.of(context);
    Color selectedColor = Colors.white;

    if (!mounted || !_isActive) {
      debugPrint('ChangeBackgroundPage not mounted or inactive, aborting color picker');
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            localizations?.selectColor ?? 'Select Color',
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ColorPicker(
                  pickerColor: selectedColor,
                  onColorChanged: (color) => selectedColor = color,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (mounted && _isActive) {
                  debugPrint('Canceling color picker dialog');
                  Navigator.pop(context);
                }
              },
              child: Text(
                localizations?.cancel ?? 'Cancel',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
            TextButton(
              onPressed: () {
                if (mounted && _isActive) {
                  Navigator.pop(context);
                  _applySolidColor(selectedColor);
                }
              },
              child: Text(
                localizations?.apply ?? 'Apply',
                style: const TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Uint8List> _createSolidColorImage(Color color) async {
    final originalImage = img.decodeImage(widget.image);
    if (originalImage == null) {
      throw Exception('Failed to decode original image');
    }

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint()..color = color;

    final width = originalImage.width.toDouble();
    final height = originalImage.height.toDouble();

    canvas.drawRect(ui.Rect.fromLTWH(0, 0, width, height), paint);
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    image.dispose();
    picture.dispose();

    if (byteData == null || byteData.lengthInBytes == 0) {
      throw Exception('Failed to generate solid color image');
    }

    return byteData.buffer.asUint8List();
  }

  Future<void> _applySolidColor(Color color) async {
    if (_isProcessing || !_isInitialized || !_isActive || !mounted) {
      debugPrint('ChangeBackgroundPage not ready for _applySolidColor');
      return;
    }

    try {
      final solidColorImage = await _createSolidColorImage(color);

      // Validate the generated image
      final codec = await ui.instantiateImageCodec(solidColorImage);
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (frame.image.width == 0 || frame.image.height == 0) {
        throw Exception('Generated solid color image is invalid');
      }
      frame.image.dispose();

      setState(() {
        _selectedBackground = solidColorImage;
        _backgroundSource = 'color';
        _selectedColor = color;
        _errorMessage = null;
      });
      await _applyBackground();
    } catch (e, stackTrace) {
      debugPrint('Error creating solid color image: $e\n$stackTrace');
      _handleError('Failed to create solid color background: $e');
    }
  }

  Future<void> _getImageFromGallery() async {
    if (!mounted || !_isActive) {
      debugPrint('ChangeBackgroundPage not mounted or inactive, aborting gallery pick');
      return;
    }

    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted && _isActive) {
        final bytes = await pickedFile.readAsBytes();
        if (bytes.isNotEmpty) {
          // Validate gallery image
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          codec.dispose();
          if (frame.image.width == 0 || frame.image.height == 0) {
            throw Exception('Selected gallery image is invalid');
          }
          frame.image.dispose();

          setState(() {
            _selectedBackground = bytes;
            _backgroundSource = 'gallery';
            _selectedColor = null;
            _errorMessage = null;
          });
          await _applyBackground();
        } else {
          throw Exception('Empty image data from gallery');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error picking gallery image: $e\n$stackTrace');
      if (mounted) {
        _handleError(e.toString());
      }
    }
  }

  Future<void> _applyBackground() async {
    if (_isProcessing || _selectedBackground == null || !_isInitialized || !_isActive || !mounted) {
      debugPrint('ChangeBackgroundPage not ready for _applyBackground');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final resultBytes = await _processImage();
      debugPrint('Processed image size: ${resultBytes.length} bytes');

      String? snapshotPath;
      List<int>? snapshotBytes;
      if (!kIsWeb) {
        final tempDir = await Directory.systemTemp.createTemp();
        snapshotPath =
        '${tempDir.path}/change_bg_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(snapshotPath);
        await file.writeAsBytes(resultBytes);
        if (!await file.exists()) {
          throw Exception('Failed to save snapshot to file: $snapshotPath');
        }
      } else {
        snapshotBytes = resultBytes;
      }

      final history = EditHistory(
        imageId: widget.imageId,
        operationType: 'change_bg',
        operationParameters: {
          'background_source': _backgroundSource ?? 'unknown',
          if (_backgroundSource == 'color' && _selectedColor != null)
            'color': _selectedColor!.value.toRadixString(16),
        },
        operationDate: DateTime.now(),
        snapshotPath: snapshotPath,
        snapshotBytes: snapshotBytes,
      );
      final db = MagicMomentDatabase.instance;
      final historyId = await db.insertHistory(history);
      if (historyId == null || historyId <= 0) {
        throw Exception('Failed to save edit history to database');
      }

      if (!mounted || !_isActive) {
        debugPrint('ChangeBackgroundPage not mounted or inactive before callbacks');
        return;
      }

      setState(() {
        _currentImage = resultBytes;
        historyStack.add({
          'image': resultBytes,
          'action': _getActionName(AppLocalizations.of(context)),
          'operationType': 'change_bg',
          'parameters': {
            'background_source': _backgroundSource ?? 'unknown',
            if (_backgroundSource == 'color' && _selectedColor != null)
              'color': _selectedColor!.value.toRadixString(16),
            'historyId': historyId,
          },
        });
        historyIndex++;
      });

      if (mounted && _isActive) {
        widget.onApply(resultBytes);
        await widget.onUpdateImage(
          resultBytes,
          action: _getActionName(AppLocalizations.of(context)),
          operationType: 'change_bg',
          parameters: {
            'background_source': _backgroundSource ?? 'unknown',
            if (_backgroundSource == 'color' && _selectedColor != null)
              'color': _selectedColor!.value.toRadixString(16),
            'historyId': historyId,
          },
        );
        if (mounted && _isActive) {
          debugPrint('Navigating back from ChangeBackgroundPage after apply');
          widget.onCancel();
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error applying background: $e\n$stackTrace');
      if (mounted) {
        _handleError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<Uint8List> _processImage(
      {int attempt = 1, int maxAttempts = 3}) async {
    if (_selectedBackground == null) {
      throw Exception('No background selected');
    }

    try {
      final apiKey = dotenv.env['CLIPDROP_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('ClipDrop API key is not configured in .env file');
      }

      debugPrint(
          'Sending request (attempt $attempt) to ${widget.apiEndpoint} with foreground size: ${widget.image.length} bytes, background size: ${_selectedBackground!.length} bytes');
      final request =
      http.MultipartRequest('POST', Uri.parse(widget.apiEndpoint));
      request.headers['x-api-key'] = apiKey;
      request.files.add(http.MultipartFile.fromBytes(
        'image_file',
        widget.image,
        filename: 'image.png',
      ));
      request.files.add(http.MultipartFile.fromBytes(
        'background_file',
        _selectedBackground!,
        filename: 'background.png',
      ));

      final response =
      await request.send().timeout(const Duration(seconds: 30));
      debugPrint(
          'API response status: ${response.statusCode}, content length: ${response.contentLength}');
      final responseBody = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        if (responseBody.bodyBytes.isEmpty) {
          throw Exception('Empty response from ClipDrop API');
        }
        final decodedImage = img.decodeImage(responseBody.bodyBytes);
        if (decodedImage == null) {
          throw Exception('Invalid image data returned from ClipDrop API');
        }
        return responseBody.bodyBytes;
      } else if (response.statusCode == 429 && attempt < maxAttempts) {
        await Future.delayed(Duration(seconds: attempt * 2));
        return _processImage(attempt: attempt + 1, maxAttempts: maxAttempts);
      } else {
        throw Exception(
            'ClipDrop API error ${response.statusCode}: ${responseBody.body}');
      }
    } catch (e, stackTrace) {
      debugPrint(
          'Error processing background change (attempt $attempt): $e\n$stackTrace');
      if (attempt < maxAttempts) {
        await Future.delayed(Duration(seconds: attempt * 2));
        return _processImage(attempt: attempt + 1, maxAttempts: maxAttempts);
      }
      rethrow;
    }
  }

  void _handleError(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black.withOpacity(0.8),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  localizations?.loading ?? 'Loading...',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black.withOpacity(0.8),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (mounted && _isActive) {
                      debugPrint('Navigating back from ChangeBackgroundPage on error');
                      widget.onCancel();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    localizations?.close ?? 'Close',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(theme, localizations),
                Expanded(
                  child: _currentImage != null
                      ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(
                        _currentImage!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint(
                              'Error displaying processed image: $error');
                          return Center(
                            child: Text(
                              localizations?.invalidImage ??
                                  'Failed to load image',
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        },
                      ),
                      if (_selectedBackground != null)
                        Opacity(
                          opacity: 0.5,
                          child: Image.memory(
                            _selectedBackground!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint(
                                  'Error displaying background image: $error');
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                    ],
                  )
                      : Image.memory(
                    widget.image,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint(
                          'Error displaying original image: $error');
                      return Center(
                        child: Text(
                          localizations?.invalidImage ??
                              'Failed to load image',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    },
                  ),
                ),
                _buildBottomPanel(theme, localizations),
              ],
            ),
            if (_isProcessing)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        _getLoadingText(localizations),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme, AppLocalizations? localizations) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.7),
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.close,
          color: Colors.redAccent,
          size: isDesktop ? 28 : 24,
        ),
        onPressed: () {
          if (mounted && _isActive) {
            debugPrint('Navigating back from ChangeBackgroundPage via cancel');
            _isActive = false;
            widget.onCancel();
          }
        },
        tooltip: localizations?.cancel ?? 'Cancel',
      ),
      title: Text(
        _getActionName(localizations),
        style: TextStyle(
          color: Colors.white,
          fontSize: isDesktop ? 20 : 16,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.undo,
            color: historyIndex > 0 && !_isProcessing
                ? Colors.white
                : Colors.grey[700],
            size: isDesktop ? 28 : 24,
          ),
          onPressed: historyIndex > 0 && !_isProcessing && _isActive ? undo : null,
          tooltip: localizations?.undo ?? 'Undo',
        ),
        IconButton(
          icon: Icon(
            Icons.check,
            color: _currentImage != null &&
                _currentImage != widget.image &&
                !_isProcessing
                ? Colors.green
                : Colors.grey[700],
            size: isDesktop ? 28 : 24,
          ),
          onPressed: _currentImage != null &&
              _currentImage != widget.image &&
              !_isProcessing &&
              mounted &&
              _isActive
              ? () {
            if (mounted && _isActive) {
              widget.onApply(_currentImage!);
              debugPrint(
                  'Navigating back from ChangeBackgroundPage via apply');
              _isActive = false;
              widget.onCancel();
            }
          }
              : null,
          tooltip: localizations?.apply ?? 'Apply',
        ),
      ],
    );
  }

  Widget _buildBottomPanel(ThemeData theme, AppLocalizations? localizations) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    return Container(
      height: isDesktop ? 100 : 80,
      padding: EdgeInsets.symmetric(
        vertical: isDesktop ? 12 : 6,
        horizontal: isDesktop ? 24 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: _isProcessing || !_isActive ? null : _showSourceSelectionDialog,
          icon: Icon(
            Icons.image,
            color: Colors.white,
            size: isDesktop ? 24 : 20,
          ),
          label: Text(
            localizations?.selectBackground ?? 'Select Background',
            style: TextStyle(
              color: Colors.white,
              fontSize: isDesktop ? 14 : 12,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.withOpacity(0.7),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 16 : 12,
              vertical: isDesktop ? 12 : 8,
            ),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }
}