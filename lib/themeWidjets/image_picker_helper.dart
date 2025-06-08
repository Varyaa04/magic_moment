import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:image_picker/image_picker.dart' as mobile_picker;
import 'package:flutter_image_compress/flutter_image_compress.dart';
//import 'package:image_picker_web/image_picker_web.dart' as web_picker
//if (dart.library.html) 'package:image_picker_web/image_picker_web.dart';

class ImagePickerHelper {
  static Future<Uint8List?> _compressImage(Uint8List bytes,
      {int maxSize = 800, int quality = 70}) async {
    try {
      if (bytes.length < 500 * 1024) {
        debugPrint('Image size ${bytes.length} bytes, skipping compression');
        return bytes;
      }

      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: maxSize,
        minHeight: maxSize,
        quality: quality,
        format: CompressFormat.png,
      );
      debugPrint(
          'Compressed image from ${bytes.length} to ${compressed.length} bytes');
      return compressed;
    } catch (e) {
      debugPrint('Compression error: $e');
      return bytes;
    }
  }

  static Future<List<Uint8List>?> pickMultiImages(
      {required int maxImages}) async {
    try {
      List<Uint8List> images = [];


        final picker = mobile_picker.ImagePicker();
        final pickedFiles = await picker.pickMultiImage();
        if (pickedFiles.isEmpty) {
          debugPrint('No images selected on mobile');
          return null;
        }

        for (var file in pickedFiles.take(maxImages)) {
          final bytes = await file.readAsBytes();
          if (bytes.length > 5 * 1024 * 1024) {
            debugPrint('Image too large: ${bytes.length} bytes');
            continue;
          }
          final compressed = await _compressImage(bytes);
          if (compressed != null) {
            images.add(compressed);
          }
      }

      return images.isEmpty ? null : images;
    } catch (e) {
      debugPrint('Error picking multi images: $e');
      return null;
    }
  }

  static Future<Uint8List?> pickImage(
      {mobile_picker.ImageSource? source}) async {
    try {
      Uint8List? bytes;

        final picker = mobile_picker.ImagePicker();
        final pickedFile = await picker.pickImage(
            source: source ?? mobile_picker.ImageSource.gallery);
        if (pickedFile != null) {
          bytes = await pickedFile.readAsBytes();

      }

      if (bytes == null || bytes.isEmpty) {
        debugPrint('No image selected');
        return null;
      }

      if (bytes.length > 5 * 1024 * 1024) {
        debugPrint('Image too large: ${bytes.length} bytes');
        return null;
      }

      final compressed = await _compressImage(bytes);
      return compressed;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }
}
