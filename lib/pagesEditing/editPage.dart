import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:MagicMoment/pagesEditing/rotatePanel.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html
    if (dart.library.io) 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import '../database/editHistory.dart';
import '../database/editHistoryManager.dart';
import '../database/magicMomentDatabase.dart';
import '../pagesSettings/classesSettings/app_localizations.dart';
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
import 'package:flutter_image_compress/flutter_image_compress.dart';

// Утилиты для адаптивного дизайна
class ResponsiveUtils {
  static double getResponsiveWidth(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * percentage;
  }

  static double getResponsiveHeight(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.height * percentage;
  }

  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    return baseSize * (width / 600).clamp(0.8, 1.5);
  }

  static bool isDesktop(BuildContext context) {
    if (kIsWeb) {
      return MediaQuery.of(context).size.width > 800;
    }
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return EdgeInsets.symmetric(
      horizontal: width * 0.02,
      vertical: width * 0.01,
    );
  }
}

// Реализация LRU-кэша
class LRUCache<K, V> {
  final int capacity;
  final Map<K, V> _cache = {};
  final List<K> _keys = [];

  LRUCache(this.capacity);

  V? get(K key) {
    if (_cache.containsKey(key)) {
      _keys.remove(key);
      _keys.add(key);
      return _cache[key];
    }
    return null;
  }

  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _keys.remove(key);
    } else if (_cache.length >= capacity) {
      final oldestKey = _keys.removeAt(0);
      _cache.remove(oldestKey);
    }
    _cache[key] = value;
    _keys.add(key);
  }

  void clear() {
    _cache.clear();
    _keys.clear();
  }
}

class EditPage extends StatefulWidget {
  final Uint8List imageBytes;
  final int imageId;
  final bool isFromCollage;

  const EditPage({
    super.key,
    required this.imageBytes,
    required this.imageId,
    this.isFromCollage = false,
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
  final ValueNotifier<Uint8List?> _currentImage = ValueNotifier(null);
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
  List<EditHistory> _cachedHistory = [];
  int _currentHistoryIndex = -1;
  final int _maxHistorySteps = 20;
  bool _isHistoryEnabled = true;
  final LRUCache<int, Uint8List> _imageCache = LRUCache(10);
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      if (widget.imageBytes.isEmpty) {
        throw Exception('Пустые данные изображения');
      }
      _currentImage.value = widget.imageBytes;
      _originalImage = Uint8List.fromList(widget.imageBytes);
      _historyManager = EditHistoryManager(
        db: MagicMomentDatabase.instance,
        imageId: widget.imageId,
      );

      await Future.wait([_initializeImage(), _loadHistory()]);
    } catch (e, stackTrace) {
      debugPrint('Ошибка инициализации: $e\nСтек: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Не удалось инициализировать: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _loadHistory() async {
    try {
      debugPrint('Loading history in EditPage for imageId: ${widget.imageId}');
      await _historyManager.loadHistory();
      _cachedHistory =
          await _historyManager.db.getAllHistoryForImage(widget.imageId);
      _currentHistoryIndex = _historyManager.currentIndex;
      _updateUndoRedoState();
      setState(() {});
      debugPrint('EditPage: Loaded ${_cachedHistory.length} history entries');
    } catch (e, stackTrace) {
      debugPrint('Ошибка загрузки истории: $e\nСтек: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки истории: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
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
    _imageCache.clear();
    debugPrint('Disposing EditPage');
    super.dispose();
  }

  Future<void> _initializeImage() async {
    if (!mounted) return;

    setState(() => _isProcessing.value = true);
    _loadingProgress.value = 0.1;

    try {
      final bytes = await _resizeImage(widget.imageBytes,
          maxWidth: 1080, preserveTransparency: true);
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Не удалось изменить размер изображения');
      }

      _loadingProgress.value = 0.3;

      await precacheImage(MemoryImage(bytes), context);
      _currentImage.value = bytes;
      _originalImage = Uint8List.fromList(bytes);
      _imageSize.value = await _decodeImageSize(bytes);
      _isInitialized.value = true;
      _imageLoaded = true;

      _resetHistory();

      _loadingProgress.value = 1.0;
    } catch (e, stackTrace) {
      debugPrint('Ошибка инициализации изображения: $e\nСтек: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки изображения: $e'),
            backgroundColor: Colors.red[700],
          ),
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

  Future<Size> _decodeImageSize(Uint8List bytes) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      completer.complete(img);
    });
    final image = await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw Exception('Тайм-аут декодирования изображения'),
    );
    final size = Size(image.width.toDouble(), image.height.toDouble());
    image.dispose();
    return size;
  }

