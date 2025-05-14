import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

Future<Uint8List?> changeBackgroundWithRemoveBg({
  required Uint8List imageBytes,
  required String apiKey,
  String? colorHex, // Example: "#ffffff"
  Uint8List? backgroundImageBytes, // New background image
}) async {
  try {
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
      ..fields['format'] = 'png';

    // Set background based on input
    if (colorHex != null && backgroundImageBytes == null) {
      request.fields['bg_color'] = colorHex.replaceFirst('#', '');
    } else if (backgroundImageBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'bg_image_file',
        backgroundImageBytes,
        filename: 'background.png',
      ));
    } else {
      throw Exception('Either colorHex or backgroundImageBytes must be provided');
    }

    final response = await request.send();
    if (response.statusCode == 200) {
      final bytes = await response.stream.toBytes();
      debugPrint('Background changed successfully, bytes: ${bytes.length}');
      return bytes;
    } else {
      final error = await response.stream.bytesToString();
      debugPrint('Remove.bg API error: $error');
      throw Exception('Remove.bg API error: $error');
    }
  } catch (e) {
    debugPrint('Change background failed: $e');
    throw Exception('Change background failed: $e');
  }
}