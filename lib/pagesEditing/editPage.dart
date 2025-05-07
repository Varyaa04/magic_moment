import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:MagicMoment/pagesEditing/annotation/eraserPanel.dart';
import 'package:device_info_plus/device_info_plus.dart';
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
import 'adjust/adjustsButtonsPanel.dart';
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
  Uint8List? _currentImageBytes;
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
    _initializeImage();
    _historyManager = EditHistoryManager(
      db: magicMomentDatabase.instance,
      imageId: widget.imageId,
    );
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

      // Всегда сжимаем большие изображения
      if (bytes.length > 2 * 1024 * 1024) { // Если больше 2MB
        bytes = await _compressImage(bytes);
      }

      if (mounted) {
        setState(() {
          _currentImage = bytes;
          _originalImage = Uint8List.fromList(bytes);
          _isInitialized = true;
        });
      }

      _resetHistory();
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

    // Удаляем все состояния после текущего индекса (если делаем новое изменение после отмены)
    if (_currentHistoryIndex < _history.length - 1) {
      _history.removeRange(_currentHistoryIndex + 1, _history.length);
    }

    // Ограничиваем размер истории
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
        setState(() => _currentImage = bytes);
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
        setState(() => _currentImage = bytes);
      }
    }

    _updateUndoRedoState();
  }


  void _applyHistoryState() {
    _isHistoryEnabled = false; // Временно отключаем историю

    setState(() {
      _currentImage = Uint8List.fromList(_history[_currentHistoryIndex].image);
    });

    _updateUndoRedoState();

    _isHistoryEnabled = true;
  }


  // Обработка нехватки памяти
  // Проверка памяти
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _currentImage = Uint8List(0);
    _originalImage = Uint8List(0);
    super.dispose();
  }

  void _updateImage(Uint8List newImage, {String? action, String? operationType, Map<String, dynamic>? parameters}) async {
    if (!mounted || listEquals(_currentImage, newImage)) return;

    setState(() => _currentImage = newImage);

    if (action != null && operationType != null && parameters != null) {
      // Сохраняем снимок во временный файл
      final tempDir = await getTemporaryDirectory();
      final snapshotPath = '${tempDir.path}/snapshot_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(snapshotPath);
      await file.writeAsBytes(newImage);

      // Добавляем операцию в историю
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

      // Конвертируем в нужный формат перед сохранением
      Uint8List formattedBytes;
      if (format == 'JPEG') {
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.jpeg);
        formattedBytes = byteData!.buffer.asUint8List();
      } else {
        formattedBytes = bytes;
      }

      await file.writeAsBytes(formattedBytes);

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
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.jpeg);
        formattedBytes = byteData!.buffer.asUint8List();
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
          // Основной интерфейс
          Container(
            color: Colors.black,
            child: Column(
              children: [
                // Верхняя панель
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
                        icon: const Icon(Icons.undo),
                        onPressed: _isUndoAvailable ? _undo : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.redo),
                        onPressed: _isRedoAvailable ? _redo : null,
                      ),
                      IconButton(
                      onPressed: _saveImage,
                      icon: const Icon(Icons.save_alt),
                      color: Colors.white,
                      ),
                ]
                  )
                ),
                // Область изображения
                Expanded(
                  child: _isInitialized && _currentImage.isNotEmpty
                      ? InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Center(
                      child: Image.memory(
                        _currentImage,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                    ),
                  )
                      : const Center(child: CircularProgressIndicator()),
                ),

                // Панель инструментов
                if (_showToolsPanel)
                  ToolsPanel(onToolSelected: _handleToolSelected),

                // Кнопка вызова панели инструментов
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
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.undo),
                      color: _isUndoAvailable ? Colors.white : Colors.grey,
                      onPressed: _isUndoAvailable ? _undo : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.redo),
                      color: _isRedoAvailable ? Colors.white : Colors.grey,
                      onPressed: _isRedoAvailable ? _redo : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Панели инструментов
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
              originalImage: _originalImage,
              onImageChanged: (Uint8List value) {
                _updateImage(value);
                 _closeToolPanel();
              },
              onClose: () {
                _closeToolPanel();
              },
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
            ),

          if (_activeTool == 'text')
            TextEmojiEditor(
              image: _currentImage,
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
              //onUpdateImage: _updateImage,
            ),
          if (_activeTool == 'eraser')
            EraserPanel(
              image: _currentImage,
              onCancel: _closeToolPanel,
              onApply: (eraserImage) {
                _updateImage(eraserImage);
                _closeToolPanel();
              },
              onUpdateImage: _updateImage,
            ),
        ],
      )
      );
  }
}