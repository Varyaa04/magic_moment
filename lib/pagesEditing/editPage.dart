import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:universal_io/io.dart';
import 'package:universal_html/html.dart' as html;
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import '../database/editHistory.dart';
import '../database/editHistoryManager.dart';
import '../database/magicMomentDatabase.dart';
import 'annotation/eraserPanel.dart';
import 'background/backgroundPanel.dart';
import 'effects/effectsPanel.dart';
import 'toolsPanel.dart';
import 'cropPanel.dart';
import 'filters/filtersPanel.dart';
import 'adjustsButtonsPanel.dart';
import 'annotation/drawPanel.dart';
import 'annotation/textEditorPanel.dart';
import 'annotation/emojiPanel.dart';

class EditPage extends StatefulWidget {
  final dynamic imageBytes;
  final int imageId;

  const EditPage({
    super.key,
    required this.imageBytes,
    required this.imageId,
  });

  @override
  _EditPageState createState() => _EditPageState();
}

class EditState {
  final Uint8List image;
  final DateTime timestamp;
  final String description;

  EditState(this.image, this.description) : timestamp = DateTime.now();
}

class _EditPageState extends State<EditPage> {
  final ValueNotifier<Uint8List> _currentImage = ValueNotifier(Uint8List(0));
  late Uint8List _originalImage;
  late EditHistoryManager _historyManager;
  final ValueNotifier<Size> _imageSize = ValueNotifier(Size.zero);
  final ValueNotifier<bool> _isInitialized = ValueNotifier(false);
  final ValueNotifier<bool> _showToolsPanel = ValueNotifier(false);
  final ValueNotifier<String?> _activeTool = ValueNotifier(null);
  final ValueNotifier<int?> _selectedAdjustTool = ValueNotifier(null);
  final ValueNotifier<bool> _isUndoAvailable = ValueNotifier(false);
  final ValueNotifier<bool> _isRedoAvailable = ValueNotifier(false);
  final ValueNotifier<bool> _isProcessing = ValueNotifier(false);
  final ValueNotifier<double> _loadingProgress = ValueNotifier(0.0);
  final List<EditState> _history = [];
  int _currentHistoryIndex = -1;
  final int _maxHistorySteps = 30;
  bool _isHistoryEnabled = true;
  final Map<String, Uint8List> _imageCache = {};
  final Map<int, Uint8List> _webHistorySnapshots = {};
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
// Быстрая инициализация основных переменных
      _currentImage.value = widget.imageBytes is Uint8List
          ? widget.imageBytes as Uint8List
          : Uint8List(0);
      _originalImage = Uint8List.fromList(_currentImage.value);
      _historyManager = EditHistoryManager(
        db: MagicMomentDatabase.instance,
        imageId: widget.imageId,
      );

// Параллельная загрузка истории и инициализация изображения
      await Future.wait([
        _loadHistory(),
        _initializeImage(),
      ]);
    } catch (e) {
      debugPrint('Initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize: $e')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _currentImage.dispose();
    _imageSize.dispose();
    _isInitialized.dispose();
    _showToolsPanel.dispose();
    _activeTool.dispose();
    _selectedAdjustTool.dispose();
    _isUndoAvailable.dispose();
    _isRedoAvailable.dispose();
    _isProcessing.dispose();
    _loadingProgress.dispose();
    if (kIsWeb) {
      _webHistorySnapshots.clear();
    } else {
      _historyManager.db.getAllHistoryForImage(widget.imageId).then((history) async {
        for (var entry in history) {
          if (entry.snapshotPath != null) {
            final file = File(entry.snapshotPath!);
            if (await file.exists()) {
              await file.delete();
            }
          }
        }
      });
    }
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      await _historyManager.loadHistory();
      _updateUndoRedoState();
    } catch (e) {
      debugPrint('Error loading history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppLocalizations.of(context)?.error ?? 'Error'}: Failed to load edit history.'),
          ),
        );
      }
    }
  }

  Future<void> _initializeImage() async {
    if (!mounted) return;

    setState(() => _isProcessing.value = true);
    _loadingProgress.value = 0.1;

    try {
      Uint8List bytes;

      if (widget.imageBytes is Uint8List) {
        bytes = widget.imageBytes;
      } else {
        throw Exception('Unsupported image type');
      }

      if (bytes.isEmpty) {
        throw Exception('Empty image data');
      }

      _loadingProgress.value = 0.3;

// Оптимизированное декодирование изображения
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, (ui.Image img) {
        completer.complete(img);
      });

      _loadingProgress.value = 0.5;

      final image = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Image decoding timeout'),
      );

      _loadingProgress.value = 0.8;

      _currentImage.value = bytes;
      _originalImage = Uint8List.fromList(bytes);
      _imageSize.value = Size(image.width.toDouble(), image.height.toDouble());
      _isInitialized.value = true;

      image.dispose();
      _resetHistory();

      _loadingProgress.value = 1.0;
    } catch (e) {
      debugPrint('Error initializing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading image: $e')),
        );
        _isInitialized.value = true;
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing.value = false);
      }
    }
  }

  Uint8List _compressImage(Uint8List imageData) {
    final decoded = img.decodeImage(imageData);
    if (decoded == null) return imageData;
    return Uint8List.fromList(img.encodeJpg(decoded, quality: 80)); // Сжатие до 80%
  }

  void _updateUndoRedoState() {
    _isUndoAvailable.value = _historyManager.canUndo;
    _isRedoAvailable.value = _historyManager.canRedo;
  }

  Future<void> _initPage() async {
    _originalImage = Uint8List.fromList(widget.imageBytes);
    Uint8List resized = await compute(_resizeImage, _originalImage);
    _currentImage.value = resized;

    _historyManager = EditHistoryManager(
      db: MagicMomentDatabase.instance,
      imageId: widget.imageId,
    );

    await _historyManager.loadHistory();
    _isInitialized.value = true;
  }

  static Uint8List _resizeImage(Uint8List imageData) {
    final decoded = img.decodeImage(imageData);
    if (decoded == null) return imageData;
    final resized = img.copyResize(decoded, width: 1080);
    return Uint8List.fromList(img.encodeJpg(resized));
  }

  void _resetHistory() {
    final localizations = AppLocalizations.of(context);
    _history.clear();
    _webHistorySnapshots.clear();
    _imageCache.clear();
    _addHistoryState(localizations?.create ?? 'Original image');
    _currentHistoryIndex = 0;
  }

  void _undo() async {
    if (!_isUndoAvailable.value) return;

    setState(() => _isProcessing.value = true);
    try {
      final entry = await _historyManager.undo();
      if (entry == null) return;

      Uint8List bytes;
      if (kIsWeb && _webHistorySnapshots.containsKey(_currentHistoryIndex - 1)) {
        bytes = _webHistorySnapshots[_currentHistoryIndex - 1]!;
      } else if (entry.snapshotPath != null) {
        final file = File(entry.snapshotPath!);
        if (await file.exists()) {
          bytes = await _resizeImage(await file.readAsBytes());
        } else {
          throw Exception('History file not found');
        }
      } else {
        throw Exception('No snapshot available');
      }

      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, (ui.Image img) {
        completer.complete(img);
      });
      final image = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Image decoding timeout'),
      );
      final newSize = Size(image.width.toDouble(), image.height.toDouble());
      image.dispose();

      _currentImage.value = bytes;
      _imageSize.value = newSize;
      _currentHistoryIndex--;
      _historyManager.setCurrentIndex(_currentHistoryIndex);
      _updateUndoRedoState();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error undoing action: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing.value = false);
    }
  }

  void _redo() async {
    if (!_isRedoAvailable.value) return;

    setState(() => _isProcessing.value = true);
    try {
      final entry = await _historyManager.redo();
      if (entry == null) return;

      Uint8List bytes;
      if (kIsWeb &&
          _webHistorySnapshots.containsKey(_currentHistoryIndex + 1)) {
        bytes = _webHistorySnapshots[_currentHistoryIndex + 1]!;
      } else if (entry.snapshotPath != null) {
        final file = File(entry.snapshotPath!);
        if (await file.exists()) {
          bytes = await _resizeImage(await file.readAsBytes());
        } else {
          throw Exception('History file not found');
        }
      } else {
        throw Exception('No snapshot available');
      }

      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, (ui.Image img) {
        completer.complete(img);
      });
      final image = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Image decoding timeout'),
      );
      final newSize = Size(image.width.toDouble(), image.height.toDouble());
      image.dispose();

      _currentImage.value = bytes;
      _imageSize.value = newSize;
      _currentHistoryIndex++;
      _updateUndoRedoState();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error redoing action: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing.value = false);
    }
  }

  void _addHistoryState(String description) async {
    if (!_isHistoryEnabled) return;

    String? snapshotPath;
    if (!kIsWeb) {
      final tempDir = await Directory.systemTemp.createTemp();
      snapshotPath = '${tempDir.path}/snapshot_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(snapshotPath);
      await file.writeAsBytes(_currentImage.value);
    } else {
      _webHistorySnapshots[_history.length] = Uint8List.fromList(_currentImage.value);
    }

    await _historyManager.addOperation(
      context: context, // Pass context
      operationType: description,
      parameters: {},
      snapshotPath: snapshotPath,
    );

    _history.add(EditState(Uint8List.fromList(_currentImage.value), description));
    if (_history.length > _maxHistorySteps) {
      _history.removeAt(0);
      if (kIsWeb) {
        _webHistorySnapshots.remove(0);
      }
    }
    _currentHistoryIndex = _history.length - 1;
    _updateUndoRedoState();
  }

  Future<void> _saveImage() async {
    final localizations = AppLocalizations.of(context);
    if (!_isInitialized.value || !mounted) return;

    final selectedFormat = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations?.save ?? 'Save Image'),
        content: Text(localizations?.chooseFormat ?? 'Choose image format:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('PNG'),
            child: Text(localizations?.pngTr ?? 'PNG (with transparency)'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('JPEG'),
            child: const Text('JPEG'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(localizations?.cancel ?? 'Cancel'),
          ),
        ],
      ),
    );

    if (selectedFormat == null) return;

    setState(() => _isProcessing.value = true);
    try {
      if (kIsWeb) {
        await _downloadImageWeb(_currentImage.value, format: selectedFormat);
      } else {
        await _saveImageToGallery(_currentImage.value, format: selectedFormat);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations?.saveSuccess ?? 'Image saved successfully'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localizations?.error ?? 'Error'}: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing.value = false);
    }
  }

  Future<void> _saveImageToGallery(Uint8List bytes, {required String format}) async {
    final localizations = AppLocalizations.of(context);
    try {
      final tempDir = await Directory.systemTemp.createTemp();
      final extension = format.toLowerCase();
      final imagePath = '${tempDir.path}/image_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final file = File(imagePath);

      if (format == 'JPEG') {
        final decodedImage = img.decodeImage(bytes);
        if (decodedImage == null) {
          throw Exception(localizations?.errorDecode ?? 'Failed to decode image');
        }
        final jpegBytes = img.encodeJpg(decodedImage, quality: 90);
        await file.writeAsBytes(jpegBytes);
      } else {
        await file.writeAsBytes(bytes);
      }

      const channel = MethodChannel('gallery_saver');
      final result = await channel.invokeMethod('saveImage', imagePath);
      if (result != true) {
        throw Exception(localizations?.errorSaveGallery ?? 'Failed to save image to gallery');
      }
    } catch (e) {
      debugPrint('Error saving image: $e');
      rethrow;
    }
  }

  Future<void> _downloadImageWeb(Uint8List bytes, {required String format}) async {
    final localizations = AppLocalizations.of(context);
    try {
      Uint8List formattedBytes;
      String mimeType;

      if (format == 'JPEG') {
        final decodedImage = img.decodeImage(bytes);
        if (decodedImage == null) {
          throw Exception(localizations?.errorDecode ?? 'Failed to decode image');
        }
        formattedBytes = img.encodeJpg(decodedImage, quality: 90);
        mimeType = 'image/jpeg';
      } else {
        formattedBytes = bytes;
        mimeType = 'image/png';
      }

      final blob = html.Blob([formattedBytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'image_${DateTime.now().millisecondsSinceEpoch}.${format.toLowerCase()}')
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      debugPrint('Error downloading image: $e');
      throw Exception(localizations?.errorDownload ?? 'Failed to download image: $e');
    }
  }

// In editPage.dart, _updateImage (replace around line 500)
  Future<void> _updateImage(
      Uint8List newImage, {
        String? action,
        String? operationType,
        Map<String, dynamic>? parameters,
      }) async {
    if (!mounted || listEquals(_currentImage.value, newImage)) return;

    setState(() => _isProcessing.value = true);
    try {
      final bytes = await _resizeImage(newImage);
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, (ui.Image img) {
        completer.complete(img);
      });
      final image = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception(AppLocalizations.of(context)?.errorDecode ?? 'Image decoding timeout'),
      );
      final newSize = Size(image.width.toDouble(), image.height.toDouble());
      image.dispose(); // Освобождаем ui.Image

      _currentImage.value = bytes;
      _imageSize.value = newSize;

      if (action != null && operationType != null && parameters != null) {
        String? snapshotPath;
        List<int>? snapshotBytes;
        if (!kIsWeb) {
          final tempDir = await Directory.systemTemp.createTemp();
          snapshotPath = '${tempDir.path}/snapshot_${DateTime.now().millisecondsSinceEpoch}.png';
          final file = File(snapshotPath);
          await file.writeAsBytes(bytes);
        } else {
          snapshotBytes = Uint8List.fromList(bytes);
        }

        await _historyManager.addOperation(
          context: context, // Pass context
          operationType: operationType,
          parameters: parameters,
          snapshotPath: snapshotPath,
          snapshotBytes: snapshotBytes,
        );
        _history.add(EditState(Uint8List.fromList(bytes), operationType));
        if (_history.length > _maxHistorySteps) {
          _history.removeAt(0);
          if (kIsWeb) {
            _webHistorySnapshots.remove(0);
          } else {
            // Use _historyManager's history instead of _history
            final managerHistory = await _historyManager.db.getAllHistoryForImage(widget.imageId);
            if (managerHistory.isNotEmpty && managerHistory.first.snapshotPath != null) {
              final file = File(managerHistory.first.snapshotPath!);
              if (await file.exists()) {
                await file.delete();
              }
            }
          }
        }
        _currentHistoryIndex = _history.length - 1;
        _updateUndoRedoState();
      }
    } catch (e) {
      debugPrint('Error updating image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)?.error ?? 'Error'}: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing.value = false);
    }
  }

  void _handleToolSelected(String tool) {
    _activeTool.value = tool;
    _showToolsPanel.value = false;
    _selectedAdjustTool.value = null;
  }

  void _closeToolPanel() {
    _activeTool.value = null;
    _selectedAdjustTool.value = null;
  }



  Future<void> _confirmBackNavigation() async {
    final localizations = AppLocalizations.of(context);

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(localizations?.back ?? 'Go Back'),
          content: Text(localizations?.unsavedChangesWarning ??
              'Are you sure you want to go back? All unsaved changes will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(localizations?.cancel ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(localizations?.yes ?? 'Yes'),
            ),
          ],
        );
      },
    );

    if (shouldLeave == true && mounted) {
      Navigator.pop(context);
    }
  }

  void _showEditHistory() async {
    final history =
        await _historyManager.db.getAllHistoryForImage(widget.imageId);
    final localizations = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.3,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  localizations?.history ?? 'Edit History',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(12),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return FutureBuilder<Uint8List>(
                      future: kIsWeb
                          ? Future.value(_webHistorySnapshots[index])
                          : File(item.snapshotPath!).readAsBytes(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox(
                            width: 100,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return GestureDetector(
                          onTap: () async {
                            Navigator.pop(context);
                            final imageBytes = snapshot.data!;
                            await _updateImage(imageBytes);
                            _currentHistoryIndex = index;
                            _historyManager.setCurrentIndex(index);
                            _updateUndoRedoState();
                          },
                          child: Column(
                            children: [
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                  image: DecorationImage(
                                    image: MemoryImage(snapshot.data!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: 100,
                                child: Text(
                                  item.operationType,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final iconSize = isMobile ? 24.0 : 32.0;
        final padding = isMobile ? 8.0 : 16.0;

        return Scaffold(
          body: Stack(
            children: [
              Container(
                color: Colors.black,
                child: Column(
                  children: [
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: padding),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: _confirmBackNavigation,
                              icon: Icon(Icons.arrow_back, size: iconSize),
                              color: Colors.white,
                              tooltip: localizations?.back ?? 'Back',
                            ),
                            Row(
                              children: [
                                ValueListenableBuilder(
                                  valueListenable: _isUndoAvailable,
                                  builder: (context, isAvailable, _) =>
                                      IconButton(
                                    icon: Icon(Icons.undo, size: iconSize),
                                    color: isAvailable
                                        ? Colors.white
                                        : Colors.grey,
                                    onPressed: isAvailable ? _undo : null,
                                    tooltip: localizations?.undo ?? 'Undo',
                                  ),
                                ),
                                ValueListenableBuilder(
                                  valueListenable: _isRedoAvailable,
                                  builder: (context, isAvailable, _) =>
                                      IconButton(
                                    icon: Icon(Icons.redo, size: iconSize),
                                    color: isAvailable
                                        ? Colors.white
                                        : Colors.grey,
                                    onPressed: isAvailable ? _redo : null,
                                    tooltip: localizations?.redo ?? 'Redo',
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.history),
                                  color: Colors.white,
                                  onPressed: _showEditHistory,
                                  tooltip: localizations?.history ?? 'History',
                                ),
                                IconButton(
                                  onPressed: _saveImage,
                                  icon: Icon(Icons.save_alt, size: iconSize),
                                  color: Colors.white,
                                  tooltip: localizations?.save ?? 'Save',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ValueListenableBuilder(
                        valueListenable: _isInitialized,
                        builder: (context, isInitialized, _) {
                          if (!isInitialized) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ValueListenableBuilder(
                                    valueListenable: _loadingProgress,
                                    builder: (context, progress, _) {
                                      return SizedBox(
                                        width: 200,
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          backgroundColor: Colors.grey[800],
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(height: padding),
                                  Text(
                                    localizations?.loading ??
                                        'Loading image...',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                ],
                              ),
                            );
                          }
                          return ValueListenableBuilder(
                            valueListenable: _currentImage,
                            builder: (context, image, _) {
                              if (image.isEmpty) {
                                return Center(
                                  child: Text(
                                    localizations?.error ??
                                        'Failed to load image',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                );
                              }
                              return ValueListenableBuilder(
                                valueListenable: _imageSize,
                                builder: (context, size, _) =>
                                    InteractiveViewer(
                                  minScale: 0.5,
                                  maxScale: 3.0,
                                  child: Center(
                                    child: SizedBox(
                                      width: size.width,
                                      height: size.height,
                                      child: Image.memory(
                                        image,
                                        gaplessPlayback: true,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Text(
                                          '${localizations?.error ?? 'Error loading image'}: $error',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Container(
                      height: isMobile ? 80 : 100,
                      color: Colors.black.withOpacity(0.7),
                      child: FutureBuilder<List<EditHistory>>(
                        future: _historyManager.db
                            .getAllHistoryForImage(widget.imageId),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final history = snapshot.data!;
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.all(padding),
                            itemCount: history.length,
                            itemBuilder: (context, index) {
                              final item = history[index];
                              return FutureBuilder<Uint8List>(
                                future: kIsWeb
                                    ? Future.value(_webHistorySnapshots[index])
                                    : File(item.snapshotPath!).readAsBytes(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const SizedBox(
                                      width: 80,
                                      child: Center(
                                          child: CircularProgressIndicator()),
                                    );
                                  }
                                  return GestureDetector(
                                    onTap: () async {
                                      final imageBytes = snapshot.data!;
                                      await _updateImage(imageBytes);
                                      _currentHistoryIndex = index;
                                      _historyManager.setCurrentIndex(index);
                                      _updateUndoRedoState();
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _currentHistoryIndex == index
                                              ? Colors.blue
                                              : Colors.white,
                                          width: 2,
                                        ),
                                        image: DecorationImage(
                                          image: MemoryImage(snapshot.data!),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Container(
                                          color: Colors.black54,
                                          padding: const EdgeInsets.all(4),
                                          child: Text(
                                            item.operationType,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    ValueListenableBuilder(
                      valueListenable: _showToolsPanel,
                      builder: (context, show, _) => show
                          ? Container(
                              constraints: BoxConstraints(
                                  maxHeight: isMobile ? 80 : 100),
                              child: ToolsPanel(
                                  onToolSelected: _handleToolSelected),
                            )
                          : Padding(
                              padding: EdgeInsets.all(padding),
                              child: IconButton(
                                icon: Icon(
                                  show ? Icons.close : Icons.edit,
                                  color: Colors.white,
                                  size: iconSize,
                                ),
                                onPressed: () {
                                  _showToolsPanel.value = !show;
                                },
                                tooltip: show
                                    ? localizations?.cancel ?? 'Close'
                                    : localizations?.edit ?? 'Edit',
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              ValueListenableBuilder(
                valueListenable: _activeTool,
                builder: (context, tool, _) {
                  if (tool == null) return const SizedBox.shrink();
                  switch (tool) {
                    case 'crop':
                      return CropPanel(
                        image: _currentImage.value,
                        onCancel: _closeToolPanel,
                        onApply: (croppedImage) {
                          _updateImage(croppedImage,
                              action: 'crop',
                              operationType: 'Crop',
                              parameters: {});
                          _closeToolPanel();
                        },
                        onUpdateImage: _updateImage,
                        imageId: widget.imageId,
                      );
                    case 'filters':
                      return FiltersPanel(
                        imageBytes: _currentImage.value,
                        onCancel: _closeToolPanel,
                        onApply: (filteredImage) {
                          _updateImage(filteredImage,
                              action: 'filter',
                              operationType: 'Filter',
                              parameters: {});
                          _closeToolPanel();
                        },
                        onUpdateImage: _updateImage,
                        imageId: widget.imageId,
                      );
                    case 'adjust':
                      return AdjustPanel(
                        image: _currentImage.value,
                        imageId: widget.imageId,
                        onImageChanged: (value) {
                          _updateImage(value,
                              action: 'adjust',
                              operationType: 'Adjust',
                              parameters: {});
                          _closeToolPanel();
                        },
                        onClose: _closeToolPanel,
                        onUpdateImage: _updateImage,
                      );
                    case 'draw':
                      return DrawPanel(
                        image: _currentImage.value,
                        onCancel: _closeToolPanel,
                        onApply: (drawnImage) {
                          _updateImage(drawnImage,
                              action: 'draw',
                              operationType: 'Draw',
                              parameters: {});
                          _closeToolPanel();
                        },
                        onUpdateImage: _updateImage,
                        imageId: widget.imageId,
                      );
                    case 'text':
                      return TextEditorPanel(
                        image: _currentImage.value,
                        imageId: widget.imageId,
                        onCancel: _closeToolPanel,
                        onApply: (textImage) {
                          _updateImage(textImage,
                              action: 'text',
                              operationType: 'Text',
                              parameters: {});
                          _closeToolPanel();
                        },
                        onUpdateImage: _updateImage,
                      );
                    case 'emoji':
                      return EmojiPanel(
                        image: _currentImage.value,
                        imageId: widget.imageId,
                        onCancel: _closeToolPanel,
                        onApply: (emojiImage) {
                          _updateImage(emojiImage,
                              action: 'emoji',
                              operationType: 'Emoji',
                              parameters: {});
                          _closeToolPanel();
                        },
                        onUpdateImage: _updateImage,
                      );
                    case 'effects':
                      return EffectsPanel(
                        image: _currentImage.value,
                        imageId: widget.imageId,
                        onCancel: _closeToolPanel,
                        onApply: (effectsImage) {
                          _updateImage(effectsImage,
                              action: 'effects',
                              operationType: 'Effects',
                              parameters: {});
                          _closeToolPanel();
                        },
                      );
                    case 'eraser':
                      return EraserPanel(
                        image: _currentImage.value,
                        imageId: widget.imageId,
                        onCancel: _closeToolPanel,
                        onApply: (eraserImage) {
                          _updateImage(eraserImage,
                              action: 'eraser',
                              operationType: 'Eraser',
                              parameters: {});
                          _closeToolPanel();
                        },
                        onUpdateImage: _updateImage,
                      );
                    case 'background':
                      return BackgroundPanel(
                        image: _currentImage.value,
                        imageId: widget.imageId,
                        onCancel: _closeToolPanel,
                        onApply: (bgImage) {
                          _updateImage(bgImage,
                              action: 'background',
                              operationType: 'Background',
                              parameters: {});
                          _closeToolPanel();
                        },
                        onUpdateImage: _updateImage,
                      );
                    default:
                      return const SizedBox.shrink();
                  }
                },
              ),
              ValueListenableBuilder(
                valueListenable: _isProcessing,
                builder: (context, isProcessing, _) {
                  return isProcessing
                      ? Container(
                          color: Colors.black.withOpacity(0.5),
                          child: const Center(
                            child:
                                CircularProgressIndicator(color: Colors.white),
                          ),
                        )
                      : const SizedBox.shrink();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
