import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'package:MagicMoment/pagesEditing/annotation/eraserPanel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, listEquals;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:universal_html/html.dart' as html;
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../database/editHistory.dart';
import '../database/magicMomentDatabase.dart';
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
  late Uint8List _currentImage;
  late Uint8List _originalImage;
  late EditHistoryManager _historyManager;
  Size _imageSize = Size.zero;
  bool _isInitialized = false;
  bool _showToolsPanel = false;
  String? _activeTool;
  int? _selectedAdjustTool;

  final List<EditState> _history = [];
  int _currentHistoryIndex = -1;
  final int _maxHistorySteps = 30;
  bool _isHistoryEnabled = true;
  bool _isUndoAvailable = false;
  bool _isRedoAvailable = false;

  @override
  void initState() {
    super.initState();
    _currentImage = widget.imageBytes is File
        ? Uint8List(0)
        : widget.imageBytes as Uint8List;
    _originalImage = Uint8List.fromList(_currentImage);
    _historyManager = EditHistoryManager(
      db: magicMomentDatabase.instance,
      imageId: widget.imageId,
    );
    _initializeImage();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    await _historyManager.loadHistory();
    _updateUndoRedoState();
  }

  void _updateUndoRedoState() {
    setState(() {
      _isUndoAvailable = _historyManager.canUndo;
      _isRedoAvailable = _historyManager.canRedo;
    });
  }

  Future<void> _loadImageFromHistory() async {
    final path = await _historyManager.getCurrentSnapshotPath();
    if (path != null) {
      setState(() {
        _currentImage = File(path) as Uint8List;
      });
    }
  }


  void _showEditHistory() async {
    final history = await _historyManager.db.getAllHistoryForImage(widget.imageId);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return FutureBuilder<Uint8List>(
                future: File(item.snapshotPath!).readAsBytes(),
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
                      _updateImage(imageBytes);
                    },
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 2),
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
                            style: const TextStyle(color: Colors.white, fontSize: 12),
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
        );
      },
    );
  }


  Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1080,
        minHeight: 1080,
        quality: 85,
      );
      return result;
    } catch (e) {
      debugPrint('Compression error: $e');
      return bytes;
    }
  }

  Future<void> _initializeImage() async {
    try {
      Uint8List bytes;

      if (widget.imageBytes is File) {
        final file = widget.imageBytes as File;
        bytes = await file.readAsBytes();
      } else if (widget.imageBytes is Uint8List) {
        bytes = widget.imageBytes as Uint8List;
      } else {
        throw Exception('Unsupported image type');
      }

      // Compress large images
      if (bytes.length > 2 * 1024 * 1024) {
        bytes = await _compressImage(bytes);
      }

      // Load image dimensions
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, (ui.Image img) {
        completer.complete(img);
      });
      final ui.Image image = await completer.future;
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      image.dispose();

      if (mounted) {
        setState(() {
          _currentImage = bytes;
          _originalImage = Uint8List.fromList(bytes);
          _isInitialized = true;
        });
      }

      _resetHistory();
      debugPrint('Initialized image: ${_imageSize.width}x${_imageSize.height}');
    } catch (e) {
      debugPrint('Error initializing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load image: ${e.toString()}')),
        );
      }
    }
  }

  void _resetHistory() {
    _history.clear();
    _addHistoryState('Initial image');
    _currentHistoryIndex = 0;
  }

  void _addHistoryState(String description) {
    if (!_isHistoryEnabled) return;

    if (_currentHistoryIndex < _history.length - 1) {
      _history.removeRange(_currentHistoryIndex + 1, _history.length);
    }

    if (_history.length >= _maxHistorySteps) {
      _history.removeAt(0);
      _currentHistoryIndex--;
    }

    _history.add(EditState(Uint8List.fromList(_currentImage), description));
    _currentHistoryIndex = _history.length - 1;
    _updateUndoRedoState();
  }

  void _undo() async {
    if (!_isUndoAvailable) return;

    final entry = await _historyManager.undo();
    if (entry != null && entry.snapshotPath != null) {
      final file = File(entry.snapshotPath!);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        // Update image size for undo
        final completer = Completer<ui.Image>();
        ui.decodeImageFromList(bytes, (ui.Image img) {
          completer.complete(img);
        });
        final ui.Image image = await completer.future;
        final newSize = Size(image.width.toDouble(), image.height.toDouble());
        image.dispose();

        setState(() {
          _currentImage = bytes;
          _imageSize = newSize;
        });
      }
    }

    _updateUndoRedoState();
  }

  void _redo() async {
    if (!_isRedoAvailable) return;

    final entry = await _historyManager.redo();
    if (entry != null && entry.snapshotPath != null) {
      final file = File(entry.snapshotPath!);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        // Update image size for redo
        final completer = Completer<ui.Image>();
        ui.decodeImageFromList(bytes, (ui.Image img) {
          completer.complete(img);
        });
        final ui.Image image = await completer.future;
        final newSize = Size(image.width.toDouble(), image.height.toDouble());
        image.dispose();

        setState(() {
          _currentImage = bytes;
          _imageSize = newSize;
        });
      }
    }

    _updateUndoRedoState();
  }


  void _updateImage(Uint8List newImage, {String? action, String? operationType, Map<String, dynamic>? parameters}) async {
    if (!mounted || listEquals(_currentImage, newImage)) return;

    //обновляем размер фото
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(newImage, (ui.Image img) {
      completer.complete(img);
    });
    final ui.Image image = await completer.future;
    final newSize = Size(image.width.toDouble(), image.height.toDouble());
    image.dispose();

    setState(() {
      _currentImage = newImage;
      _imageSize = newSize;
    });

    if (action != null && operationType != null && parameters != null) {
      final tempDir = await getTemporaryDirectory();
      final snapshotPath = '${tempDir.path}/snapshot_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(snapshotPath);
      await file.writeAsBytes(newImage);

      await _historyManager.addOperation(
        operationType: operationType,
        parameters: parameters,
        snapshotPath: snapshotPath,
      );

      _updateUndoRedoState();
    }
  }

  void _handleToolSelected(String tool) {
    setState(() {
      _activeTool = tool;
      _showToolsPanel = false;
      _selectedAdjustTool = null;
    });
  }

  void _closeToolPanel() {
    setState(() {
      _activeTool = null;
      _selectedAdjustTool = null;
    });
  }

  Future<void> _saveImage() async {
    if (!_isInitialized || !mounted) return;

    try {
      final db = magicMomentDatabase.instance;
      final format = await db.getImageFormat() ?? 'PNG';

      if (kIsWeb) {
        await _downloadImageWeb(_currentImage, format: format);
      } else {
        await _saveImageToGallery(_currentImage, format: format);
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
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _saveImageToGallery(Uint8List bytes, {required String format}) async {
    try {
      final directory = await getTemporaryDirectory();
      final extension = format.toLowerCase();
      final imagePath = '${directory.path}/image_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final file = File(imagePath);

      if (format == 'JPEG') {
        final img.Image? decodedImage = img.decodeImage(bytes);
        if (decodedImage != null) {
          final jpegBytes = img.encodeJpg(decodedImage, quality: 90);
          await file.writeAsBytes(jpegBytes);
        } else {
          throw Exception('Failed to decode image for JPEG conversion');
        }
      } else {
        await file.writeAsBytes(bytes);
      }

      const channel = MethodChannel('gallery_saver');
      await channel.invokeMethod('saveImage', imagePath);
    } on PlatformException catch (e) {
      debugPrint('Failed to save image: ${e.message}');
      rethrow;
    }
  }

  Future<void> _downloadImageWeb(Uint8List bytes, {required String format}) async {
    try {
      Uint8List formattedBytes;
      String mimeType;

      if (format == 'JPEG') {
        final img.Image? decodedImage = img.decodeImage(bytes);
        if (decodedImage == null) {
          throw Exception('Failed to decode image for JPEG conversion');
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
      debugPrint('Web download error: $e');
      throw Exception('Failed to download image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: Colors.black,
            child: Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        color: Colors.white,
                      ),
                      IconButton(
                        icon: const Icon(Icons.history),
                        color: Colors.white,
                        onPressed: _showEditHistory,
                      ),
                      IconButton(
                        onPressed: _saveImage,
                        icon: const Icon(Icons.save_alt),
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isInitialized && _currentImage.isNotEmpty
                      ? InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Center(
                      child: SizedBox(
                        width: _imageSize.width,
                        height: _imageSize.height,
                        child: Image.memory(
                          _currentImage,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                  )
                      : const Center(child: CircularProgressIndicator()),
                ),
                // Кнопки истории в нижней панели
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.undo),
                        color: _isUndoAvailable ? Colors.white : Colors.grey,
                        onPressed: _isUndoAvailable ? _undo : null,
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.redo),
                        color: _isRedoAvailable ? Colors.white : Colors.grey,
                        onPressed: _isRedoAvailable ? _redo : null,
                      ),
                    ],
                  ),
                ),
                if (_showToolsPanel)
                  ToolsPanel(onToolSelected: _handleToolSelected),
                IconButton(
                  icon: Icon(
                    _showToolsPanel ? Icons.close : Icons.edit,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    setState(() => _showToolsPanel = !_showToolsPanel);
                  },
                ),
              ],
            ),
          ),
          if (_activeTool == 'crop')
            CropPanel(
              image: _currentImage,
              onCancel: _closeToolPanel,
              onApply: (croppedImage) {
                _updateImage(croppedImage);
                _closeToolPanel();
              },
              onUpdateImage: _updateImage,
            ),
          if (_activeTool == 'filters')
            FiltersPanel(
              imageBytes: _currentImage,
              onCancel: _closeToolPanel,
              onApply: (filteredImage) {
                _updateImage(filteredImage);
                _closeToolPanel();
              },
              onUpdateImage: _updateImage,
            ),
          if (_activeTool == 'adjust')
            AdjustPanel(
              originalImage: _currentImage,
              onImageChanged: (Uint8List value) {
                _updateImage(value);
                _closeToolPanel();
              },
              onClose: _closeToolPanel,
              onUpdateImage: _updateImage,
            ),
          if (_activeTool == 'draw')
            DrawPanel(
              image: _currentImage,
              onCancel: _closeToolPanel,
              onApply: (drawnImage) {
                _updateImage(drawnImage);
                _closeToolPanel();
              },
              onUpdateImage: _updateImage,
              imageId: widget.imageId,
            ),
          if (_activeTool == 'text')
            TextEmojiEditor(
              image: _currentImage,
              imageId: widget.imageId,
              onCancel: _closeToolPanel,
              onApply: (textImage) {
                _updateImage(textImage);
                _closeToolPanel();
              },
              onUpdateImage: _updateImage,
            ),
          if (_activeTool == 'emoji')
            EmojiPanel(
              image: _currentImage,
              imageId: widget.imageId,
              onCancel: _closeToolPanel,
              onApply: (emojiImage) {
                _updateImage(emojiImage);
                _closeToolPanel();
              },
              onUpdateImage: _updateImage,
            ),
          if (_activeTool == 'effects')
            EffectsPanel(
              image: _currentImage,
              onCancel: _closeToolPanel,
              onApply: (effectsImage) {
                _updateImage(effectsImage);
                _closeToolPanel();
              },
            ),
          if (_activeTool == 'eraser')
            EraserPanel(
              image: _currentImage,
              imageId: widget.imageId,
              onCancel: _closeToolPanel,
              onApply: (eraserImage) {
                _updateImage(eraserImage);
                _closeToolPanel();
              },
              onUpdateImage: _updateImage,
            ),
        ],
      ),
    );
  }
}