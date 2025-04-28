import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart';
import 'dart:ui';

class PhotoFilter {
final String name;
final Image Function(Image) applyFilter;
Uint8List? thumbnail;

PhotoFilter({required this.name, required this.applyFilter});
}