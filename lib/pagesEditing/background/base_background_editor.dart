import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';

abstract class BaseBackgroundEditor extends StatefulWidget {
  final Uint8List image;
  final int imageId;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;
  final Function(Uint8List, {String? action, String? operationType, Map<String, dynamic>? parameters}) onUpdateImage;
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

  void undo() {
    if (historyIndex > 0 && mounted) {
      setState(() {
        historyIndex--;
        final previousState = historyStack[historyIndex];
        if (previousState['image'] != null) {
          widget.onApply(previousState['image'] as Uint8List);
        }
      });
    }
  }

  void _showError(BuildContext context, String message) {
    final localizations = AppLocalizations.of(context);
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            localizations?.error ?? 'Error',
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                localizations?.ok ?? 'OK',
                style: const TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      );
    }
  }

  String _getActionName(AppLocalizations? localizations);
  String _getLoadingText(AppLocalizations? localizations);
  String _getActionTooltip(AppLocalizations? localizations);
}