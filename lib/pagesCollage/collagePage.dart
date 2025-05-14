import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/rendering.dart';
import 'package:MagicMoment/pagesEditing/editPage.dart';
import 'package:MagicMoment/pagesCollage/templates/2photosCollage.dart';
import 'package:MagicMoment/pagesCollage/templates/3photosCollage.dart';
import 'package:MagicMoment/pagesCollage/templates/4photosCollage.dart';
import 'package:MagicMoment/pagesCollage/templates/5photosCollage.dart';
import 'package:MagicMoment/pagesCollage/templates/6photosCollage.dart';
import '../pagesEditing/imageUtils.dart';
import '../pagesSettings/classesSettings/app_localizations.dart';
import '../themeWidjets/colorPicker.dart';
import 'package:image/image.dart' as img;

class CollageEditorPage extends StatefulWidget {
  final List<Uint8List> images;
  const CollageEditorPage({super.key, required this.images});

  @override
  State<CollageEditorPage> createState() => _CollageEditorPageState();
}

class _CollageEditorPageState extends State<CollageEditorPage>
    with SingleTickerProviderStateMixin {
  Color _backgroundColor = Colors.grey[900]!;
  Uint8List? _backgroundImage;
  double _borderRadius = 12;
  double _borderWidth = 2;
  Color _borderColor = Colors.blueAccent;
  final GlobalKey _collageKey = GlobalKey();
  int _selectedTemplateIndex = 0;
  late List<Widget> _templates;
  int _currentTabIndex = 0;
  late List<Offset> _imagePositions;
  late List<double> _imageScales;
  late List<double> _imageRotations;
  int? _selectedImageIndex;
  late List<Uint8List?> _mutableImages;
  late AnimationController _animationController;
  late Animation<double> _tabAnimation;
  List<Widget>? _templateCache;

  @override
  void initState() {
    super.initState();
    _mutableImages = widget.images.map((e) => _resizeImage(e)).toList();
    _imagePositions = List.generate(_mutableImages.length, (_) => Offset.zero);
    _imageScales = List.generate(_mutableImages.length, (_) => 1.0);
    _imageRotations = List.generate(_mutableImages.length, (_) => 0.0);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _tabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _templates = _generateTemplates();
    _templateCache = _templates;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Uint8List? _resizeImage(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;
    if (image.width > 1024 || image.height > 1024) {
      final resized = img.copyResizeCropSquare(image, size: 1024);
      return img.encodePng(resized);
    }
    return bytes;
  }

  List<Widget> _generateTemplates() {
    final localizations = AppLocalizations.of(context)!;
    if (_mutableImages.isEmpty ||
        _mutableImages.every((image) => image == null)) {
      return [
        Container(
          color: Colors.grey[700],
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.image, color: Colors.grey, size: 48),
                const SizedBox(height: 8),
                Text(
                  localizations.addPhoto,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          ),
        )
      ];
    }

    final providers = _mutableImages
        .asMap()
        .entries
        .where((entry) => entry.value != null)
        .map((entry) => MemoryImage(entry.value!))
        .toList();
    final validImageCount = providers.length;

    if (validImageCount < 2) {
      return [
        Container(
          color: Colors.grey[700],
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.image, color: Colors.grey, size: 48),
                const SizedBox(height: 8),
                Text(
                  localizations.tooFewImages,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          ),
        )
      ];
    }

    final templateParams = [
      providers,
      _borderColor,
      _imagePositions.take(validImageCount).toList(),
      _imageScales.take(validImageCount).toList(),
      _imageRotations.take(validImageCount).toList(),
          (int index, Offset offset) {
        setState(() {
          _imagePositions[index] = Offset(
            offset.dx.clamp(-0.5, 0.5),
            offset.dy.clamp(-0.5, 0.5),
          );
        });
      },
          (int index, double scale) {
        setState(() {
          _imageScales[index] = scale.clamp(0.5, 2.0);
        });
      },
          (int index, double rotation) {
        setState(() {
          _imageRotations[index] = rotation;
        });
      },
          (int index) {
        setState(() {
          _selectedImageIndex = index;
        });
      },
          (int index) => index == _selectedImageIndex
          ? BoxDecoration(
        border: Border.all(color: Colors.yellow, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.yellow.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      )
          : null,
    ];

    switch (validImageCount) {
      case 2:
        return List.generate(
          10,
              (i) => TwoPhotosCollage(
            images: providers,
            layoutIndex: i,
            borderColor: _borderColor,
            positions: templateParams[2] as List<Offset>,
            scales: templateParams[3] as List<double>,
            rotations: templateParams[4] as List<double>,
            onPositionChanged: templateParams[5] as Function(int, Offset),
            onScaleChanged: templateParams[6] as Function(int, double),
            onRotationChanged: templateParams[7] as Function(int, double),
            onImageTapped: templateParams[8] as Function(int),
            selectedImageIndex: _selectedImageIndex,
            selectedImageDecoration: templateParams[9] as BoxDecoration? Function(int),
          ),
        );
      case 3:
        return List.generate(
          10,
              (i) => ThreePhotosCollage(
            images: providers,
            templateIndex: i,
            borderColor: _borderColor,
            positions: templateParams[2] as List<Offset>,
            scales: templateParams[3] as List<double>,
            rotations: templateParams[4] as List<double>,
            onPositionChanged: templateParams[5] as Function(int, Offset),
            onScaleChanged: templateParams[6] as Function(int, double),
            onRotationChanged: templateParams[7] as Function(int, double),
            onImageTapped: templateParams[8] as Function(int),
            selectedImageIndex: _selectedImageIndex,
            selectedImageDecoration: templateParams[9] as BoxDecoration? Function(int),
          ),
        );
      case 4:
        return FourPhotosCollageTemplates.build(
          templateParams[0] as List<ImageProvider>,
          templateParams[1] as Color,
          templateParams[2] as List<Offset>,
          templateParams[3] as List<double>,
          templateParams[4] as List<double>,
          templateParams[5] as Function(int, Offset),
          templateParams[6] as Function(int, double),
          templateParams[7] as Function(int, double),
          templateParams[8] as Function(int),
          _selectedImageIndex,
          templateParams[9] as BoxDecoration? Function(int),
        );
      case 5:
        return FivePhotosTemplates.getTemplates(
          templateParams[0] as List<ImageProvider>,
          templateParams[1] as Color,
          templateParams[2] as List<Offset>,
          templateParams[3] as List<double>,
          templateParams[4] as List<double>,
          templateParams[5] as Function(int, Offset),
          templateParams[6] as Function(int, double),
          templateParams[7] as Function(int, double),
          templateParams[8] as Function(int),
          _selectedImageIndex,
          templateParams[9] as BoxDecoration? Function(int),
        );
      case 6:
        return SixPhotosTemplates.getTemplates(
          templateParams[0] as List<ImageProvider>,
          templateParams[1] as Color,
          templateParams[2] as List<Offset>,
          templateParams[3] as List<double>,
          templateParams[4] as List<double>,
          templateParams[5] as Function(int, Offset),
          templateParams[6] as Function(int, double),
          templateParams[7] as Function(int, double),
          templateParams[8] as Function(int),
          _selectedImageIndex,
          templateParams[9] as BoxDecoration? Function(int),
        );
      default:
        return [
          Container(
            color: Colors.grey[700],
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.image, color: Colors.grey, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    localizations.tooFewImages,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          )
        ];
    }
  }

  Future<void> _pickBackgroundImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _backgroundImage = _resizeImage(bytes);
        _backgroundColor = Colors.grey[900]!;
      });
    }
  }

  void _changeBackgroundColor(Color color) {
    setState(() {
      _backgroundColor = color;
      _backgroundImage = null;
    });
  }

  void _changeBorderColor(Color color) {
    setState(() {
      _borderColor = color;
      _templates = _generateTemplates();
      _templateCache = _templates;
    });
  }

  void _resetImage(int index) {
    setState(() {
      _imagePositions[index] = Offset.zero;
      _imageScales[index] = 1.0;
      _imageRotations[index] = 0.0;
    });
  }

  Future<void> _replaceImage(int index) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _mutableImages[index] = _resizeImage(bytes);
        _templates = _generateTemplates();
        _templateCache = _templates;
      });
    }
  }

  void _deleteImage(int index) {
    final localizations = AppLocalizations.of(context)!;
    setState(() {
      _mutableImages.removeAt(index);
      _imagePositions.removeAt(index);
      _imageScales.removeAt(index);
      _imageRotations.removeAt(index);
      _selectedImageIndex = null;
      _templates = _generateTemplates();
      _templateCache = _templates;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.remove)),
      );
    });
  }

  Future<void> _addImage() async {
    final localizations = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        if (_mutableImages.length < 6) {
          _mutableImages.add(_resizeImage(bytes));
          _imagePositions.add(Offset.zero);
          _imageScales.add(1.0);
          _imageRotations.add(0.0);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.tooManyImages)),
          );
        }
        _templates = _generateTemplates();
        _templateCache = _templates;
      });
    }
  }

  Future<void> _exportAndEdit() async {
    final localizations = AppLocalizations.of(context)!;
    try {
      final imageBytes = await saveImage(_collageKey);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditPage(
            imageBytes: imageBytes,
            imageId: DateTime.now().microsecondsSinceEpoch,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error exporting collage: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localizations.error}: $e'),
          backgroundColor: Colors.red[800],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final collageSize = math.min(screenWidth * 0.8, screenHeight * 0.6)
            .clamp(300.0, 600.0);

        final buttonStyle = ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[800],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        );

        return DefaultTabController(
          length: 2,
          initialIndex: _currentTabIndex,
          child: Scaffold(
            backgroundColor: Colors.grey[900],
            appBar: AppBar(
              backgroundColor: Colors.grey[900],
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(localizations.warning),
                      content: Text(localizations.unsavedChangesWarning),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(localizations.cancel),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: Text(localizations.yes),
                        ),
                      ],
                    ),
                  );
                },
                tooltip: localizations.back,
              ),
              title: Text(
                localizations.collage,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              actions: [
                ElevatedButton.icon(
                  style: buttonStyle,
                  onPressed: _exportAndEdit,
                  icon: const Icon(Icons.check, size: 20),
                  label: Text(localizations.apply),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: Center(
                    child: RepaintBoundary(
                      key: _collageKey,
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Container(
                          width: collageSize,
                          height: collageSize,
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _backgroundImage == null
                                ? _backgroundColor
                                : null,
                            image: _backgroundImage != null
                                ? DecorationImage(
                              image: MemoryImage(_backgroundImage!),
                              fit: BoxFit.cover,
                            )
                                : null,
                            borderRadius: BorderRadius.circular(_borderRadius),
                            border: Border.all(
                              color: _borderColor,
                              width: _borderWidth,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRect(
                            child: _templates[_selectedTemplateIndex],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  color: Colors.grey[900],
                  child: Column(
                    children: [
                      TabBar(
                        onTap: (index) {
                          setState(() {
                            _currentTabIndex = index;
                          });
                          _animationController.forward(from: 0);
                        },
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey[400],
                        indicatorColor: _borderColor,
                        labelStyle:
                        const TextStyle(fontWeight: FontWeight.bold),
                        tabs: [
                          Tab(text: localizations.template),
                          Tab(text: localizations.edit),
                        ],
                      ),
                      FadeTransition(
                        opacity: _tabAnimation,
                        child: SizedBox(
                          height: isMobile ? 350 : 400,
                          child: TabBarView(
                            children: [
                              _buildTemplateTab(isMobile),
                              _buildEditorTab(buttonStyle, isMobile),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTemplateTab(bool isMobile) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 3 : 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _templates.length,
      itemBuilder: (context, index) => GestureDetector(
        onTap: () {
          setState(() {
            _selectedTemplateIndex = index;
            _selectedImageIndex = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _selectedTemplateIndex == index
                  ? _borderColor
                  : Colors.grey[700]!,
              width: _selectedTemplateIndex == index ? 3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRect(
            child: AspectRatio(
              aspectRatio: 1,
              child: _templateCache![index],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditorTab(ButtonStyle buttonStyle, bool isMobile) {
    final localizations = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      child: Column(
        children: [
          if (_selectedImageIndex != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.grey[850],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildToolButton(
                    icon: Icons.zoom_in,
                    tooltip: localizations.size,
                    onPressed: () {
                      setState(() {
                        _imageScales[_selectedImageIndex!] += 0.05;
                        _imageScales[_selectedImageIndex!] =
                            _imageScales[_selectedImageIndex!].clamp(0.5, 2.0);
                      });
                    },
                  ),
                  _buildToolButton(
                    icon: Icons.zoom_out,
                    tooltip: localizations.size,
                    onPressed: () {
                      setState(() {
                        _imageScales[_selectedImageIndex!] -= 0.05;
                        _imageScales[_selectedImageIndex!] =
                            _imageScales[_selectedImageIndex!].clamp(0.5, 2.0);
                      });
                    },
                  ),
                  _buildToolButton(
                    icon: Icons.rotate_left,
                    tooltip: localizations.rotateCrop,
                    onPressed: () {
                      setState(() {
                        _imageRotations[_selectedImageIndex!] -=
                            5 * math.pi / 180; // 5 degrees
                      });
                    },
                  ),
                  _buildToolButton(
                    icon: Icons.rotate_right,
                    tooltip: localizations.rotateCrop,
                    onPressed: () {
                      setState(() {
                        _imageRotations[_selectedImageIndex!] +=
                            5 * math.pi / 180; // 5 degrees
                      });
                    },
                  ),
                  _buildToolButton(
                    icon: Icons.center_focus_strong,
                    tooltip: localizations.reset,
                    onPressed: () => _resetImage(_selectedImageIndex!),
                  ),
                  _buildToolButton(
                    icon: Icons.image,
                    tooltip: localizations.edit,
                    onPressed: () => _replaceImage(_selectedImageIndex!),
                  ),
                  _buildToolButton(
                    icon: Icons.delete,
                    tooltip: localizations.delete,
                    onPressed: () => _deleteImage(_selectedImageIndex!),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('${localizations.addPhoto}:',
                        style: TextStyle(
                            color: Colors.grey[300],
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: buttonStyle,
                      onPressed: _addImage,
                      icon: const Icon(Icons.add_photo_alternate, size: 20),
                      label: Text(localizations.add),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('${localizations.background}:',
                        style: TextStyle(
                            color: Colors.grey[300],
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: buttonStyle,
                      onPressed: _pickBackgroundImage,
                      child: Text(localizations.selectImage),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentTabIndex = 1;
                        });
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _backgroundColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ColorPicker(
                    pickerColor: _backgroundColor,
                    onColorChanged: _changeBackgroundColor,
                    pickerAreaHeightPercent: isMobile ? 0.4 : 0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('${localizations.borderColor}:',
                        style: TextStyle(
                            color: Colors.grey[300],
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return Dialog(
                              backgroundColor: Colors.grey[900],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      localizations.selectColor,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      height: isMobile ? 200 : 300,
                                      child: ColorPicker(
                                        pickerColor: _borderColor,
                                        onColorChanged: _changeBorderColor,
                                        pickerAreaHeightPercent: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      style: buttonStyle,
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(localizations.apply),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _borderColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _borderColor.withOpacity(0.5),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('${localizations.borderWidth}:',
                        style: TextStyle(
                            color: Colors.grey[300],
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: _borderColor,
                          inactiveTrackColor: Colors.grey[700],
                          thumbColor: _borderColor,
                          overlayColor: _borderColor.withOpacity(0.2),
                          valueIndicatorColor: _borderColor,
                          valueIndicatorTextStyle:
                          const TextStyle(color: Colors.white),
                        ),
                        child: Slider(
                          min: 0,
                          max: 10,
                          value: _borderWidth,
                          onChanged: (val) {
                            setState(() {
                              _borderWidth = val;
                            });
                          },
                          label: _borderWidth.round().toString(),
                        ),
                      ),
                    ),
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        _borderWidth.round().toString(),
                        style: TextStyle(color: Colors.grey[300]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('${localizations.borderRadius}:',
                        style: TextStyle(
                            color: Colors.grey[300],
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: _borderColor,
                          inactiveTrackColor: Colors.grey[700],
                          thumbColor: _borderColor,
                          overlayColor: _borderColor.withOpacity(0.2),
                          valueIndicatorColor: _borderColor,
                          valueIndicatorTextStyle:
                          const TextStyle(color: Colors.white),
                        ),
                        child: Slider(
                          min: 0,
                          max: 50,
                          value: _borderRadius,
                          onChanged: (val) {
                            setState(() {
                              _borderRadius = val;
                            });
                          },
                          label: _borderRadius.round().toString(),
                        ),
                      ),
                    ),
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        _borderRadius.round().toString(),
                        style: TextStyle(color: Colors.grey[300]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
      child: Material(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}