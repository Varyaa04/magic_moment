import 'dart:io';
import 'package:MagicMoment/pagesEditing/filtersPanel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

import 'adjust/noisePanel.dart';
import 'adjust/saturationPanel.dart';
import 'adjust/smoothPanel.dart';
import 'adjust/contrastPanel.dart';
import 'adjust/adjustsButtonsPanel.dart';
import 'adjust/brightnessPanel.dart';
import 'adjust/exposurePanel.dart';
import 'cropPanel.dart';
import 'drawPanel.dart';
import 'emojiPanel.dart';
import 'textEditorPanel.dart';

class EditPage extends StatefulWidget {
  final dynamic imageBytes;

  const EditPage({super.key, required this.imageBytes});

  @override
  _EditPageState createState() => _EditPageState();
}

class EditState {
  final Uint8List image;
  final Map<String, dynamic>? params;

  EditState(this.image, [this.params]);
}

class _EditPageState extends State<EditPage> {
  bool _showCropPanel = false;
  bool _showAdjustsPanel = false;
  bool _showAdjustToolPanel = false;
  int? _selectedAdjustTool;
  late Uint8List _currentImage;
  late Uint8List _originalImage;
  bool _isInitialized = false;
  bool _showTextPanel = false;
  bool _showFiltersPanel = false;
  bool _showEmojiPanel = false;
  bool _isDrawingPanelVisible = false;
  bool _showDrawPanel = false;
  bool _isEditing = false; // Флаг для отслеживания редактирования
  CropAspectRatioPreset _selectedCropPreset = CropAspectRatioPreset.original;
  List<DrawingPoint> _drawingPoints = [];
  bool _isDrawing = false;

  // Для управления историей
  final List<EditState> _history = [];
  int _currentHistoryIndex = -1;
  bool _isUndoAvailable = false;
  bool _isRedoAvailable = false;

  @override
  void initState() {
    super.initState();
    _initializeImage();
  }

