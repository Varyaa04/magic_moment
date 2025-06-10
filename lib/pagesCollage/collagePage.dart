import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import '../pagesSettings/classesSettings/app_localizations.dart';
import 'photosCollage.dart';
import '../themeWidjets/image_picker_helper.dart';
import '../pagesEditing/editPage.dart';
import '../themeWidjets/colorPicker.dart';
import 'templatePreview.dart';

class CollageEditorPage extends StatefulWidget {
  final List<Uint8List> images;
  const CollageEditorPage({super.key, required this.images});

  @override
  State<CollageEditorPage> createState() => _CollageEditorPageState();
}

class _CollageEditorPageState extends State<CollageEditorPage>
    with TickerProviderStateMixin {
  final ValueNotifier<Color> _backgroundColor =
      ValueNotifier(Colors.grey[900]!);
  final ValueNotifier<Uint8List?> _backgroundImage = ValueNotifier(null);
  final ValueNotifier<double> _borderRadius = ValueNotifier(16.0);
  final ValueNotifier<double> _borderWidth = ValueNotifier(2.0);
  final ValueNotifier<bool> _showBorder =
      ValueNotifier(true);
  final ValueNotifier<Color> _borderColor = ValueNotifier(Colors.white);
  final GlobalKey _collageKey = GlobalKey();
  final ValueNotifier<int> _selectedTemplateIndex = ValueNotifier(0);
  final ValueNotifier<int> _currentTabIndex = ValueNotifier(0);
  final ValueNotifier<int?> _selectedImageIndex = ValueNotifier(null);
  late List<Uint8List> _mutableImages;
  late List<Offset> _imagePositions;
  late List<double> _imageScales;
  late List<double> _imageRotations;
  late AnimationController _animationController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _mutableImages = List.from(widget.images);
// Проверяем, предоставлено ли более 6 изображений, и показываем предупреждение
if (_mutableImages.length > 6) {
      _mutableImages = _mutableImages.take(6).toList();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showImageLimitWarning();
      });
    }
    _imagePositions = List.generate(_mutableImages.length, (_) => Offset.zero);
    _imageScales = List.generate(_mutableImages.length, (_) => 1.0);
    _imageRotations = List.generate(_mutableImages.length, (_) => 0.0);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _currentTabIndex.value,
    );

    _tabController.addListener(() {
      _currentTabIndex.value = _tabController.index;
    });

    _preResizeImages();
  }

  Future<void> _showImageLimitWarning() async {
    final appLocalizations = AppLocalizations.of(context);
    if (mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[850],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            appLocalizations?.warning ?? 'Предупреждение',
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            appLocalizations?.imageLimitWarning ??
                'Коллажи поддерживают от 2 до 6 изображений. Вы выбрали больше 6 изображений. Будут использованы только первые 6.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                appLocalizations?.ok ?? 'OK',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _backgroundColor.dispose();
    _backgroundImage.dispose();
    _borderRadius.dispose();
    _borderWidth.dispose();
    _showBorder.dispose();
    _borderColor.dispose();
    _selectedTemplateIndex.dispose();
    _currentTabIndex.dispose();
    _selectedImageIndex.dispose();
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _addImage() async {
    if (_mutableImages.length >= 6) {
      _showErrorSnackBar(AppLocalizations.of(context)!.tooManyImages);
      return;
    }
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      final bytes = await ImagePickerHelper.pickImage();
      Navigator.pop(context);
      if (bytes != null && bytes.isNotEmpty) {
        debugPrint('Adding image: size=${bytes.length} bytes');
        setState(() {
          _mutableImages.add(_resizeImage(bytes));
          _syncLists();
          debugPrint(
              'Images count: ${_mutableImages.length}, last image size=${bytes.length} bytes');
        });
      } else {
        _showErrorSnackBar(AppLocalizations.of(context)!.noImages);
      }
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar('${AppLocalizations.of(context)!.errorPickImage}: $e');
    }
  }

  Uint8List _resizeImage(Uint8List bytes) {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) {
        debugPrint('Failed to decode image');
        return bytes;
      }
      debugPrint(
          'Original image: width=${image.width}, height=${image.height}');
      if (image.width > 800 || image.height > 800) {
        final resized = img.copyResize(image,
            width: 800, height: 800, maintainAspect: true);
        final result = img.encodePng(resized);
        debugPrint('Resized image: size=${result.length} bytes');
        return result;
      }
      return bytes;
    } catch (e) {
      debugPrint('Image resizing error: $e');
      return bytes;
    }
  }

  Future<void> _preResizeImages() async {
    for (var i = 0; i < _mutableImages.length; i++) {
      _mutableImages[i] =
          await Future.microtask(() => _resizeImage(_mutableImages[i]));
    }
    setState(() {
      _syncLists();
    });
  }

  void _syncLists() {
    final newLength = _mutableImages.length;
    final oldLength = _imagePositions.length;

    final newPositions = List<Offset>.generate(newLength, (index) {
      return index < oldLength ? _imagePositions[index] : Offset.zero;
    });
    final newScales = List<double>.generate(newLength, (index) {
      return index < oldLength ? _imageScales[index] : 1.0;
    });
    final newRotations = List<double>.generate(newLength, (index) {
      return index < oldLength ? _imageRotations[index] : 0.0;
    });

    _imagePositions = newPositions;
    _imageScales = newScales;
    _imageRotations = newRotations;
    debugPrint(
        'Synced lists: positions=$newPositions, scales=$newScales, rotations=$newRotations');
  }

  Future<void> _pickBackgroundImage() async {
    try {
      final bytes = await ImagePickerHelper.pickImage();
      if (bytes != null) {
        _backgroundImage.value = _resizeImage(bytes);
        _backgroundColor.value = Colors.grey[900]!;
        setState(() {});
      }
    } catch (e) {
      _showErrorSnackBar('${AppLocalizations.of(context)!.errorPickImage}: $e');
    }
  }

  void _changeBackgroundColor(Color color) {
    _backgroundColor.value = color;
    _backgroundImage.value = null;
    setState(() {});
  }

  void _changeBorderColor(Color color) {
    _borderColor.value = color;
    debugPrint(
        'Selected border color: #${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}');
    setState(() {});
  }

  void _resetImage(int index) {
    _imagePositions[index] = Offset.zero;
    _imageScales[index] = 1.0;
    _imageRotations[index] = 0.0;
    _selectedImageIndex.value = null;
    setState(() {});
  }

  Future<void> _replaceImage(int index) async {
    try {
      final bytes = await ImagePickerHelper.pickImage();
      if (bytes != null && bytes.isNotEmpty) {
        setState(() {
          _mutableImages[index] = _resizeImage(bytes);
          _syncLists();
        });
      } else {
        _showErrorSnackBar(AppLocalizations.of(context)!.noImages);
      }
    } catch (e) {
      _showErrorSnackBar('${AppLocalizations.of(context)!.errorPickImage}: $e');
    }
  }

  Future<void> _deleteImage(int index) async {
    if (_mutableImages.length <= 2) {
      _showErrorSnackBar(AppLocalizations.of(context)!.tooFewImages);
      return;
    }
    setState(() {
      _mutableImages.removeAt(index);
      _syncLists();
      _selectedImageIndex.value = null;
    });
  }

  Future<void> _exportAndEdit() async {
    try {
      _selectedImageIndex.value = null;
      await Future.delayed(const Duration(milliseconds: 50));

      final boundary = _collageKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        _showErrorSnackBar(AppLocalizations.of(context)!.processingError);
        return;
      }

      final pixelRatio =
          MediaQuery.of(context).devicePixelRatio.clamp(2.0, 3.0);
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _showErrorSnackBar(AppLocalizations.of(context)!.processingError);
        return;
      }
      final bytes = byteData.buffer.asUint8List();

      final decodedImage = img.decodePng(bytes);
      if (decodedImage == null) {
        _showErrorSnackBar(AppLocalizations.of(context)!.processingError);
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditPage(
              imageBytes: bytes,
              imageId: DateTime.now().microsecondsSinceEpoch,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Export error: $e');
      _showErrorSnackBar(
          '${AppLocalizations.of(context)!.processingError}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final collageSize = math
            .min(screenWidth * 0.85, screenHeight * 0.65)
            .clamp(300.0, 700.0);

        return Scaffold(
          backgroundColor: Colors.grey[900],
          appBar: AppBar(
            backgroundColor: Colors.grey[850],
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: _showExitDialog,
            ),
            title: Text(
              AppLocalizations.of(context)!.collage,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.check, color: Colors.greenAccent),
                onPressed: _exportAndEdit,
                tooltip: AppLocalizations.of(context)!.save,
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Center(
                  child: RepaintBoundary(
                    key: _collageKey,
                    child: ValueListenableBuilder(
                      valueListenable: _backgroundColor,
                      builder: (context, bgColor, _) {
                        return ValueListenableBuilder(
                          valueListenable: _backgroundImage,
                          builder: (context, bgImage, _) {
                            return ValueListenableBuilder(
                              valueListenable: _borderRadius,
                              builder: (context, radius, _) {
                                return ValueListenableBuilder(
                                  valueListenable: _borderWidth,
                                  builder: (context, width, _) {
                                    return ValueListenableBuilder(
                                      valueListenable: _showBorder,
                                      builder: (context, showBorder, _) {
                                        return ValueListenableBuilder(
                                          valueListenable: _borderColor,
                                          builder: (context, borderColor, _) {
                                            return AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              width: collageSize,
                                              height: collageSize,
                                              margin: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: bgImage == null
                                                    ? bgColor
                                                    : null,
                                                image: bgImage != null
                                                    ? DecorationImage(
                                                        image: MemoryImage(
                                                            bgImage),
                                                        fit: BoxFit.cover,
                                                      )
                                                    : null,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        radius),
                                                border: showBorder
                                                    ? Border.all(
                                                        color: borderColor,
                                                        width: width,
                                                      )
                                                    : null,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.4),
                                                    blurRadius: 20,
                                                    spreadRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        radius),
                                                child: PhotosCollage(
                                                  images: _mutableImages
                                                      .map(
                                                          (e) => MemoryImage(e))
                                                      .toList(),
                                                  templateIndex:
                                                      _selectedTemplateIndex
                                                          .value,
                                                  imageCount:
                                                      _mutableImages.length,
                                                  borderColor: showBorder
                                                      ? _borderColor.value
                                                      : Colors.transparent,
                                                  positions: _imagePositions,
                                                  scales: _imageScales,
                                                  rotations: _imageRotations,
                                                  onPositionChanged:
                                                      (index, offset) {
                                                    _imagePositions[index] =
                                                        offset;
                                                    setState(() {});
                                                  },
                                                  onScaleChanged:
                                                      (index, scale) {
                                                    _imageScales[index] = scale;
                                                    setState(() {});
                                                  },
                                                  onRotationChanged:
                                                      (index, rotation) {
                                                    _imageRotations[index] =
                                                        rotation;
                                                    setState(() {});
                                                  },
                                                  onImageTapped: (index) {
                                                    _selectedImageIndex.value =
                                                        index;
                                                  },
                                                  selectedImageIndex:
                                                      _selectedImageIndex,
                                                  selectedImageDecoration:
                                                      (index) => index ==
                                                              _selectedImageIndex
                                                                  .value
                                                          ? BoxDecoration(
                                                              border:
                                                                  Border.all(
                                                                color:
                                                                    Colors.pink,
                                                                width: 3,
                                                              ),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: Colors
                                                                      .black
                                                                      .withOpacity(
                                                                          0.3),
                                                                  blurRadius: 8,
                                                                  spreadRadius:
                                                                      2,
                                                                ),
                                                              ],
                                                            )
                                                          : null,
                                                  borderWidth: showBorder
                                                      ? _borderWidth.value
                                                      : 0.0,
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
              Container(
                height: isMobile ? 320 : 360,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey[850]!, Colors.grey[800]!],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[700]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey[400],
                        indicator: const UnderlineTabIndicator(
                          borderSide: BorderSide(
                            width: 3,
                            color: Colors.blueAccent,
                          ),
                        ),
                        labelStyle:
                            const TextStyle(fontWeight: FontWeight.w600),
                        tabs: [
                          Tab(
                              icon: const Icon(Icons.grid_view),
                              text: AppLocalizations.of(context)!.template),
                          Tab(
                              icon: const Icon(Icons.tune),
                              text: AppLocalizations.of(context)!.edit),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTemplateTab(isMobile),
                          _buildEditorTab(isMobile),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  Widget _buildImageTools(int selectedIndex) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[850]!, Colors.grey[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolButton(
            icon: Icons.zoom_in,
            tooltip: AppLocalizations.of(context)!.zoomIn,
            onPressed: () {
              _imageScales[selectedIndex] =
                  (_imageScales[selectedIndex] + 0.1).clamp(0.5, 2.0);
              setState(() {});
            },
          ),
          _buildToolButton(
            icon: Icons.zoom_out,
            tooltip: AppLocalizations.of(context)!.zoomOut,
            onPressed: () {
              _imageScales[selectedIndex] =
                  (_imageScales[selectedIndex] - 0.1).clamp(0.5, 2.0);
              setState(() {});
            },
          ),
          _buildToolButton(
            icon: Icons.rotate_left,
            tooltip: AppLocalizations.of(context)!.rotateLeft,
            onPressed: () {
              _imageRotations[selectedIndex] -= 15 * math.pi / 180;
              setState(() {});
            },
          ),
          _buildToolButton(
            icon: Icons.rotate_right,
            tooltip: AppLocalizations.of(context)!.rotateRight,
            onPressed: () {
              _imageRotations[selectedIndex] += 15 * math.pi / 180;
              setState(() {});
            },
          ),
          _buildToolButton(
            icon: Icons.refresh,
            tooltip: AppLocalizations.of(context)!.reset,
            onPressed: () => _resetImage(selectedIndex),
          ),
          _buildToolButton(
            icon: Icons.image,
            tooltip: AppLocalizations.of(context)!.replace,
            onPressed: () => _replaceImage(selectedIndex),
          ),
          _buildToolButton(
            icon: Icons.delete,
            tooltip: AppLocalizations.of(context)!.delete,
            onPressed: () => _deleteImage(selectedIndex),
          ),
        ],
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          AppLocalizations.of(context)!.exit,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          AppLocalizations.of(context)!.unsavedChangesWarning,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              AppLocalizations.of(context)!.exit,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateTab(bool isMobile) {
    return ValueListenableBuilder(
      valueListenable: _selectedTemplateIndex,
      builder: (context, selectedIndex, _) {
        if (_mutableImages.length < 2) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.image, color: Colors.grey, size: 48),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.tooFewImages,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 3 : 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: 10,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                _selectedTemplateIndex.value = index;
                setState(() {
                  _syncLists();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selectedIndex == index
                        ? Colors.blueAccent
                        : Colors.grey[600]!,
                    width: selectedIndex == index ? 3 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: TemplatePreview(
                    imageCount: _mutableImages.length,
                    templateIndex: index,
                    borderColor: _showBorder.value
                        ? _borderColor.value
                        : Colors.transparent,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEditorTab(bool isMobile) {
    return ValueListenableBuilder(
      valueListenable: _selectedImageIndex,
      builder: (context, selectedIndex, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedIndex != null) ...[
                _buildImageTools(selectedIndex),
                const SizedBox(height: 16),
              ],
              _buildAddPhotoButton(),
              const SizedBox(height: 16),
              _buildBackgroundOptions(),
              const SizedBox(height: 16),
              _buildBorderOptions(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddPhotoButton() {
    return Row(
      children: [
        Text(
          '${AppLocalizations.of(context)!.addPhoto}:',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _addImage,
          icon: const Icon(Icons.add_photo_alternate, size: 20),
          label: Text(AppLocalizations.of(context)!.addPhoto),
        ),
      ],
    );
  }

  Widget _buildBackgroundOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${AppLocalizations.of(context)!.background}:',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: _pickBackgroundImage,
              child: ValueListenableBuilder(
                valueListenable: _backgroundImage,
                builder: (context, bgImage, _) {
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[500]!, width: 1),
                      image: bgImage != null
                          ? DecorationImage(
                              image: MemoryImage(bgImage),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: bgImage == null
                        ? const Center(
                            child:
                                Icon(Icons.image, color: Colors.grey, size: 28),
                          )
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (context) => _buildColorPickerDialog(
                  AppLocalizations.of(context)!.background,
                  _backgroundColor,
                  _changeBackgroundColor,
                ),
              ),
              child: ValueListenableBuilder(
                valueListenable: _backgroundColor,
                builder: (context, color, _) {
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[500]!, width: 1),
                    ),
                    child: const Center(
                      child: Icon(Icons.color_lens, color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBorderOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${AppLocalizations.of(context)!.borderOptions}:',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${AppLocalizations.of(context)!.showBorder}:',
              style: const TextStyle(color: Colors.white70),
            ),
            ValueListenableBuilder(
              valueListenable: _showBorder,
              builder: (context, showBorder, _) {
                return Switch(
                  value: showBorder,
                  activeColor: Colors.blueAccent,
                  onChanged: (val) {
                    _showBorder.value = val;
                    setState(() {});
                  },
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder(
          valueListenable: _showBorder,
          builder: (context, showBorder, _) {
            return Column(
              children: [
                if (showBorder) ...[
                  Row(
                    children: [
                      Text(
                        '${AppLocalizations.of(context)!.color}:',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => showDialog(
                          context: context,
                          builder: (context) => _buildColorPickerDialog(
                            AppLocalizations.of(context)!.borderColor,
                            _borderColor,
                            _changeBorderColor,
                          ),
                        ),
                        child: ValueListenableBuilder(
                          valueListenable: _borderColor,
                          builder: (context, color, _) {
                            return Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '${AppLocalizations.of(context)!.borderWidth}:',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: _borderWidth,
                          builder: (context, width, _) {
                            return Slider(
                              min: 0.0,
                              max: 8.0,
                              divisions: 80,
                              value: width,
                              activeColor: Colors.blueAccent,
                              inactiveColor: Colors.grey[600],
                              label: width.toStringAsFixed(1),
                              onChanged: (val) {
                                _borderWidth.value = val;
                                setState(() {});
                              },
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Center(
                          child: ValueListenableBuilder(
                            valueListenable: _borderWidth,
                            builder: (context, width, _) {
                              return Text(
                                width.toStringAsFixed(1),
                                style: const TextStyle(color: Colors.white),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${AppLocalizations.of(context)!.borderRadius}:',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ValueListenableBuilder(
                        valueListenable: _borderRadius,
                        builder: (context, radius, _) {
                          return Slider(
                            min: 0.0,
                            max: 40.0,
                            divisions: 40,
                            value: radius,
                            activeColor: Colors.blueAccent,
                            inactiveColor: Colors.grey[600],
                            label: radius.toStringAsFixed(1),
                            onChanged: (val) {
                              _borderRadius.value = val;
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Center(
                        child: ValueListenableBuilder(
                          valueListenable: _borderRadius,
                          builder: (context, radius, _) {
                            return Text(
                              radius.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildColorPickerDialog(
    String title,
    ValueNotifier<Color> colorNotifier,
    void Function(Color) onColorChanged,
  ) {
    return Dialog(
      backgroundColor: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: ColorPicker(
                pickerColor: colorNotifier.value,
                onColorChanged: onColorChanged,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    AppLocalizations.of(context)!.cancel,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.apply),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.grey[600]!, Colors.grey[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
