import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image/image.dart' as img;
import 'package:MagicMoment/database/editHistory.dart';
import 'package:MagicMoment/database/magicMomentDatabase.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'package:MagicMoment/themeWidjets/image_picker_helper.dart';
import 'package:image_picker/image_picker.dart';
import '../editPage.dart';
import 'base_background_editor.dart';

class ChangeBackgroundPage extends BaseBackgroundEditor {
  const ChangeBackgroundPage({
    required super.image,
    required super.imageId,
    required super.onCancel,
    required super.onApply,
    required super.onUpdateImage,
    super.key,
  }) : super(
    apiEndpoint: 'https://clipdrop-api.co/remove-background/v1',
    operationName: 'change_bg',
    defaultTitle: 'Change Background',
  );

  @override
  State<ChangeBackgroundPage> createState() => _ChangeBackgroundPageState();
}

class _ChangeBackgroundPageState extends BaseBackgroundEditorState<ChangeBackgroundPage> {
  Uint8List? _backgroundImage;
  bool _isLoading = false;
  Uint8List? _processedImage;
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

  Future<Uint8List?> _resizeImage(Uint8List imageData, {int maxWidth = 1080, bool preserveTransparency = false}) async {
    try {
      final decoded = img.decodeImage(imageData);
      if (decoded == null) {
        debugPrint('Failed to decode image in _resizeImage');
        return null;
      }
      final resized = img.copyResize(decoded, width: maxWidth, maintainAspect: true);
      final compressed = preserveTransparency ? img.encodePng(resized, level: 6) : img.encodeJpg(resized, quality: 80);
      debugPrint('Resized image: size=${compressed.length} bytes');
      return Uint8List.fromList(compressed);
    } catch (e, stackTrace) {
      debugPrint('Error resizing image: $e\nStack: $stackTrace');
      return null;
    }
  }