  Future<void> _initializeImage() async {
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
      _addToHistory(EditState(_currentImage));

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading image: ${e.toString()}')),
        );
      }
    }
  }

  void _toggleDrawingPanel() {
    setState(() {
      _isDrawingPanelVisible = !_isDrawingPanelVisible;
    });
  }

  void _addToHistory(EditState state) {
    if (_currentHistoryIndex < _history.length - 1) {
      _history.removeRange(_currentHistoryIndex + 1, _history.length);
    }

    // Ограничиваем размер истории
    if (_history.length >= 20) {
      _history.removeAt(0);
      _currentHistoryIndex--;
    }

    // Добавляем новое состояние в историю
    _history.add(EditState(Uint8List.fromList(state.image), state.params));
    _currentHistoryIndex = _history.length - 1;

    // Обновляем флаги доступности undo/redo
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
    setState(() {
      _currentImage = Uint8List.fromList(_history[_currentHistoryIndex].image);
      _isEditing = false;
    });
    _updateUndoRedoState();
  }

  void _redo() {
    if (!_isRedoAvailable) return;

    _currentHistoryIndex++;
    setState(() {
      _currentImage = Uint8List.fromList(_history[_currentHistoryIndex].image);
      _isEditing = false;
    });
    _updateUndoRedoState();
  }

  void _updateImage(Uint8List newImage, [Map<String, dynamic>? params]) {
    if (!mounted) return;
    setState(() {
      _currentImage = newImage;
      _isEditing = true;
    });
  }

  // Сохраняем изменения в историю
  void _saveChanges() {
    if (!_isEditing) return;

    _addToHistory(EditState(_currentImage));
    setState(() {
      _isEditing = false;
    });
  }

  void _toggleAdjustsPanel() {
    setState(() {
      _showAdjustsPanel = !_showAdjustsPanel;
      _showAdjustToolPanel = false;
      _selectedAdjustTool = null;
      if (_showCropPanel) _showCropPanel = false;
    });
  }

  void _handleToolSelected(int toolIndex) {
    setState(() {
      _showAdjustToolPanel = true;
      _selectedAdjustTool = toolIndex;
    });
  }

  void _closeAdjustToolPanel() {
    setState(() {
      _showAdjustToolPanel = false;
      _selectedAdjustTool = null;
    });
  }

  void _toggleCropPanel() {
    setState(() {
      _showCropPanel = !_showCropPanel;
      if (_showAdjustsPanel) _showAdjustsPanel = false;
    });
  }

  void _handleButtonPress(int index) {
    switch (index) {
      case 0: // Crop
        _toggleCropPanel();
        break;
      case 1: // Adjust
        _toggleAdjustsPanel();
        break;
      case 2: // Filters
        setState(() {
          _showFiltersPanel = true;
          _showTextPanel = false;
          _showDrawPanel = false;
          _showCropPanel = false;
          _showAdjustsPanel = false;
        });
        break;
      case 3: // Draw
        setState(() {
          _isDrawingPanelVisible = true;
          _showDrawPanel = true;
          _showTextPanel = false;
          _showEmojiPanel = false;
          _showCropPanel = false;
          _showAdjustsPanel = false;
        });
        break;
      case 4: // Text
        setState(() {
          _showTextPanel = true;
          _showDrawPanel = false;
          _showEmojiPanel = false;
          _showCropPanel = false;
          _showAdjustsPanel = false;
        });
        break;
      case 5: // Emoji
        setState(() {
          _showEmojiPanel = true;
          _showTextPanel = false;
          _showDrawPanel = false;
          _showCropPanel = false;
          _showAdjustsPanel = false;
        });
        break;
      default:
        debugPrint('Button $index pressed');
    }
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
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
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
    final appLocalizations = AppLocalizations.of(context);
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
                        onPressed: () async {
                          bool? shouldPop = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title:  Text(appLocalizations?.warning ?? 'Warning'),
                                content:  Text(appLocalizations?.areYouSure ?? 'Are you sure you want to exit? All unsaved changes will be deleted.'),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text(appLocalizations?.cancel ?? 'Cancel'),
                                    onPressed: () {
                                      Navigator.of(context).pop(false);
                                    },
                                  ),
                                  TextButton(
                                    child:  Text(appLocalizations?.exit ?? 'Exit'),
                                    onPressed: () {
                                      Navigator.of(context).pop(true);
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                          if (shouldPop == true) {
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(FluentIcons.arrow_left_16_filled),
                        color: Colors.white,
                      ),
                      IconButton(
                        onPressed: _isInitialized ? _saveImage : null,
                        icon: const Icon(Icons.save_alt_rounded),
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                // место для фото
                Expanded(
                  child: _isInitialized
                      ? InteractiveViewer(
                    child: Center(
                      child: Image.memory(
                        _currentImage,
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                      : const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                // Bottom tools panel
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          onPressed: _showCropPanel
                              ? _toggleCropPanel
                              : _showAdjustsPanel
                              ? _toggleAdjustsPanel
                              : null,
                          icon: const Icon(FluentIcons.arrow_hook_up_left_16_regular),
                          color: Colors.white,
                        ),
                        IconButton(
                          onPressed: _showCropPanel
                              ? () {
                            _applyCrop();
                            _saveChanges(); // Сохраняем изменения в историю
                          }
                              : _showAdjustsPanel
                              ? () {
                            _toggleAdjustsPanel();
                            _saveChanges(); // Сохраняем изменения в историю
                          }
                              : null,
                          icon: const Icon(FluentIcons.arrow_hook_up_right_16_filled),
                          color: Colors.white,
                        ),
                      ],
                    ),
                    Container(height: 1, color: Colors.white.withOpacity(0.3)),
                    _buildToolsPanel(context),
                  ],
                ),
              ],
            ),
          ),
          //  панель обрезки
          // if (_showCropPanel)
          //   Positioned(
          //     bottom: 0,
          //     left: 0,
          //     right: 0,
          //     child: CropPanel(
          //       originalImage: _currentImage,
          //       onCancel: () {
          //         Navigator.pop(context);
          //       },
          //       onApply: (editedImage) {
          //         Navigator.pop(context, editedImage);
          //       },
          //       onCropTypeSelected: (ratio) {
          //         print('Selected ratio: $ratio');
          //       },
          //     ),
          //   ),

          // Главная панель регулировок
          if (_showAdjustsPanel && !_showAdjustToolPanel)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AdjustButtonsPanel(
                onBack: _toggleAdjustsPanel,
                onToolSelected: _handleToolSelected,
                onUndo: _undo,
                onRedo: _redo,
                isUndoAvailable: _isUndoAvailable,
                isRedoAvailable: _isRedoAvailable,
              ),
            ),

          // Конкретная панель инструмента
          if (_showAdjustToolPanel)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildSelectedToolPanel(),
            ),

          // панель фильтров
          // if (_showFiltersPanel)
          //   Positioned(
          //     bottom: 0,
          //     left: 0,
          //     right: 0,
          //     child: FiltersListView(
          //       originalImage: _currentImage,
          //       onFilterApplied: (filteredImage) {
          //         setState(() {
          //           _currentImage = filteredImage;
          //           _showFiltersPanel = false;
          //         });
          //         _saveChanges();
          //       },
          //     ),
          //   ),

          // панель для добавления текста
          if (_showTextPanel)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: TextEditor(
                image: _currentImage,
                onUpdate: (editedImage) {
                  _updateImage(editedImage);
                  _saveChanges(); // Сохраняем изменения в историю
                },
                onClose: () => setState(() => _showTextPanel = false),
                theme: Theme.of(context), // Передаем текущую тему
              ),
            ),

          // панель для добавления эмоджи
          if (_showEmojiPanel)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: EmojiPanel(
                originalImage: _currentImage,
                onImageChanged: _updateImage,
                onCancel: () => setState(() => _showEmojiPanel = false),
                onApply: () {
                  setState(() => _showEmojiPanel = false);
                  _saveChanges(); // Сохраняем изменения в историю
                },
              ),
            ),

          // панель для добавления рисунка
          if (_showDrawPanel)
            Positioned(
              child: DrawPanel(
                currentImage: _currentImage,
                onImageChanged: (image) {
                  setState(() {
                    _currentImage = image;
                  });
                },
                onCancel: _toggleDrawingPanel,
                onApply: _toggleDrawingPanel,
                isDrawingPanelVisible: _isDrawingPanelVisible,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolsPanel(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: List.generate(6, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _handleButtonPress(index),
                  icon: Icon(
                    _getIconForIndex(index),
                    size: 28,
                  ),
                  color: Colors.white,
                ),
                const SizedBox(height: 4),
                Text(
                  _getLabelForIndex(index, context),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _getLabelForIndex(int index, BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    switch (index) {
      case 0: return appLocalizations?.crop ?? 'Crop';
      case 1: return appLocalizations?.parametrs ?? 'Parametrs';
      case 2: return appLocalizations?.filters ?? 'Filters';
      case 3: return appLocalizations?.draw ?? 'Draw';
      case 4: return appLocalizations?.text ?? 'Text';
      case 5: return appLocalizations?.emoji ?? 'Emoji';
      default: return 'button';
    }
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0: return FluentIcons.crop_24_filled;
      case 1: return FluentIcons.brightness_high_24_filled;
      case 2: return Icons.filter_b_and_w;
      case 3: return FluentIcons.ink_stroke_24_regular;
      case 4: return FluentIcons.text_field_24_regular;
      case 5: return FluentIcons.emoji_sparkle_24_regular;
      default: return Icons.error;
    }
  }

  Widget _buildSelectedToolPanel() {
    // Берем текущее изображение вместо оригинального
    final currentImage = _currentImage;

    switch (_selectedAdjustTool) {
      case 0: // Яркость
        return BrightnessPanel(
          onCancel: _closeAdjustToolPanel,
          onApply: () {
            _closeAdjustToolPanel();
            _saveChanges(); // Сохраняем изменения в историю
          },
          originalImage: currentImage,
          onImageChanged: (newImage) => _updateImage(newImage, {'type': 'brightness'}),
        );
      case 1: // Контраст
        return ContrastPanel(
          onCancel: _closeAdjustToolPanel,
          onApply: () {
            _closeAdjustToolPanel();
            _saveChanges(); // Сохраняем изменения в историю
          },
          originalImage: currentImage,
          onImageChanged: (newImage) => _updateImage(newImage, {'type': 'contrast'}),
        );
      case 2: // Экспозиция
        return ExposurePanel(
          onCancel: _closeAdjustToolPanel,
          onApply: () {
            _closeAdjustToolPanel();
            _saveChanges(); // Сохраняем изменения в историю
          },
          originalImage: currentImage,
          onImageChanged: (newImage) => _updateImage(newImage, {'type': 'exposure'}),
        );
      case 3: // Насыщенность
        return SaturationPanel(
          onCancel: _closeAdjustToolPanel,
          onApply: () {
            _closeAdjustToolPanel();
            _saveChanges(); // Сохраняем изменения в историю
          },
          originalImage: currentImage,
          onImageChanged: (newImage) => _updateImage(newImage, {'type': 'saturation'}),
        );
      case 4: // Зернистость
        return NoisePanel(
          onCancel: _closeAdjustToolPanel,
          onApply: () {
            _closeAdjustToolPanel();
            _saveChanges(); // Сохраняем изменения в историю
          },
          originalImage: currentImage,
          onImageChanged: (newImage) => _updateImage(newImage, {'type': 'noise'}),
        );
      case 5: // Гладкость
        return SmoothPanel(
          onCancel: _closeAdjustToolPanel,
          onApply: () {
            _closeAdjustToolPanel();
            _saveChanges(); // Сохраняем изменения в историю
          },
          originalImage: currentImage,
          onImageChanged: (newImage) => _updateImage(newImage, {'type': 'smooth'}),
        );
      default:
        return Container();
    }
  }

  Future<void> _applyCrop() async {
    _toggleCropPanel();
  }
}