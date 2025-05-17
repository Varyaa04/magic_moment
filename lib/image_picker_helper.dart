import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  // Одиночное изображение
  static Future<Uint8List?> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;
    return await image.readAsBytes();
  }

  // Несколько изображений
  static Future<List<Uint8List>?> pickMultiImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isEmpty) return null;
    return Future.wait(images.map((image) => image.readAsBytes()));
  }
}
