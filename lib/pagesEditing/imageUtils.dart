import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// Утилита для сохранения изображения из RenderRepaintBoundary
Future<Uint8List> saveImage(GlobalKey renderKey, {double pixelRatio = 3.0}) async {
  try {
    final boundary = renderKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception('RenderRepaintBoundary not found');
    }

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Failed to convert image to PNG bytes');
    }

    final pngBytes = byteData.buffer.asUint8List();
    return pngBytes;
  } catch (e) {
    throw Exception('Error saving image: $e');
  }
}