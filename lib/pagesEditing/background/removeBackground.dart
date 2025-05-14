import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

Future<Uint8List?> removeBackgroundFromBytes({
  required Uint8List imageBytes,
  required String apiKey,
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


    final response = await request.send();
    if (response.statusCode == 200) {
      final bytes = await response.stream.toBytes();
      debugPrint('Background removed successfully');
      return bytes;
    } else {
      final error = await response.stream.bytesToString();
      debugPrint('Error removing background: $error');
      throw Exception('Failed to remove background: $error');
    }
  } catch (e) {
    debugPrint('Exception in removeBackgroundFromBytes: $e');
    throw Exception('Error removing background: $e');
  }
}