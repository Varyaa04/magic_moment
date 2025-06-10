import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';

abstract class BaseBackgroundEditor extends StatefulWidget {
  final Uint8List image;
  final int imageId;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;
  final Function(Uint8List, {String action, String operationType, Map<String, dynamic> parameters}) onUpdateImage;
  final String apiEndpoint;
  final String operationName;
  final String defaultTitle;

  const BaseBackgroundEditor({
    required this.image,
    required this.imageId,
    required this.onCancel,
    required this.onApply,
    required this.onUpdateImage,
    required this.apiEndpoint,
    required this.operationName,
    required this.defaultTitle,
    super.key,
  });
}

abstract class BaseBackgroundEditorState<T extends BaseBackgroundEditor> extends State<T> {
  List<Map<String, dynamic>> historyStack = [];
  int historyIndex = -1;

  String _getActionName(AppLocalizations? localizations);
  String _getLoadingText(AppLocalizations? localizations);
  String _getActionTooltip(AppLocalizations? localizations);

  void undo() {
    if (historyIndex > 0) {
      setState(() {
        historyIndex--;
      });
    }
  }

  Future<Uint8List> _resizeImage(Uint8List imageBytes, {int maxWidth = 1024}) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image for resizing');
    }
    if (image.width <= maxWidth) return imageBytes;
    final resized = img.copyResize(
      image,
      width: maxWidth,
      maintainAspect: true,
      interpolation: img.Interpolation.cubic,
    );
    final resizedBytes = img.encodePng(resized, level: 1);
    return Uint8List.fromList(resizedBytes);
  }

}