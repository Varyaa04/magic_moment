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
  bool _isActive = true; // Track page activity

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

  Future<Uint8List?> _getBackgroundMask(
      {int attempt = 1, int maxAttempts = 3}) async {
    try {
      final apiKey = dotenv.env['CLIPDROP_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('ClipDrop API key is not configured in .env file');
      }

      debugPrint(
          'Sending mask request (attempt $attempt) to ${widget.apiEndpoint}');
      final request =
      http.MultipartRequest('POST', Uri.parse(widget.apiEndpoint));
      request.headers['x-api-key'] = apiKey;
      request.files.add(http.MultipartFile.fromBytes(
        'image_file',
        widget.image,
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

    final blurredImage = img.gaussianBlur(original, radius: blurValue.round());
    final resultImage =
    img.Image(width: original.width, height: original.height);
    for (int y = 0; y < original.height; y++) {
      for (int x = 0; x < original.width; x++) {
        final maskPixel = mask.getPixelSafe(x, y);
        if (maskPixel.a > 128) {
          resultImage.setPixel(x, y, original.getPixel(x, y));
        } else {
          resultImage.setPixel(x, y, blurredImage.getPixel(x, y));
        }
      }
    }
    return img.encodePng(resultImage);
  }

  Future<void> _processImage() async {
    if (_isProcessing || !_isInitialized || !_isActive) return;
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
      final maskImage = img.decodeImage(maskBytes);
      if (maskImage == null) {
        throw Exception('Failed to decode mask image');
      }

      if (originalImage.width != maskImage.width ||
          originalImage.height != maskImage.height) {
        throw Exception('Original image and mask dimensions do not match');
      }

      final isolateParams = {
        'original': Uint8List.fromList(img.encodePng(originalImage)),
        'mask': Uint8List.fromList(img.encodePng(maskImage)),
        'blurValue': _blurValue,
      };

      final resultBytes = await compute(_applyBlurIsolate, isolateParams);

      final resultImageDecoded = img.decodeImage(resultBytes);
      if (resultImageDecoded == null) {
        throw Exception('Failed to decode result image');
      }

      final processedBytes =
      Uint8List.fromList(img.encodePng(resultImageDecoded));
      if (processedBytes.isEmpty) {
        throw Exception('Failed to encode blurred image');
      }

      debugPrint('Processed image size: ${processedBytes.length} bytes');
      if (!mounted || !_isActive) {
        debugPrint('BlurBackgroundPage not mounted or inactive after processing');
        return;
      }

      String? snapshotPath;
      List<int>? snapshotBytes;
      if (!kIsWeb) {
        final tempDir = await Directory.systemTemp.createTemp();
        snapshotPath =
        '${tempDir.path}/blur_bg_${DateTime.now().millisecondsSinceEpoch}.png';
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
        debugPrint('BlurBackgroundPage not mounted or inactive before callbacks');
        return;
      }

      setState(() {
        _processedImage = processedBytes;
        historyStack.add({
          'image': processedBytes,
          'action': _getActionName(AppLocalizations.of(context)),
          'operationType': 'blur_bg',
          'parameters': {'blur_value': _blurValue, 'historyId': historyId},
        });
        historyIndex++;
      });

      if (mounted && _isActive) {
        widget.onApply(processedBytes);
        await widget.onUpdateImage(
          processedBytes,
          action: _getActionName(AppLocalizations.of(context)),
          operationType: 'blur_bg',
          parameters: {'blur_value': _blurValue, 'historyId': historyId},
        );
        if (mounted && _isActive) {
          debugPrint('Navigating back from BlurBackgroundPage after apply');
          widget.onCancel();
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
                      debugPrint('Navigating back from BlurBackgroundPage on error');
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
            debugPrint('Navigating back from BlurBackgroundPage via cancel');
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
            color: _processedImage != null && !_isProcessing
                ? Colors.green
                : Colors.grey[700],
            size: isDesktop ? 28 : 24,
          ),
          onPressed: _processedImage != null &&
              !_isProcessing &&
              mounted &&
              _isActive
              ? () {
            if (mounted && _isActive) {
              widget.onApply(_processedImage!);
              debugPrint(
                  'Navigating back from BlurBackgroundPage via apply');
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
      height: isDesktop ? 120 : 100,
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
      child: Column(
        children: [
          SliderRow(
            title: localizations?.blurIntensity ?? 'Blur Intensity',
            value: _blurValue,
            min: 5,
            max: 50,
            divisions: 45,
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
          const SizedBox(height: 8),
          Center(
            child: ElevatedButton.icon(
              onPressed: _isProcessing || !_isActive ? null : _processImage,
              icon: Icon(
                Icons.blur_on,
                color: Colors.white,
                size: isDesktop ? 24 : 20,
              ),
              label: Text(
                _getActionName(localizations),
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
            fontSize: isDesktop ? 16 : 14,
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
              fontSize: isDesktop ? 16 : 14,
            ),
          ),
        ),
      ],
    );
  }
}