  Future<void> _initialize() async {
    debugPrint('Initializing ChangeBackgroundPage with image size: ${widget.image.length} bytes');
    try {
      if (widget.image.isEmpty) {
        throw Exception(AppLocalizations.of(context)?.noImages ?? 'No image provided');
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

  Future<Uint8List?> _getBackgroundMask(Uint8List imageBytes, {int attempt = 1, int maxAttempts = 5}) async {
    try {
      final apiKey = dotenv.env['CLIPDROP_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('ClipDrop API key is not configured in .env file');
      }

      final resizedImage = await _resizeImage(imageBytes, maxWidth: 1024, preserveTransparency: true);
      if (resizedImage == null) {
        throw Exception('Failed to resize image for API call');
      }

      debugPrint('Sending mask request (attempt $attempt) to ${widget.apiEndpoint} with image size: ${resizedImage.length} bytes');
      final request = http.MultipartRequest('POST', Uri.parse(widget.apiEndpoint));
      request.headers['x-api-key'] = apiKey;
      request.files.add(http.MultipartFile.fromBytes(
        'image_file',
        resizedImage,
        filename: 'image.png',
      ));

      final response = await request.send().timeout(const Duration(seconds: 30));
      debugPrint('Mask API response status: ${response.statusCode}, content length: ${response.contentLength}');
      final responseBody = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        if (responseBody.bodyBytes.isEmpty) {
          throw Exception('Empty mask response from ClipDrop API');
        }
        return responseBody.bodyBytes;
      } else if (response.statusCode == 429 && attempt < maxAttempts) {
        debugPrint('Rate limit hit, retrying after ${attempt * 2} seconds...');
        await Future.delayed(Duration(seconds: attempt * 2));
        return _getBackgroundMask(imageBytes, attempt: attempt + 1, maxAttempts: maxAttempts);
      } else {
        throw Exception('ClipDrop API error: ${response.statusCode}: ${responseBody.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting background mask (attempt $attempt): $e\n$stackTrace');
      if (attempt < maxAttempts) {
        await Future.delayed(Duration(seconds: attempt * 2));
        return _getBackgroundMask(imageBytes, attempt: attempt + 1, maxAttempts: maxAttempts);
      }
      rethrow;
    }
  }

  Future<void> _pickBackgroundImage() async {
    if (_isLoading || !_isActive) return;
    try {
      final bytes = await ImagePickerHelper.pickImage(source: ImageSource.gallery);
      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.noImages ?? 'No image selected'),
            ),
          );
        }
        return;
      }
      if (mounted) {
        setState(() {
          _backgroundImage = bytes;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error picking background image: $e\n$stackTrace');
      if (mounted) {
        _handleError(e.toString());
      }
    }
  }

  static Future<Uint8List> _applyBackgroundIsolate(Map<String, dynamic> params) async {
    // Decode input data
    final originalBytes = params['original'] as Uint8List;
    final maskBytes = params['mask'] as Uint8List;
    final backgroundBytes = params['background'] as Uint8List?;

    final original = img.decodeImage(originalBytes);
    final mask = img.decodeImage(maskBytes);

    if (original == null || mask == null) {
      throw Exception('Failed to decode original or mask image');
    }

    // Ensure mask matches original image dimensions
    img.Image resizedMask = mask;
    if (original.width != mask.width || original.height != mask.height) {
      debugPrint('Resizing mask to match original dimensions: ${original.width}x${original.height}');
      resizedMask = img.copyResize(mask, width: original.width, height: original.height);
    }

    // Create background image
    img.Image background;
    if (backgroundBytes != null) {
      final decodedBackground = img.decodeImage(backgroundBytes);
      if (decodedBackground == null) {
        throw Exception('Failed to decode background image');
      }
      background = img.copyResize(decodedBackground, width: original.width, height: original.height);
    } else {
      throw Exception('No background image provided');
    }

    // Create result image
    final resultImage = img.Image(width: original.width, height: original.height);

    // Apply mask
    for (int y = 0; y < original.height; y++) {
      for (int x = 0; x < original.width; x++) {
        final maskPixel = resizedMask.getPixelSafe(x, y);
        final alpha = maskPixel.a; // Use raw alpha value (0-255)
        if (alpha > 0) {
          // Foreground: keep original pixel
          resultImage.setPixel(x, y, original.getPixel(x, y));
        } else {
          // Background: use background pixel
          resultImage.setPixel(x, y, background.getPixel(x, y));
        }
      }
    }
    return img.encodePng(resultImage);
  }

  Future<void> _processImage() async {
    if (_isLoading || !_isInitialized || !_isActive || _backgroundImage == null) {
      debugPrint('Cannot process image: missing background or not initialized');
      return;
    }
    if (!mounted) {
      debugPrint('ChangeBackgroundPage not mounted, aborting _processImage');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final originalImage = img.decodeImage(widget.image);
      if (originalImage == null) {
        throw Exception('Failed to decode original image');
      }

      final maskBytes = await _getBackgroundMask(widget.image);
      if (maskBytes == null || maskBytes.isEmpty) {
        throw Exception('Failed to generate background mask');
      }
      final maskImage = img.decodeImage(maskBytes);
      if (maskImage == null) {
        throw Exception('Failed to decode mask image');
      }

      img.Image resizedMask = maskImage;
      if (originalImage.width != maskImage.width || originalImage.height != maskImage.height) {
        debugPrint('Mask dimensions (${maskImage.width}x${maskImage.height}) do not match original (${originalImage.width}x${originalImage.height}), resizing mask...');
        resizedMask = img.copyResize(maskImage, width: originalImage.width, height: originalImage.height);
      }

      final isolateParams = {
        'original': widget.image,
        'mask': Uint8List.fromList(img.encodePng(resizedMask)),
        'background': _backgroundImage,
      };

      final resultBytes = await compute(_applyBackgroundIsolate, isolateParams);

      final resultImageDecoded = img.decodeImage(resultBytes);
      if (resultImageDecoded == null) {
        throw Exception('Failed to decode result image');
      }

      final processedBytes = Uint8List.fromList(img.encodePng(resultImageDecoded));
      if (processedBytes.isEmpty) {
        throw Exception('Failed to encode processed image');
      }

      debugPrint('Processed image size: ${processedBytes.length} bytes');

      String? snapshotPath;
      List<int>? snapshotBytes;
      if (!kIsWeb) {
        final tempDir = await Directory.systemTemp.createTemp();
        snapshotPath = '${tempDir.path}/change_bg_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(snapshotPath);
        await file.writeAsBytes(processedBytes);
        if (!await file.exists()) {
          throw Exception('Failed to save snapshot to file: $snapshotPath');
        }
      } else {
        snapshotBytes = processedBytes;
      }

      final historyEntry = EditHistory(
        imageId: widget.imageId,
        operationType: 'change_bg',
        operationParameters: {
          'backgroundType': 'image',
        },
        operationDate: DateTime.now(),
        snapshotPath: snapshotPath,
        snapshotBytes: snapshotBytes,
      );
      final db = MagicMomentDatabase.instance;
      final historyId = await db.insertHistory(historyEntry);
      if (historyId == null || historyId <= 0) {
        throw Exception('Failed to save edit history to database');
      }

      if (!mounted || !_isActive) {
        debugPrint('ChangeBackgroundPage not mounted or inactive after processing');
        return;
      }

      setState(() {
        _processedImage = processedBytes;
        historyStack.add({
          'image': processedBytes,
          'action': _getActionName(AppLocalizations.of(context)),
          'operationType': 'change_bg',
          'parameters': {'historyId': historyId},
        });
        historyIndex++;
      });

      if (mounted && _isActive) {
        debugPrint('Calling onApply and onUpdateImage');
        widget.onApply(processedBytes);
        await widget.onUpdateImage(
          processedBytes,
          action: _getActionName(AppLocalizations.of(context)),
          operationType: 'change_bg',
          parameters: {'historyId': historyId},
        );
        if (mounted && _isActive) {
          debugPrint('Navigating back with result: ${processedBytes.length} bytes');
          _isActive = false;
          Navigator.pop(context, processedBytes);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error processing background change: $e\n$stackTrace');
      if (mounted) {
        _handleError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleError(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _isLoading = false;
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
                      debugPrint('Navigating back to BackgroundPanel on error');
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  child: _processedImage != null
                      ? Image.memory(
                    _processedImage!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Error displaying processed image: $error');
                      return Center(
                        child: Text(
                          localizations?.invalidImage ?? 'Failed to load image',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    },
                  )
                      : Image.memory(
                    widget.image,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Error displaying original image: $error');
                      return Center(
                        child: Text(
                          localizations?.invalidImage ?? 'Failed to load image',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    },
                  ),
                ),
                _buildBottomPanel(theme, localizations),
              ],
            ),
            if (_isLoading)
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
          if (mounted && _isActive)  {
            debugPrint('Navigating back to BackgroundPanel via cancel');
            _isActive = false;
            Navigator.pop(context);
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
    color: historyIndex > 0 && !_isLoading ? Colors.white : Colors.grey[700],
    size: isDesktop ? 28 : 24,
    ),
    onPressed: historyIndex > 0 && !_isLoading && _isActive ? undo : null,
    tooltip: localizations?.undo ?? 'Undo',
    ),
    IconButton(
    icon: Icon(
    Icons.check,
    color: _processedImage != null && !_isLoading ? Colors.green : Colors.grey[700],
    size: isDesktop ? 28 : 24,
    ),
    onPressed: _processedImage != null && !_isLoading && mounted && _isActive
    ? () {
    if (mounted && _isActive) {
    debugPrint('Applying processed image');
    widget.onApply(_processedImage!);
    _isActive = false;
    Navigator.pop(context, _processedImage!);
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
      constraints: BoxConstraints(
        minHeight: isDesktop ? 100 : 80,
        maxHeight: isDesktop ? 100 : 80,
      ),
      padding: EdgeInsets.symmetric(
        vertical: isDesktop ? 8 : 4,
        horizontal: isDesktop ? 20 : 12,
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading || !_isActive ? null : _pickBackgroundImage,
                  icon: Icon(
                    Icons.image,
                    color: Colors.white,
                    size: isDesktop ? 20 : 16,
                  ),
                  label: Text(
                    localizations?.selectBackground ?? 'Select Image',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isDesktop ? 12 : 10,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.withOpacity(0.7),
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 12 : 8,
                      vertical: isDesktop ? 8 : 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ElevatedButton.icon(
              onPressed: _isLoading || !_isActive || _backgroundImage == null ? null : _processImage,
              icon: Icon(
                Icons.check,
                color: Colors.white,
                size: isDesktop ? 20 : 16,
              ),
              label: Text(
                _getActionName(localizations),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isDesktop ? 12 : 10,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.withOpacity(0.7),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 12 : 8,
                  vertical: isDesktop ? 8 : 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}