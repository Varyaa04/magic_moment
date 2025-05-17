import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:MagicMoment/database/editHistory.dart';
import 'package:MagicMoment/database/magicMomentDatabase.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';

class ChangeBackgroundPage extends StatefulWidget {
  final Uint8List image;
  final int imageId;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;
  final Function(Uint8List, {String? action, String? operationType, Map<String, dynamic>? parameters}) onUpdateImage;

  const ChangeBackgroundPage({
    required this.image,
    required this.imageId,
    required this.onCancel,
    required this.onApply,
    required this.onUpdateImage,
    super.key,
  });

  @override
  State<ChangeBackgroundPage> createState() => _ChangeBackgroundPageState();
}

class _ChangeBackgroundPageState extends State<ChangeBackgroundPage> {
  Uint8List? _processedImage;
  bool _isLoading = false;
  String _apiKey = 'd985d2bff07351e6ca40eda24ca325607dd6d1a812b79215d26bd74eaf387c144a30436ab3ebe9696c486aa4db1c3609';

  Future<void> _pickImageAndProcess() async {
    if (_isLoading) return;
    final localizations = AppLocalizations.of(context);
    setState(() => _isLoading = true);

    try {
      if (_apiKey.isEmpty) {
        throw Exception(localizations?.error ?? 'API key is missing');
      }
      final result = await _callClipDrop(widget.image);
      if (mounted) {
        String? snapshotPath;
        List<int>? snapshotBytes;
        if (!kIsWeb) {
          final tempDir = await Directory.systemTemp.createTemp();
          snapshotPath = '${tempDir.path}/change_bg_${DateTime.now().millisecondsSinceEpoch}.png';
          final file = File(snapshotPath);
          await file.writeAsBytes(result);
        } else {
          snapshotBytes = result;
        }

        final history = EditHistory(
          imageId: widget.imageId,
          operationType: 'background',
          operationParameters: {'operation': 'change_bg'},
          operationDate: DateTime.now(),
          snapshotPath: snapshotPath,
          snapshotBytes: snapshotBytes,
        );
        final db = MagicMomentDatabase.instance;
        final historyId = await db.insertHistory(history);

        setState(() => _processedImage = result);

        await widget.onUpdateImage(
          result,
          action: localizations?.changeBackground ?? 'Change Background',
          operationType: 'background',
          parameters: {'operation': 'change_bg', 'historyId': historyId},
        );

        widget.onApply(result);
      }
    } catch (e) {
      _showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Uint8List> _callClipDrop(Uint8List imageBytes) async {
    final localizations = AppLocalizations.of(context);
    try {
      final uri = Uri.parse('https://clipdrop-api.co/replace-background/v1');
      final response = await http.post(
        uri,
        headers: {
          'x-api-key': _apiKey,
          'Content-Type': 'application/octet-stream',
        },
        body: imageBytes,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('${localizations?.processingError ?? 'Processing error'}: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ClipDrop error: $e');
      rethrow;
    }
  }

  void _showError(BuildContext context, String message) {
    final localizations = AppLocalizations.of(context);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localizations?.error ?? 'Error'}: $message'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.changeBackgroundTitle ?? 'Change Background'),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: widget.onCancel,
          tooltip: localizations?.cancel ?? 'Cancel',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: _isLoading || _processedImage == null ? null : () => widget.onApply(_processedImage!),
            tooltip: localizations?.apply ?? 'Apply',
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              localizations?.changingBackground ?? 'Changing background...',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        )
            : _processedImage != null
            ? Image.memory(_processedImage!, fit: BoxFit.contain)
            : Image.memory(widget.image, fit: BoxFit.contain),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImageAndProcess,
        tooltip: localizations?.changeImageTooltip ?? 'Pick Image',
        child: const Icon(Icons.image),
      ),
    );
  }
}
