import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

Future<Uint8List?> blurBackgroundWithRemoveBg({
  required Uint8List imageBytes,
  required String apiKey,
  required double blurIntensity, // Add blurIntensity parameter
}) async {
  try {
    // Map blurIntensity (0.0 to 1.0) to remove.bg's blur levels
    final blurLevel = blurIntensity >= 0.5 ? 'strong' : 'light';

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.remove.bg/v1.0/removebg'),
    )
      ..headers['X-Api-Key'] = apiKey
      ..files.add(http.MultipartFile.fromBytes(
        'image_file',
        imageBytes,
        filename: 'image.png',
      ))
      ..fields['bg_blur'] = blurLevel
      ..fields['format'] = 'png';

    final response = await request.send();
    if (response.statusCode == 200) {
      final bytes = await response.stream.toBytes();
      debugPrint('Blur background successful, blur level: $blurLevel, bytes: ${bytes.length}');
      return bytes;
    } else {
      final error = await response.stream.bytesToString();
      debugPrint('Remove.bg API error: $error');
      throw Exception('Remove.bg API error: $error');
    }
  } catch (e) {
    debugPrint('Blur background failed: $e');
    throw Exception('Blur background failed: $e');
  }
}