import 'dart:io';
import 'dart:typed_data';
import 'package:MagicMoment/pagesEditing/eraserPanel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_cropper/image_cropper.dart';
import 'package:universal_html/html.dart' as html;
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
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

  const EditPage({super.key, required this.imageBytes});

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
    _initializeImage();
  }

  void _initializeImage() async {
    try {
      if (widget.imageBytes is File) {
        final file = widget.imageBytes as File;
        _currentImage = await file.readAsBytes();
      } else if (widget.imageBytes is Uint8List) {
        _currentImage = widget.imageBytes as Uint8List;
      } else {
        throw Exception('Unsupported image type');
      }
      _originalImage = Uint8List.fromList(_currentImage);

      // Инициализация истории
      _resetHistory();

      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Error initializing image: $e');
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

  void _updateUndoRedoState() {
    setState(() {
      _isUndoAvailable = _currentHistoryIndex > 0;
      _isRedoAvailable = _currentHistoryIndex < _history.length - 1;
    });
  }

  void _undo() {
    if (!_isUndoAvailable) return;

    _currentHistoryIndex--;
    _applyHistoryState();
  }

  void _redo() {
    if (!_isRedoAvailable) return;

    _currentHistoryIndex++;
    _applyHistoryState();
  }

  void _applyHistoryState() {
    _isHistoryEnabled = false; // Временно отключаем историю

    setState(() {
      _currentImage = Uint8List.fromList(_history[_currentHistoryIndex].image);
    });

    _updateUndoRedoState();

    _isHistoryEnabled = true; // Включаем историю обратно
  }

  void _updateImage(Uint8List newImage, {String? action}) {
    if (!mounted) return;

    setState(() => _currentImage = newImage);

    if (action != null) {
      _addHistoryState(action);
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

  void _handleAdjustToolSelected(int toolIndex) {
    setState(() {
      _selectedAdjustTool = toolIndex;
    });
  }

  void _closeAdjustToolPanel() {
    setState(() {
      _selectedAdjustTool = null;
    });
  }

  void _saveChanges() {

  }

  Future<void> _saveImage() async {
    if (!_isInitialized || !mounted) return;

    try {
      if (kIsWeb) {
        await _downloadImageWeb(_currentImage);
      } else {
        await _saveImageToGallery(_currentImage);
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

  Future<void> _downloadImageWeb(Uint8List bytes) async {
    try {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'edited_image_${DateTime.now().millisecondsSinceEpoch}.png')
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      debugPrint('Web download error: $e');
      throw Exception('Failed to download image: $e');
    }
  }

  Future<void> _saveImageToGallery(Uint8List bytes) async {
    try {
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/image_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(imagePath);
      await file.writeAsBytes(bytes);

      const channel = MethodChannel('gallery_saver');
      await channel.invokeMethod('saveImage', imagePath);
    } on PlatformException catch (e) {
      debugPrint('Failed to save image: ${e.message}');
      rethrow;
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
                      onPressed: _saveImage,
                      icon: const Icon(Icons.save_alt),
                      color: Colors.white,
                      ),
                ]
                  )
                ),
                // Область изображения
                Expanded(
                  child: _isInitialized
                      ? InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Center(
                      child: Image.memory(
                        _currentImage,
                        fit: BoxFit.contain,
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
            ),

          if (_activeTool == 'filters')
            FiltersPanel(
              imageBytes: _currentImage,
              onCancel: _closeToolPanel,
              onApply: (filteredImage) {
                _updateImage(filteredImage);
                _closeToolPanel();
              },
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
            ),

          if (_activeTool == 'draw')
            DrawPanel(
              image: _currentImage,
              onCancel: _closeToolPanel,
              onApply: (drawnImage) {
                _updateImage(drawnImage);
                _closeToolPanel();
              },
            ),

          if (_activeTool == 'text')
            TextEmojiEditor(
              image: _currentImage,
              onCancel: _closeToolPanel,
              onApply: (textImage) {
                _updateImage(textImage);
                _closeToolPanel();
              },
            ),

          if (_activeTool == 'emoji')
            EmojiPanel(
              image: _currentImage,
              onCancel: _closeToolPanel,
              onApply: (emojiImage) {
                _updateImage(emojiImage);
                _closeToolPanel();
              },
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
              onCancel: _closeToolPanel,
              onApply: (eraserImage) {
                _updateImage(eraserImage);
                _closeToolPanel();
              },
            ),
        ],
      )
      );
  }
}