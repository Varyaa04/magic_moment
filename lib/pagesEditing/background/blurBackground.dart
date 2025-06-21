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
import '../../themeWidjets/helpTooltip.dart';
import '../editPage.dart';
import 'base_background_editor.dart';

class BlurBackgroundPage extends BaseBackgroundEditor {
  const BlurBackgroundPage({
    required super.image,
    required super.imageId,
    required super.onCancel,
    required super.onApply,
    required super.onUpdateImage,
    super.key,
  }) : super(
          apiEndpoint: 'https://clipdrop-api.co/remove-background/v1',
          operationName: 'blur_bg',
          defaultTitle: 'Blur Background',
        );

  @override
  State<BlurBackgroundPage> createState() => _BlurBackgroundState();
}

class _BlurBackgroundState
    extends BaseBackgroundEditorState<BlurBackgroundPage> {
  double _blurValue = 10.0;
  bool _isProcessing = false;
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
    debugPrint('Disposing BlurBackgroundPage');
    super.dispose();
  }

  Future<void> _initialize() async {
    debugPrint(
        'Initializing BlurBackgroundPage with image size: ${widget.image.length} bytes');
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
    return localizations?.blurBackground ?? 'Blur Background';
  }

  @override
  String _getLoadingText(AppLocalizations? localizations) {
    return localizations?.blurringBackground ?? 'Blurring background...';
  }

  @override
  String _getActionTooltip(AppLocalizations? localizations) {
    return localizations?.blurBackgroundTitle ?? 'Blur background';
  }

  Future<Uint8List?> _resizeImage(Uint8List imageData,
      {int maxWidth = 1080, bool preserveTransparency = false}) async {
    try {
      final decoded = img.decodeImage(imageData);
      if (decoded == null) {
        debugPrint('Failed to decode image in _resizeImage');
        return null;
      }
      final resized = img.copyResize(decoded,
          width: maxWidth,
          maintainAspect: true,
          interpolation: img.Interpolation.nearest);
      final compressed = preserveTransparency
          ? img.encodePng(resized, level: 6)
          : img.encodeJpg(resized, quality: 80);
      debugPrint('Resized image: size=${compressed.length} bytes');
      return Uint8List.fromList(compressed);
    } catch (e, stackTrace) {
      debugPrint('Error resizing image: $e\nStack: $stackTrace');
      return null;
    }
  }

  Future<Uint8List?> _getBackgroundMask(
      {int attempt = 1, int maxAttempts = 5}) async {
    try {
      final apiKey = dotenv.env['CLIPDROP_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('ClipDrop API key is not configured in .env file');
      }

      final resizedImage = await _resizeImage(widget.image,
          maxWidth: 1024, preserveTransparency: true);
      if (resizedImage == null) {
        throw Exception('Failed to resize image for API call');
      }

      debugPrint(
          'Sending mask request (attempt $attempt) to ${widget.apiEndpoint} with image size: ${resizedImage.length} bytes');
      final request =
          http.MultipartRequest('POST', Uri.parse(widget.apiEndpoint));
      request.headers['x-api-key'] = apiKey;
      request.files.add(http.MultipartFile.fromBytes(
        'image_file',
        resizedImage,
        filename: 'image.png',
      ));

      final response =
          await request.send().timeout(const Duration(seconds: 30));
      debugPrint(
          'Mask API response status: ${response.statusCode}, content length: ${response.contentLength}');
      final responseBody = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        if (responseBody.bodyBytes.isEmpty) {
          throw Exception('Empty mask response from ClipDrop API');
        }
        if (!kIsWeb) {
          final tempDir = await Directory.systemTemp.createTemp();
          final maskPath =
              '${tempDir.path}/mask_${DateTime.now().millisecondsSinceEpoch}.png';
          await File(maskPath).writeAsBytes(responseBody.bodyBytes);
          debugPrint('Saved mask to $maskPath for inspection');
        }
        return responseBody.bodyBytes;
      } else if (response.statusCode == 429 && attempt < maxAttempts) {
        await Future.delayed(Duration(seconds: attempt * 2));
        return _getBackgroundMask(
            attempt: attempt + 1, maxAttempts: maxAttempts);
      } else {
        throw Exception(
            'ClipDrop API error ${response.statusCode}: ${responseBody.body}');
      }
    } catch (e, stackTrace) {
      debugPrint(
          'Error getting background mask (attempt $attempt): $e\n$stackTrace');
      if (attempt < maxAttempts) {
        await Future.delayed(Duration(seconds: attempt * 2));
        return _getBackgroundMask(
            attempt: attempt + 1, maxAttempts: maxAttempts);
      }
      rethrow;
    }
  }

  static Future<Uint8List> _applyBlurIsolate(
      Map<String, dynamic> params) async {
    final originalBytes = params['original'] as Uint8List;
    final maskBytes = params['mask'] as Uint8List;
    final blurValue = params['blurValue'] as double;

    final original = img.decodeImage(originalBytes);
    final mask = img.decodeImage(maskBytes);

    if (original == null || mask == null) {
      throw Exception('Failed to decode images in isolate');
    }

    // Ensure mask matches original image dimensions
    img.Image resizedMask = mask;
    if (original.width != mask.width || original.height != mask.height) {
      debugPrint(
          'Resizing mask to match original dimensions: ${original.width}x${original.height}');
      resizedMask = img.copyResize(
        mask,
        width: original.width,
        height: original.height,
        interpolation: img.Interpolation.nearest,
      );
    }

    // Binarize mask: foreground (subject) = 255, background = 0
    final binaryMask = img.Image.from(resizedMask);
    int foregroundPixels = 0;
    int backgroundPixels = 0;
    for (int y = 0; y < binaryMask.height; y++) {
      for (int x = 0; x < binaryMask.width; x++) {
        final pixel = binaryMask.getPixelSafe(x, y);
        final isForeground = pixel.a > 128;
        binaryMask.setPixel(
            x,
            y,
            isForeground
                ? img.ColorRgba8(255, 255, 255, 255)
                : img.ColorRgba8(0, 0, 0, 0));
        if (isForeground) {
          foregroundPixels++;
        } else {
          backgroundPixels++;
        }
      }
    }
    debugPrint(
        'Mask stats: foreground pixels = $foregroundPixels, background pixels = $backgroundPixels');

    // Create blurred version of the entire image
    final blurredImage = img.gaussianBlur(original, radius: blurValue.round());

    // Start with the original image (sharp foreground)
    final resultImage = img.Image.from(original);

    // Replace background pixels with blurred version
    for (int y = 0; y < resultImage.height; y++) {
      for (int x = 0; x < resultImage.width; x++) {
        final maskPixel = binaryMask.getPixelSafe(x, y);
        if (maskPixel.a == 0) {
          // Background
          final blurredPixel = blurredImage.getPixelSafe(x, y);
          resultImage.setPixel(x, y, blurredPixel);
        }
      }
    }

    final encoded = img.encodePng(resultImage);
    debugPrint('Blur applied, result image size: ${encoded.length} bytes');
    return Uint8List.fromList(encoded);
  }

  Future<void> _processImage() async {
    if (_isProcessing || !_isInitialized || !_isActive) {
      debugPrint('Cannot process image: already processing or not initialized');
      return;
    }
    if (!mounted) {
      debugPrint('BlurBackgroundPage not mounted, aborting _processImage');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final originalImage = img.decodeImage(widget.image);
      if (originalImage == null) {
        throw Exception('Failed to decode original image');
      }

      final maskBytes = await _getBackgroundMask();
      if (maskBytes == null || maskBytes.isEmpty) {
        throw Exception('Failed to generate background mask');
      }

      final isolateParams = {
        'original': widget.image,
        'mask': maskBytes,
        'blurValue': _blurValue,
      };

      final resultBytes = await compute(_applyBlurIsolate, isolateParams);

      if (resultBytes.isEmpty) {
        throw Exception('Failed to encode blurred image');
      }

      debugPrint('Processed image size: ${resultBytes.length} bytes');
      if (!mounted || !_isActive) {
        debugPrint(
            'BlurBackgroundPage not mounted or inactive after processing');
        return;
      }

      String? snapshotPath;
      List<int>? snapshotBytes;
      if (!kIsWeb) {
        final tempDir = await Directory.systemTemp.createTemp();
        snapshotPath =
            '${tempDir.path}/blur_bg_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(snapshotPath);
        await file.writeAsBytes(resultBytes);
        if (!await file.exists()) {
          throw Exception('Failed to save snapshot to file: $snapshotPath');
        }
      } else {
        snapshotBytes = resultBytes;
      }

      final historyEntry = EditHistory(
        imageId: widget.imageId,
        operationType: 'blur_bg',
        operationParameters: {'blur_value': _blurValue},
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
        debugPrint(
            'BlurBackgroundPage not mounted or inactive before callbacks');
        return;
      }

      setState(() {
        _processedImage = resultBytes;
        historyStack.add({
          'image': resultBytes,
          'action': _getActionName(AppLocalizations.of(context)),
          'operationType': 'blur_bg',
          'parameters': {'blur_value': _blurValue, 'historyId': historyId},
        });
        historyIndex++;
      });

      if (mounted && _isActive) {
        debugPrint('Calling onApply and onUpdateImage');
        widget.onApply(resultBytes);
        await widget.onUpdateImage(
          resultBytes,
          action: _getActionName(AppLocalizations.of(context)),
          operationType: 'blur_bg',
          parameters: {'blur_value': _blurValue, 'historyId': historyId},
        );
        if (mounted && _isActive) {
          debugPrint('Navigating back to BackgroundPanel with result');
          _isActive = false;
          Navigator.pop(context, resultBytes);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error processing blur: $e\n$stackTrace');
      if (mounted) {
        _handleError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
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
                      debugPrint('Navigating back to BackgroundPanel on error');
                      Navigator.pop(context);
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
                  child: _processedImage != null
                      ? Image.memory(
                          _processedImage!,
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

  Widget _buildBottomPanel(ThemeData theme, AppLocalizations? localizations) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isDesktop ? 8 : 4,
        horizontal: isDesktop ? 16 : 10,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderRow(
            title: localizations?.blurIntensity ?? 'Blur Intensity',
            value: _blurValue,
            min: 5,
            max: 30,
            divisions: 25,
            onChanged: _isProcessing || !_isActive
                ? null
                : (value) {
                    if (mounted) {
                      setState(() {
                        _blurValue = value;
                      });
                    }
                  },
            isDesktop: isDesktop,
          ),
          const SizedBox(height: 6),
          Center(
            child: ElevatedButton.icon(
              onPressed: _isProcessing || !_isActive ? null : _processImage,
              icon: Icon(
                Icons.blur_on,
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
          ),
        ],
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
        HelpTooltip(
          message: localizations?.blurBackgroundHelp ??
              'Adjust the blur intensity using the slider.\n'
                  'Higher values create stronger blur effect.\n'
                  'Press Apply when you\'re satisfied with the result.',
          iconSize: isDesktop ? 28 : 24,
        ),
        IconButton(
          icon: Icon(
            Icons.undo,
            color: historyIndex > 0 && !_isProcessing
                ? Colors.white
                : Colors.grey[700],
            size: isDesktop ? 28 : 24,
          ),
          onPressed:
              historyIndex > 0 && !_isProcessing && _isActive ? undo : null,
          tooltip: localizations?.undo ?? 'Undo',
        ),
        IconButton(
          icon: Icon(
            Icons.check,
            color: _processedImage != null && !_isProcessing
                ? Colors.green
                : Colors.grey[700],
            size: isDesktop ? 28 : 24,
          ),
          onPressed:
              _processedImage != null && !_isProcessing && mounted && _isActive
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
}

class SliderRow extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double>? onChanged;
  final bool isDesktop;

  const SliderRow({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    this.onChanged,
    required this.isDesktop,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: isDesktop ? 14 : 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: Colors.blue,
            inactiveColor: Colors.grey[700],
            label: value.round().toString(),
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            value.round().toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: isDesktop ? 14 : 12,
            ),
          ),
        ),
      ],
    );
  }
}