  Map<String, dynamic> _sanitizeParameters(Map<String, dynamic> parameters) {
    final sanitized = <String, dynamic>{};
    for (var entry in parameters.entries) {
      if (entry.value is num ||
          entry.value is String ||
          entry.value is bool ||
          entry.value is List ||
          entry.value is Map ||
          entry.value == null) {
        sanitized[entry.key] = entry.value;
      } else {
        debugPrint('Пропуск несереализуемого параметра: ${entry.key}');
        sanitized[entry.key] = entry.value.toString();
      }
    }
    return sanitized;
  }

  Future<void> _updateImage(Uint8List newImage,
      {String? action,
      String? operationType,
      Map<String, dynamic>? parameters}) async {
    if (newImage.isEmpty) {
      debugPrint(
          'Ошибка: newImage пустое в _updateImage, действие: $action, тип операции: $operationType');
      return;
    }
    if (!mounted || listEquals(_currentImage.value, newImage)) return;

    setState(() => _isProcessing.value = true);
    try {
      final bool preserveTransparency = operationType == 'Eraser' ||
          operationType == 'object_removal' ||
          operationType == 'collage' ||
          operationType == 'remove_bg' ||
          operationType == 'Text' ||
          operationType == 'Emoji' ||
          operationType == 'Crop' ||
          operationType == 'Effects' ||
          operationType == 'Draw' ||
          operationType == 'Filter' ||
          operationType == 'Rotate' ||
          operationType == 'Adjustments' ;

      final bytes = await _compressImage(newImage,
          quality: 70,
          maxWidth: 800,
          preserveTransparency: preserveTransparency);
      if (bytes.isEmpty) {
        throw Exception('Не удалось изменить размер изображения');
      }
      if (!mounted) return;

      debugPrint('Preloading new image, size: ${bytes.length} bytes');
      await precacheImage(MemoryImage(bytes), context);
      _currentImage.value = bytes;
      _imageLoaded = true;
      _imageCache.put(_currentHistoryIndex + 1, bytes);

      _imageSize.value = await _decodeImageSize(bytes);

      if (parameters != null && operationType != null) {
        final serializableParameters = _sanitizeParameters(parameters);
        final historyEntry = await _historyManager.addOperation(
          context: context,
          operationType: operationType,
          parameters: serializableParameters,
          snapshotBytes: bytes,
        );
        _cachedHistory.add(historyEntry);
        if (_cachedHistory.length > _maxHistorySteps) {
          _cachedHistory.removeAt(0);
        }
      }
      debugPrint(
          'Изображение обновлено: $operationType, размер: ${bytes.length} байт');
      _updateUndoRedoState();
    } catch (e, stackTrace) {
      debugPrint('Ошибка обновления изображения: $e\nСтек: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления изображения: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing.value = false);
      }
    }
  }

  Future<Uint8List> _compressImage(Uint8List imageBytes,
      {int quality = 80,
      int maxWidth = 1080,
      bool preserveTransparency = false}) async {
    final result = await compute(_compressImageIsolate, {
      'imageBytes': imageBytes,
      'quality': quality,
      'maxWidth': maxWidth,
      'preserveTransparency': preserveTransparency,
    });
    debugPrint(
        'Формат сжатого изображения: ${preserveTransparency ? 'PNG' : 'JPEG'}');
    return result;
  }

