import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'filters/exampleFilters.dart';

class Filter {
  final String name;
  final List<double> matrix;
  Uint8List? thumbnail;

  Filter({required this.name, required this.matrix});
}

class FiltersPanel extends StatefulWidget {
  final Uint8List originalImage;
  final Function(Uint8List) onFilterApplied;

  const FiltersPanel({
    required this.originalImage,
    required this.onFilterApplied,
    Key? key,
  }) : super(key: key);

  @override
  _FiltersPanelState createState() => _FiltersPanelState();
}

class _FiltersPanelState extends State<FiltersPanel> {
  late List<Filter> _filters;
  late img.Image _decodedImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _decodedImage = img.decodeImage(widget.originalImage)!;

    _filters = [
      // Filter(name: "Anxiety", matrix: anxiety),
      // Filter(name: "Quiet Night", matrix: quietNight),
      // Filter(name: "Bunnies", matrix: bunnies),
      // Filter(name: "Summer", matrix: summerFreshness),
    ];

    // Генерация превью для всех фильтров
    await _generateThumbnails();
    setState(() => _isLoading = false);
  }

  Future<void> _generateThumbnails() async {
    for (var filter in _filters) {
      try {
        // final thumbnail = await _applyFilterToImage(
        //     _decodedImage,
        //     filter.matrix,
        //     resizeWidth: 100
        // );
        // filter.thumbnail = thumbnail;
      } catch (e) {
        debugPrint('Error generating thumbnail for ${filter.name}: $e');
      }
    }
  }

  // Future<Uint8List> _applyFilterToImage(
  //     img.Image image,
  //     List<double> matrix, {
  //       int? resizeWidth
  //     }) async {
  //   // Применяем матрицу фильтра
  //   // final filtered = img.Matrix(image, matrix);
  //
  //   // Изменяем размер если нужно
  //   // final resized = resizeWidth != null
  //   //     ? img.copyResize(filtered, width: resizeWidth)
  //   //     : filtered;
  //
  //   //return img.encodePng(resized);
  // }

  Future<void> _applyFilter(Filter filter) async {
    try {
      //final processed = await _applyFilterToImage(_decodedImage, filter.matrix);
     // widget.onFilterApplied(processed);
    } catch (e) {
      debugPrint('Error applying filter ${filter.name}: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to apply ${filter.name} filter')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Filters',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                return _FilterItem(
                  filter: filter,
                  onTap: () => _applyFilter(filter),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterItem extends StatelessWidget {
  final Filter filter;
  final VoidCallback onTap;

  const _FilterItem({
    required this.filter,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                image: filter.thumbnail != null
                    ? DecorationImage(
                  image: MemoryImage(filter.thumbnail!),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: filter.thumbnail == null
                  ? Center(
                child: Icon(
                  Icons.error_outline,
                  color: Colors.white.withOpacity(0.5),
                ),
              )
                  : null,
            ),
          ),
          SizedBox(height: 8),
          Text(
            filter.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}