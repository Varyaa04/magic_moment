import 'dart:io';
import 'dart:ui' as ui;
import 'package:MagicMoment/pagesCollage/collagePage.dart';
import 'package:MagicMoment/pagesEditing/editPage.dart';
import 'package:MagicMoment/pagesSettings/settingsPage.dart';
import 'package:MagicMoment/themeWidjets/buildButtonIcon.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart' as mobile_picker;
import 'themeWidjets/image_picker_helper.dart';
import 'package:MagicMoment/database/magicMomentDatabase.dart';
import 'package:MagicMoment/database/editHistoryManager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

// Перечислитель для типов разрешений
enum PermissionType { camera, gallery }

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

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  List<Uint8List> selectedImages = [];
  final LRUCache<int, Uint8List> _snapshotCache = LRUCache(20);
  bool _isCheckingPermissions = false;

  @override
  void initState() {
    super.initState();
  }

  // Пояснительный диалог перед запросом разрешения
  Future<bool> _showPermissionRationale(BuildContext context, PermissionType type) async {
    final appLocalizations = AppLocalizations.of(context);
    String title;
    String message;

    switch (type) {
      case PermissionType.camera:
        title = appLocalizations?.cameraPermissionTitle ?? 'Camera Permission';
        message = appLocalizations?.cameraPermissionMessage ??
            'This app needs camera access to take photos for editing.';
        break;
      case PermissionType.gallery:
        title = appLocalizations?.galleryPermissionTitle ?? 'Gallery Permission';
        message = appLocalizations?.galleryPermissionMessage ??
            'This app needs gallery access to select photos for editing or collage creation.';
        break;
    }

    if (mounted) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(appLocalizations?.cancel ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(appLocalizations?.continueText ?? 'Continue'),
            ),
          ],
        ),
      );
      return result ?? false;
    }
    return false;
  }

  Future<bool> _requestPermission(BuildContext context, PermissionType type, {bool showDialog = true}) async {
    final appLocalizations = AppLocalizations.of(context);
    Permission permission;
    String permissionName;

    switch (type) {
      case PermissionType.camera:
        if (kIsWeb) return true;
        permission = Permission.camera;
        permissionName = appLocalizations?.camera ?? 'camera';
        break;
      case PermissionType.gallery:
        if (Platform.isAndroid) {
          final androidInfo = await DeviceInfoPlugin().androidInfo;
          if (androidInfo.version.sdkInt >= 33) {
            permission = Permission.photos;
          } else {
            permission = Permission.storage;
          }
        } else {
          permission = Permission.photos;
        }
        permissionName = appLocalizations?.gallery ?? 'gallery';
        break;
    }

    final status = await permission.status;
    debugPrint('Permission $type status: $status');

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied || status.isLimited) {
      if (await _showPermissionRationale(context, type)) {
        final newStatus = await permission.request();
        if (newStatus.isGranted) {
          return true;
        }
      } else {
        return false;
      }
    }

    if (status.isPermanentlyDenied || (await permission.status).isPermanentlyDenied) {
      if (mounted && showDialog) {
        await showDialog;
      }
      return false;
    }

    if (mounted && showDialog) {
      _showSnackBar(
        appLocalizations?.permissionError?.replaceFirst('+', permissionName) ??
            'Failed to access $permissionName. Please try again.',
      );
    }
    return false;
  }

  Future<Uint8List> _compressImage(Uint8List imageBytes, {int quality = 80, int minWidth = 1080}) async {
    try {
      final compressed = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: minWidth,
        minHeight: minWidth,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      debugPrint('Compressed image: original=${imageBytes.length}, compressed=${compressed.length}');
      return compressed;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return imageBytes;
    }
  }

  Future<Uint8List?> _generateSnapshot(Uint8List imageBytes, {int width = 80}) async {
    try {
      final compressed = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: width,
        minHeight: width,
        quality: 60,
        format: CompressFormat.jpeg,
      );
      final codec = await ui.instantiateImageCodec(compressed, targetWidth: width);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      codec.dispose();
      final result = byteData?.buffer.asUint8List();
      if (result == null) {
        debugPrint('Snapshot generation failed: null byteData');
        return null;
      }
      debugPrint('Generated snapshot: size=${result.length} bytes');
      return result;
    } catch (e) {
      debugPrint('Error generating snapshot: $e');
      return null;
    }
  }

  Future<void> _saveSnapshot(int imageId, Uint8List imageBytes) async {
    try {
      final snapshot = await _generateSnapshot(imageBytes);
      if (snapshot == null) {
        throw Exception('Failed to generate snapshot for imageId: $imageId');
      }

      _snapshotCache.put(imageId, snapshot);

      final historyManager = EditHistoryManager(db: MagicMomentDatabase.instance, imageId: imageId);
      await historyManager.loadHistory();

      await historyManager.saveSnapshot(context: context, snapshot: snapshot);
      debugPrint('Snapshot saved for imageId: $imageId');
    } catch (e, stackTrace) {
      debugPrint('Error saving snapshot: $e\n$stackTrace');
      if (mounted) {
        _showError('${AppLocalizations.of(context)?.error ?? 'Error'}: Failed to save snapshot');
      }
    }
  }

  Future<void> _saveToGallery(Uint8List imageBytes) async {
    if (kIsWeb) {
      debugPrint('Saving to gallery is not supported on web');
      return;
    }
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = 'MagicMoment_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      final result = await GallerySaver.saveImage(filePath);
      debugPrint('Image saved to gallery: $result');

      await file.delete();
    } catch (e, stackTrace) {
      debugPrint('Error saving image to gallery: $e\n$stackTrace');
      if (mounted) {
        _showSnackBar('${AppLocalizations.of(context)?.error ?? 'Error'}: Failed to save image to gallery');
      }
    }
  }

  Future<void> getImages() async {
    final appLocalizations = AppLocalizations.of(context);

    if (!kIsWeb) {
      final permission = await Permission.photos.request();
      if (permission.isDenied || permission.isPermanentlyDenied) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(appLocalizations?.permissionDeniedTitle ?? 'Permission Denied'),
            content: Text(appLocalizations?.permissionDenied ?? 'Please grant photo access to select images.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(appLocalizations?.ok ?? 'OK'),
              ),
            ],
          ),
        );
        return;
      }
    }

    try {
      final imageBytesList = await ImagePickerHelper.pickMultiImages(maxImages: 6);
      if (imageBytesList == null || imageBytesList.isEmpty) {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(appLocalizations?.errorTitle ?? 'Error'),
              content: Text(appLocalizations?.noImages ?? 'No images selected'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(appLocalizations?.ok ?? 'OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      List<Uint8List> imagesToUse = imageBytesList;
      if (imageBytesList.length > 6) {
        imagesToUse = imageBytesList.take(6).toList();
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(appLocalizations?.warning ?? 'Warning'),
              content: Text(
                appLocalizations?.tooManyImages ??
                    'You selected ${imageBytesList.length} images. Only the first 6 will be used.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(appLocalizations?.ok ?? 'OK'),
                ),
              ],
            ),
          );
        }
      }

      if (imagesToUse.length < 2) {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(appLocalizations?.errorTitle ?? 'Error'),
              content: Text(
                appLocalizations?.tooFewImages ?? 'Please select at least 2 images for a collage.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(appLocalizations?.ok ?? 'OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      final compressedImages = await Future.wait(
        imagesToUse.map((bytes) => _compressImage(bytes, quality: 72, minWidth: 800)),
      );

      if (!mounted) return;

      debugPrint('Selected ${compressedImages.length} images for collage');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CollageEditorPage(images: compressedImages),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Error selecting images for collage: $e\n$stackTrace');
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(appLocalizations?.errorTitle ?? 'Error'),
            content: Text('${appLocalizations?.error ?? 'An error occurred'}: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(appLocalizations?.ok ?? 'OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _pickImage(mobile_picker.ImageSource source) async {
    try {
      // Проверка разрешений
      bool hasPermission = true;
      if (source == mobile_picker.ImageSource.camera && !kIsWeb) {
        hasPermission = await _requestPermission(context, PermissionType.camera);
      } else if (source == mobile_picker.ImageSource.gallery) {
        hasPermission = await _requestPermission(context, PermissionType.gallery);
      }

      if (!hasPermission) {
        if (mounted) {
          _showSnackBar(
            AppLocalizations.of(context)?.permissionError?.replaceFirst(
                '+',
                source == mobile_picker.ImageSource.camera
                    ? AppLocalizations.of(context)?.camera ?? 'camera'
                    : AppLocalizations.of(context)?.gallery ?? 'gallery') ??
                'Permission denied',
          );
        }
        return;
      }

      final bytes = await ImagePickerHelper.pickImage(source: source);
      debugPrint('Picked image bytes length: ${bytes?.length ?? 0}');

      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)?.noImages ??
                    'No image selected or invalid image data')),
          );
        }
        return;
      }

      if (source == mobile_picker.ImageSource.camera && !kIsWeb) {
        await _saveToGallery(bytes);
      }

      final compressedBytes = await _compressImage(bytes, quality: 80, minWidth: 1080);

      final imageId = DateTime.now().microsecondsSinceEpoch;
      await _saveSnapshot(imageId, compressedBytes);

      if (!mounted) return;

      debugPrint('Picked image for editing: imageId=$imageId, size=${compressedBytes.length} bytes');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditPage(
            imageBytes: compressedBytes,
            imageId: imageId,
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Error picking image: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${AppLocalizations.of(context)?.error ?? 'Error'}: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    final appLocalizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(appLocalizations?.choose ?? 'Choose Image Source'),
          content: Text(appLocalizations?.from ?? 'Select an image from:'),
          actions: [
            if (!kIsWeb)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage(mobile_picker.ImageSource.camera);
                },
                child: Text(appLocalizations?.camera ?? 'Camera'),
              ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImage(mobile_picker.ImageSource.gallery);
              },
              child: Text(appLocalizations?.gallery ?? 'Gallery'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)?.errorTitle ?? 'Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)?.ok ?? 'OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 500;

    if (_isCheckingPermissions) {
      return Scaffold(
        backgroundColor: colorScheme.onInverseSurface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
              const SizedBox(height: 20),
              Text(
                appLocalizations?.permissionRequired ?? 'Requesting permissions...',
                style: TextStyle(
                  color: colorScheme.onSecondary,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: colorScheme.onInverseSurface,
        child: Row(
          children: [
            Container(
              width: isSmallScreen ? screenWidth * 0.6 : screenWidth * 0.7,
              padding: const EdgeInsets.only(top: 100),
              margin: const EdgeInsets.only(top: 50),
              child: Image.asset(
                'lib/assets/icons/photos.png',
                fit: BoxFit.fitHeight,
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    margin: EdgeInsets.only(
                      top: isSmallScreen ? 30 : 40,
                      right: isSmallScreen ? 15 : 25,
                    ),
                    child: IconButton(
                      iconSize: isSmallScreen ? 35 : 35,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings),
                      color: colorScheme.onSecondary,
                      tooltip: appLocalizations?.settings ?? 'Settings',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    margin: EdgeInsets.only(
                      top: isSmallScreen ? 20 : 40,
                      right: isSmallScreen ? 15 : 25,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Magic Moment',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getResponsiveFontSize(context, isSmallScreen ? 32 : 36),
                            color: colorScheme.onSecondary,
                            fontFamily: 'LilitaOne-Regular',
                          ),
                        ),
                        Container(
                          width: isSmallScreen ? 200 : 350,
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            appLocalizations?.challengeText ??
                                'Create unique moments with our application!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize:
                              ResponsiveUtils.getResponsiveFontSize(context, isSmallScreen ? 15 : 18),
                              color: colorScheme.onSecondary,
                              fontFamily: 'PTSansNarrow-Regular',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(
                      top: isSmallScreen ? 15 : 20,
                      right: isSmallScreen ? 15 : 25,
                    ),
                    child: Column(
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: isSmallScreen ? 350 : 400),
                          child: CustomButton(
                            onPressed: _showImageSourceDialog,
                            text: appLocalizations?.change ?? 'Edit Photo',
                            icon: FluentIcons.image_24_regular,
                            isSmall: isSmallScreen,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: isSmallScreen ? 350 : 400),
                          child: CustomButton(
                            onPressed: getImages,
                            text: appLocalizations?.create ?? 'Create',
                            secondaryText: appLocalizations?.collage ?? 'Collage',
                            icon: FluentIcons.layout_column_two_split_left_24_regular,
                            isSmall: isSmallScreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _snapshotCache.clear();
    super.dispose();
  }
}