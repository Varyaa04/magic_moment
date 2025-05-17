// image_picker_helper_web.dart
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:image_picker_web/image_picker_web.dart';

Future<Uint8List?> pickImageFromGallery() async {
  try {
    final bytes = await ImagePickerWeb.getImageAsBytes();
    debugPrint('Web image picker bytes length: ${bytes?.length ?? 0}');
    return bytes;
  } catch (e) {
    debugPrint('Web image picker error: $e');
    return null;
  }
}