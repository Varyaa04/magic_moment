import 'dart:io';
import 'dart:typed_data';
import 'package:MagicMoment/pagesEditing/editPage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:MagicMoment/database/editHistory.dart';
import 'package:MagicMoment/database/magicMomentDatabase.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'package:image/image.dart' as img;
import 'base_background_editor.dart';

class RemoveBackgroundPage extends BaseBackgroundEditor {
  const RemoveBackgroundPage({
    required super.image,
    required super.imageId,
    required super.onCancel,
    required super.onApply,
    required super.onUpdateImage,
    super.key,
  }) : super(
          apiEndpoint: 'https://clipdrop-api.co/remove-background/v1',
          operationName: 'remove_bg',
          defaultTitle: 'Remove Background',
        );

  @override
  State<RemoveBackgroundPage> createState() => _RemoveBackgroundPageState();
}

class _RemoveBackgroundPageState
    extends BaseBackgroundEditorState<RemoveBackgroundPage> {
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
    debugPrint('Disposing RemoveBackgroundPage');
    super.dispose();
  }

  Future<Uint8List?> _resizeImage(Uint8List imageData,
      {int maxWidth = 1080, bool preserveTransparency = false}) async {
    try {
      final decoded = img.decodeImage(imageData);
      if (decoded == null) {
        debugPrint('Не удалось декодировать изображение в _resizeImage');
        return null;
      }
      final resized =
          img.copyResize(decoded, width: maxWidth, maintainAspect: true);
      final compressed = preserveTransparency
          ? img.encodePng(resized, level: 6)
          : img.encodeJpg(resized, quality: 80);
      debugPrint(
          'Измененный размер изображения: размер=${compressed.length} байт');
      return Uint8List.fromList(compressed);
    } catch (e, stackTrace) {
      debugPrint('Ошибка изменения размера изображения: $e\nСтек: $stackTrace');
      return null;
    }
  }

  Future<void> _initialize() async {
    debugPrint(
        'Initializing RemoveBackgroundPage with image size: ${widget.image.length} bytes');
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
    return localizations?.removeBackground ?? 'Remove Background';
  }

  @override
  String _getLoadingText(AppLocalizations? localizations) {
    return localizations?.removingBackground ?? 'Removing background...';
  }

  @override
  String _getActionTooltip(AppLocalizations? localizations) {
    return localizations?.removeBackgroundTitle ?? 'Remove background';
  }

  Future<Uint8List?> _callApi(Uint8List imageBytes, {int attempt = 1, int maxAttempts = 3}) async {
    try {
      final apiKey = dotenv.env['CLIPDROP_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('ClipDrop API key is not configured in .env file');
      }

      final resizedImage = await _resizeImage(imageBytes, maxWidth: 1024, preserveTransparency: true);
      if (resizedImage == null) {
        throw Exception('Failed to resize image for API call');
      }

      debugPrint('Sending request (attempt $attempt) to ${widget.apiEndpoint} with image size: ${resizedImage.length} bytes');
      final request = http.MultipartRequest('POST', Uri.parse(widget.apiEndpoint));
      request.headers['x-api-key'] = apiKey;
      request.files.add(http.MultipartFile.fromBytes(
        'image_file',
        resizedImage,
        filename: 'image.png',
      ));

      final response = await request.send().timeout(const Duration(seconds: 30));
      debugPrint('API response status: ${response.statusCode}, content length: ${response.contentLength}');
      final responseBody = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        if (responseBody.bodyBytes.isEmpty) {
          throw Exception('Empty response from ClipDrop API');
        }
        final decodedImage = img.decodeImage(responseBody.bodyBytes);
        if (decodedImage == null) {
          throw Exception('Invalid image data returned from ClipDrop API');
        }
        // Проверяем наличие альфа-канала
        if (!decodedImage.hasAlpha) {
          debugPrint('Warning: Returned image does not have an alpha channel');
        }
        return responseBody.bodyBytes;
      } else if (response.statusCode == 429 && attempt < maxAttempts) {
        debugPrint('Rate limit hit, retrying after ${attempt * 2} seconds...');
        await Future.delayed(Duration(seconds: attempt * 2));
        return _callApi(imageBytes, attempt: attempt + 1, maxAttempts: maxAttempts);
      } else {
        throw Exception('ClipDrop API error ${response.statusCode}: ${responseBody.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('API error (attempt $attempt): $e\n$stackTrace');
      if (attempt < maxAttempts) {
        await Future.delayed(Duration(seconds: attempt * 2));
        return _callApi(imageBytes, attempt: attempt + 1, maxAttempts: maxAttempts);
      }
      rethrow;
    }
  }

  Future<void> _processImage() async {
    if (_isLoading || !_isInitialized || !_isActive) {
      debugPrint('Cannot process image: already processing or not initialized');
      return;
    }
    if (!mounted) {
      debugPrint('RemoveBackgroundPage not mounted, aborting _processImage');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final processedBytes = await _callApi(widget.image);
      if (processedBytes == null) {
        throw Exception('Failed to process image');
      }

      String? snapshotPath;
      List<int>? snapshotBytes;
      if (!kIsWeb) {
        final tempDir = await Directory.systemTemp.createTemp();
        snapshotPath =
            '${tempDir.path}/remove_bg_${DateTime.now().millisecondsSinceEpoch}.png';
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
        operationType: 'remove_bg',
        operationParameters: {},
        operationDate: DateTime.now(),
        snapshotPath: snapshotPath,
        snapshotBytes: snapshotBytes,
      );
      final db = MagicMomentDatabase.instance;
      final historyId = await db.insertHistory(historyEntry);
      if (historyId == null || historyId <= 0) {
        debugPrint('Failed to save edit history to database');
        throw Exception('Failed to save edit history to database');
      }

      if (!mounted || !_isActive) {
        debugPrint(
            'RemoveBackgroundPage not mounted or inactive after processing');
        return;
      }

      setState(() {
        _processedImage = processedBytes;
        historyStack.add({
          'image': processedBytes,
          'action': _getActionName(AppLocalizations.of(context)),
          'operationType': 'remove_bg',
          'parameters': {'historyId': historyId},
        });
        historyIndex++;
        debugPrint('Processed image has alpha: ${img.decodeImage(processedBytes)?.hasAlpha}');
      });

      if (mounted && _isActive) {
        debugPrint('Calling onApply and onUpdateImage');
        widget.onApply(processedBytes);
        await widget.onUpdateImage(
          processedBytes,
          action: _getActionName(AppLocalizations.of(context)),
          operationType: 'remove_bg',
          parameters: {'historyId': historyId},
        );
        if (mounted && _isActive) {
          debugPrint(
              'Navigating back to BackgroundPanel with result: ${processedBytes.length} bytes');
          _isActive = false;
          Navigator.pop(context, processedBytes);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error processing background removal: $e\n$stackTrace');
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
    debugPrint('Handling error: $message');
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
                  child: Container(
                    color: Colors.transparent, // Явно прозрачный контейнер
                    child: _processedImage != null
                        ? Image.memory(
                      _processedImage!,
                      fit: BoxFit.contain,
                      color: Colors.transparent,
                      colorBlendMode: BlendMode.dst,
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
                      color: Colors.transparent,
                      colorBlendMode: BlendMode.dst,
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
        IconButton(
          icon: Icon(
            Icons.undo,
            color: historyIndex > 0 && !_isLoading
                ? Colors.white
                : Colors.grey[700],
            size: isDesktop ? 28 : 24,
          ),
          onPressed: historyIndex > 0 && !_isLoading && _isActive ? undo : null,
          tooltip: localizations?.undo ?? 'Undo',
        ),
        IconButton(
          icon: Icon(
            Icons.check,
            color: _processedImage != null && !_isLoading
                ? Colors.green
                : Colors.grey[700],
            size: isDesktop ? 28 : 24,
          ),
          onPressed:
              _processedImage != null && !_isLoading && mounted && _isActive
                  ? () {
                      if (mounted) {
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
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: _isLoading || !_isActive ? null : _processImage,
          icon: Icon(
            Icons.delete,
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
            backgroundColor: Colors.red.withOpacity(0.7),
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
    );
  }
}