  static Uint8List _compressImageIsolate(Map<String, dynamic> params) {
    final imageBytes = params['imageBytes'] as Uint8List;
    final quality = params['quality'] as int;
    final maxWidth = params['maxWidth'] as int;
    final preserveTransparency = params['preserveTransparency'] as bool;

    debugPrint(
        'Начало _compressImageIsolate: размер входного изображения=${imageBytes.length} байт');
    try {
      if (imageBytes.isEmpty) {
        throw Exception(
            'Пустой массив байтов изображения в _compressImageIsolate');
      }
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) {
        debugPrint('Не удалось декодировать изображение в _compressImage');
        return imageBytes;
      }
      final resized =
          img.copyResize(decoded, width: maxWidth, maintainAspect: true);
      final compressed = preserveTransparency
          ? img.encodePng(resized, level: 6)
          : img.encodeJpg(resized, quality: quality);
      debugPrint(
          'Сжатое изображение: оригинал=${imageBytes.length}, сжатое=${compressed.length}');
      return Uint8List.fromList(compressed);
    } catch (e, stackTrace) {
      debugPrint('Ошибка сжатия изображения: $e\nСтек: $stackTrace');
      return imageBytes;
    }
  }

  void _updateUndoRedoState() {
    _isUndoAvailable.value = _historyManager.canUndo;
    _isRedoAvailable.value = _historyManager.canRedo;
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

  void _resetHistory() {
    final localizations = AppLocalizations.of(context);
    _history.clear();
    _imageCache.clear();
    _cachedHistory.clear();
    _addHistoryState(localizations?.create ?? 'Оригинальное изображение');
    _currentHistoryIndex = 0;
  }

  void _undo() async {
    if (!_isUndoAvailable.value) return;

    setState(() => _isProcessing.value = true);
    try {
      final entry = await _historyManager.undo();
      if (entry == null) {
        throw Exception('Нет записей в истории для отмены');
      }

      final bytes = entry.snapshotBytes != null
          ? Uint8List.fromList(entry.snapshotBytes!)
          : throw Exception('Нет данных снимка для отмены');

      if (bytes.isEmpty) {
        throw Exception('Пустые данные снимка для отмены');
      }

      await precacheImage(MemoryImage(bytes), context);
      _currentImage.value = bytes;
      _imageLoaded = true;
      _imageSize.value = await _decodeImageSize(bytes);
      _currentHistoryIndex = _historyManager.currentIndex;
      _cachedHistory =
          await _historyManager.db.getAllHistoryForImage(widget.imageId);
      _updateUndoRedoState();
    } catch (e, stackTrace) {
      debugPrint('Ошибка отмены: $e\nСтек: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при отмене действия: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing.value = false);
      }
    }
  }

  void _redo() async {
    if (!_isRedoAvailable.value) return;

    setState(() => _isProcessing.value = true);
    try {
      final entry = await _historyManager.redo();
      if (entry == null) {
        throw Exception('Нет записей в истории для повтора');
      }

      final bytes = entry.snapshotBytes != null
          ? Uint8List.fromList(entry.snapshotBytes!)
          : throw Exception('Нет данных снимка для повтора');

      if (bytes.isEmpty) {
        throw Exception('Пустые данные снимка для повтора');
      }

      await precacheImage(MemoryImage(bytes), context);
      _currentImage.value = bytes;
      _imageLoaded = true;
      _imageSize.value = await _decodeImageSize(bytes);
      _currentHistoryIndex = _historyManager.currentIndex;
      _cachedHistory =
          await _historyManager.db.getAllHistoryForImage(widget.imageId);
      _updateUndoRedoState();
    } catch (e, stackTrace) {
      debugPrint('Ошибка повтора: $e\nСтек: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при повторе действия: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing.value = false);
      }
    }
  }

  Future<void> _addHistoryState(String description) async {
    if (!_isHistoryEnabled || _currentImage.value == null) return;

    if (_history.isNotEmpty &&
        listEquals(_history.last.image, _currentImage.value)) {
      return;
    }

    final snapshotBytes = await _compressImage(_currentImage.value!,
        quality: 70, maxWidth: 800, preserveTransparency: true);

    final historyEntry = await _historyManager.addOperation(
      context: context,
      operationType: description,
      parameters: {},
      snapshotBytes: snapshotBytes,
    );

    _cachedHistory.add(historyEntry);
    _imageCache.put(historyEntry.historyId!, snapshotBytes);
    _history.add(EditState(snapshotBytes, description));

    if (_history.length > _maxHistorySteps) {
      _history.removeAt(0);
      _cachedHistory.removeAt(0);
    }

    _currentHistoryIndex = _historyManager.currentIndex;
    _updateUndoRedoState();
  }

  bool _isSameAsLast(Uint8List newImage) {
    if (_history.isEmpty) return false;
    return listEquals(_history.last.image, newImage);
  }

  Uint8List validateImageBytes(Uint8List? bytes, String context) {
    if (bytes == null) {
      debugPrint('Ошибка: $context: Байты изображения null');
      throw Exception('$context: Байты изображения null');
    }
    if (bytes.isEmpty) {
      debugPrint('Ошибка: $context: Байты изображения пустые');
      throw Exception('$context: Байты изображения пустые');
    }
    return bytes;
  }

  Future<void> _saveImage() async {
    final localizations = AppLocalizations.of(context);
    if (!_isInitialized.value || !mounted || _currentImage.value == null) {
      return;
    }

    final selectedFormat = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          localizations?.save ?? 'Сохранить изображение',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          localizations?.chooseFormat ?? 'Выберите формат изображения:',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('PNG'),
            child: Text(
              localizations?.pngTr ?? 'PNG (с прозрачностью)',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('JPEG'),
            child: const Text(
              'JPEG',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(
              localizations?.cancel ?? 'Отмена',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );

    if (selectedFormat == null) return;

    setState(() => _isProcessing.value = true);
    try {
      Uint8List bytes;
      if (selectedFormat == 'PNG') {
        final decoded = img.decodeImage(_currentImage.value!);
        if (decoded == null) {
          throw Exception('Не удалось декодировать изображение для сохранения');
        }
        bytes = Uint8List.fromList(img.encodePng(decoded, level: 0));
      } else {
        final decoded = img.decodeImage(_currentImage.value!);
        if (decoded == null) {
          throw Exception('Не удалось декодировать изображение для сохранения');
        }
        bytes = Uint8List.fromList(img.encodeJpg(decoded, quality: 100));
      }

      if (kIsWeb) {
        await _downloadImageWeb(bytes, format: selectedFormat);
      } else {
        final hasPermission = await _requestPermissions();
        if (!hasPermission) {
          throw Exception(
              localizations?.permissionDenied ?? 'Доступ к хранилищу запрещен');
        }
        await _saveImageToGallery(bytes, format: selectedFormat);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations?.saveSuccess ?? 'Изображение успешно сохранено',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Ошибка сохранения изображения: $e\nСтек: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${localizations?.error ?? 'Ошибка'}: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      setState(() => _isProcessing.value = false);
    }
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      final sdkVersion = deviceInfo.version.sdkInt;

      if (sdkVersion >= 33) {
        final photosStatus = await Permission.photos.request();
        if (photosStatus.isGranted) {
          return true;
        }
        final writeStatus = await Permission.photosAddOnly.request();
        if (writeStatus.isGranted) {
          return true;
        }
      } else {
        final storageStatus = await Permission.storage.request();
        if (storageStatus.isGranted) {
          return true;
        }
      }
      return false;
    }
    return true;
  }

  Future<void> _saveImageToGallery(Uint8List bytes,
      {required String format}) async {
    final localizations = AppLocalizations.of(context);
    try {
      final tempDir = await getTemporaryDirectory();
      final extension = format.toLowerCase();
      final filePath =
          '${tempDir.path}/MagicMoment_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final file = File(filePath);

      await file.writeAsBytes(bytes);

      final result =
          await GallerySaver.saveImage(filePath, albumName: 'MagicMoment');

      if (result == null) {
        throw Exception(localizations?.errorSaveGallery ??
            'Не удалось сохранить изображение в галерею');
      }

      await file.delete();
    } catch (e, stackTrace) {
      debugPrint('Ошибка сохранения в галерею: $e\nСтек: $stackTrace');
      throw Exception(localizations?.errorSaveGallery ??
          'Не удалось сохранить изображение в галерею: $e');
    }
  }

  Future<void> _shareImage() async {
    final localizations = AppLocalizations.of(context);
    if (!_isInitialized.value || !mounted || _currentImage.value == null) {
      return;
    }

    setState(() => _isProcessing.value = true);
    try {
      final bytes = await _compressImage(_currentImage.value!,
          quality: 90, maxWidth: 1080, preserveTransparency: true);
      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/MagicMoment_share_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);

      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(filePath)],
          text: localizations?.shareText ??
              'Посмотрите мое отредактированное изображение в MagicMoment!');
      await file.delete();
    } catch (e, stackTrace) {
      debugPrint('Ошибка при поделиться изображением: $e\nСтек: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${localizations?.error ?? 'Ошибка'}: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      setState(() => _isProcessing.value = false);
    }
  }

  Future<void> _downloadImageWeb(Uint8List bytes,
      {required String format}) async {
    final localizations = AppLocalizations.of(context);
    try {
      Uint8List formattedBytes;
      String mimeType;

      if (format == 'JPEG') {
        formattedBytes = bytes;
        mimeType = 'image/jpeg';
      } else {
        formattedBytes = bytes;
        mimeType = 'image/png';
      }

      final blob = html.Blob([formattedBytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download',
            'MagicMoment_${DateTime.now().millisecondsSinceEpoch}.${format.toLowerCase()}')
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e, stackTrace) {
      debugPrint('Ошибка скачивания изображения: $e\nСтек: $stackTrace');
      throw Exception(
          localizations?.errorDownload ?? 'Не удалось скачать изображение: $e');
    }
  }

  void _handleToolSelected(String tool) {
    final localizations = AppLocalizations.of(context);
    if (_currentImage.value == null || _currentImage.value!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations?.error ?? 'Изображение не загружено',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    _activeTool.value = tool;
    _showToolsPanel.value = false;
  }

  void _closeToolPanel() {
    _activeTool.value = null;
  }

  Future<void> _confirmBackNavigation() async {
    final localizations = AppLocalizations.of(context);

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            localizations?.back ?? 'Вернуться назад',
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            localizations?.unsavedChangesWarning ??
                'Вы уверены, что хотите вернуться? Все несохраненные изменения будут потеряны.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                localizations?.cancel ?? 'Отмена',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                localizations?.yes ?? 'Да',
                style: const TextStyle(color: Colors.redAccent),
              ),
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
    final localizations = AppLocalizations.of(context);

// Ensure history is loaded
    await _loadHistory();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  localizations?.history ?? 'История редактирования',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: _cachedHistory.isEmpty
                    ? Center(
                        child: Text(
                          localizations?.noHistory ?? 'История пуста',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context, 16),
                          ),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: _cachedHistory.length,
                        itemBuilder: (context, index) {
                          final item = _cachedHistory[index];
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: GestureDetector(
                              onTap: () async {
                                Navigator.pop(context);
                                try {
                                  final imageBytes = item.snapshotBytes != null
                                      ? Uint8List.fromList(item.snapshotBytes!)
                                      : throw Exception(
                                          'Нет данных снимка для historyId: ${item.historyId}');
                                  debugPrint(
                                      'История: Загрузка снимка для индекса $index, длина байт: ${imageBytes.length}');
                                  await _updateImage(
                                    imageBytes,
                                    action: 'Восстановление из истории',
                                    operationType: 'restore',
                                    parameters: {'historyId': item.historyId},
                                  );
                                  _currentHistoryIndex = index;
                                  _historyManager.setCurrentIndex(index);
                                  _updateUndoRedoState();
                                } catch (e, stackTrace) {
                                  debugPrint(
                                      'Ошибка восстановления из истории: $e\nСтек: $stackTrace');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${localizations?.error ?? 'Ошибка'}: $e',
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                        backgroundColor: Colors.red[700],
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Column(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: _currentHistoryIndex == index
                                            ? Colors.blueAccent
                                            : Colors.grey,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: item.snapshotBytes != null &&
                                              item.snapshotBytes!.isNotEmpty
                                          ? Image.memory(
                                              Uint8List.fromList(
                                                  item.snapshotBytes!),
                                              fit: BoxFit.cover,
                                              width: 100,
                                              height: 100,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                debugPrint(
                                                    'Ошибка отображения снимка для historyId: ${item.historyId}, ошибка: $error');
                                                return Container(
                                                  color: Colors.grey[800],
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.broken_image,
                                                      color: Colors.white70,
                                                      size: 40,
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(
                                              color: Colors.grey[800],
                                              child: const Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  color: Colors.white70,
                                                  size: 40,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item.operationType ?? 'Изменение $index',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize:
                                          ResponsiveUtils.getResponsiveFontSize(
                                              context, 12),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
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
        final padding = 16.0;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Column(
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
                            tooltip: localizations?.back ?? 'Назад',
                          ),
                          Row(
                            children: [
                              ValueListenableBuilder(
                                valueListenable: _isUndoAvailable,
                                builder: (context, isUndoAvailable, _) {
                                  return IconButton(
                                    icon: Icon(Icons.undo, size: iconSize),
                                    color: isUndoAvailable
                                        ? Colors.white
                                        : Colors.grey,
                                    onPressed: isUndoAvailable ? _undo : null,
                                    tooltip: localizations?.undo ?? 'Отменить',
                                  );
                                },
                              ),
                              ValueListenableBuilder(
                                valueListenable: _isRedoAvailable,
                                builder: (context, isRedoAvailable, _) {
                                  return IconButton(
                                    icon: Icon(Icons.redo, size: iconSize),
                                    color: isRedoAvailable
                                        ? Colors.white
                                        : Colors.grey,
                                    onPressed: isRedoAvailable ? _redo : null,
                                    tooltip: localizations?.redo ?? 'Повторить',
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.history, size: iconSize),
                                color: Colors.white,
                                onPressed: _showEditHistory,
                                tooltip: localizations?.history ?? 'История',
                              ),
                              IconButton(
                                onPressed: _saveImage,
                                icon: Icon(Icons.save_alt, size: iconSize),
                                color: Colors.white,
                                tooltip: localizations?.save ?? 'Сохранить',
                              ),
                              IconButton(
                                onPressed: _shareImage,
                                icon: Icon(Icons.share, size: iconSize),
                                color: Colors.white,
                                tooltip: localizations?.share ?? 'Поделиться',
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
                                      'Загрузка изображения...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize:
                                        ResponsiveUtils.getResponsiveFontSize(
                                            context, 16),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return ValueListenableBuilder(
                          valueListenable: _currentImage,
                          builder: (context, image, _) {
                            if (image == null || image.isEmpty) {
                              return Center(
                                child: Text(
                                  localizations?.error ??
                                      'Не удалось загрузить изображение',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize:
                                        ResponsiveUtils.getResponsiveFontSize(
                                            context, 16),
                                  ),
                                ),
                              );
                            }
                            return ValueListenableBuilder(
                              valueListenable: _imageSize,
                              builder: (context, size, _) => InteractiveViewer(
                                minScale: 0.5,
                                maxScale: 2.0,
                                child: Center(
                                  child: SizedBox(
                                    width: size.width,
                                    height: size.height,
                                    child: _imageLoaded
                                        ? Image.memory(
                                            image,
                                            key: ValueKey(image.hashCode),
                                            gaplessPlayback: true,
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              debugPrint(
                                                  'Error displaying image: $error');
                                              return Text(
                                                '${localizations?.error ?? 'Ошибка загрузки изображения'}: $error',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: ResponsiveUtils
                                                      .getResponsiveFontSize(
                                                          context, 16),
                                                ),
                                              );
                                            },
                                          )
                                        : const CircularProgressIndicator(
                                            color: Colors.white),
                                  ),
                                ),
                              ),
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
                            constraints:
                                BoxConstraints(maxHeight: isMobile ? 80 : 100),
                            child:
                                ToolsPanel(onToolSelected: _handleToolSelected),
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
                                  ? localizations?.cancel ?? 'Закрыть'
                                  : localizations?.edit ?? 'Редактировать',
                            ),
                          ),
                  ),
                ],
              ),
              ValueListenableBuilder(
                valueListenable: _activeTool,
                builder: (context, tool, _) {
                  if (tool == null || _currentImage.value == null)
                    return const SizedBox.shrink();
                  switch (tool) {
                    case 'crop':
                      return CropPanel(
                        image: _currentImage.value!,
                        onCancel: _closeToolPanel,
                        onApply: (croppedImage) {
                          _updateImage(croppedImage,
                              action: 'Обрезка',
                              operationType: 'Crop',
                              parameters: {});
                          _closeToolPanel();
                        },
                        onUpdateImage: _updateImage,
                        imageId: widget.imageId,
                      );
                    case 'rotate':
                      return RotatePanel(
                        image: _currentImage.value!,
                        onCancel: _closeToolPanel,
                        onApply: (croppedImage) {
                          _updateImage(croppedImage,
                              action: 'Поворот',
                              operationType: 'Rotate',
                              parameters: {});
                          _closeToolPanel();
                        },
                        onUpdateImage: _updateImage,
                        imageId: widget.imageId,
                      );
                    case 'filters':
                      return FiltersPanel(
                        imageBytes: _currentImage.value!,
                        onCancel: _closeToolPanel,
                        onApply: (filteredImage) {
                          _updateImage(filteredImage,
                              action: 'Фильтр',
                              operationType: 'Filter',
                              parameters: {});
                          _closeToolPanel();
                        },
                        onUpdateImage: _updateImage,
                        imageId: widget.imageId,
                      );
                    case 'adjust':
                      return AdjustPanel(
                        image: _currentImage.value!,
                        imageId: widget.imageId,
                        onImageChanged: (value, parameters) {
                          _updateImage(
                            value,
                            action: localizations?.adjust ?? 'Корректировка',
                            operationType: 'Adjustments',
                            parameters: parameters,
                          );
                        },
                        onClose: _closeToolPanel,
                        onUpdateImage: _updateImage,
                      );
                    case 'draw':
                      return DrawPanel(
                        image: _currentImage.value!,
                        onCancel: _closeToolPanel,
                        onApply: (drawnImage) {
                          _updateImage(drawnImage,
                              action: 'Рисование',
                              operationType: 'Draw',
                              parameters: {});
                          _closeToolPanel();
                        },
                        onUpdateImage: _updateImage,
                        imageId: widget.imageId,
                      );
                    case 'text':
                      return TextEditorPanel(
                        image: _currentImage.value!,
                        imageId: widget.imageId,
                        onCancel: _closeToolPanel,
                        onApply: (textImage) {
                          _updateImage(textImage,
                              action: 'Текст',
                              operationType: 'Text',
                              parameters: {});
                          _closeToolPanel();
                        },
                        onUpdateImage: _updateImage,
                      );
                    case 'emoji':
                      return EmojiPanel(
                        image: _currentImage.value!,
                        imageId: widget.imageId,
                        onCancel: _closeToolPanel,
                        onApply: (emojiImage) {
                          _updateImage(emojiImage,
                              action: 'Эмодзи',
                              operationType: 'Emoji',
                              parameters: {});
                          _closeToolPanel();
                        },
                        onUpdateImage: _updateImage,
                      );
                    case 'effects':
                      return EffectsPanel(
                        image: _currentImage.value!,
                        imageId: widget.imageId,
                        onCancel: _closeToolPanel,
                        onApply: (effectsImage) {
                          _updateImage(effectsImage,
                              action: 'Эффекты',
                              operationType: 'Effects',
                              parameters: {});
                          _closeToolPanel();
                        },
                      );
                    case 'eraser':
                      return EraserPanel(
                        image: _currentImage.value!,
                        imageId: widget.imageId,
                        onCancel: _closeToolPanel,
                        onApply: (eraserImage) {
                          _updateImage(eraserImage,
                              action: 'Ластик',
                              operationType: 'Eraser',
                              parameters: {});
                          _closeToolPanel();
                        },
                        onUpdateImage: _updateImage,
                      );
                    case 'background':
                      return BackgroundPanel(
                        image: _currentImage.value!,
                        imageId: widget.imageId,
                        onCancel: _closeToolPanel,
                        onApply: (bgImage) {
                          _updateImage(bgImage,
                              action: 'Фон',
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

  Future<Uint8List> captureImage() async {
    try {
      if (_currentImage.value == null || _currentImage.value!.isEmpty) {
        throw Exception(
            AppLocalizations.of(context)?.error ?? 'Изображение недоступно');
      }
      return Uint8List.fromList(_currentImage.value!);
    } catch (e, stackTrace) {
      debugPrint('Ошибка захвата байтов изображения: $e\nСтек: $stackTrace');
      rethrow;
    }
  }
}
